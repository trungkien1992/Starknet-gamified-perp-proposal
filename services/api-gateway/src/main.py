import strawberry
import grpc
import uvicorn
from fastapi import FastAPI, Request, WebSocket, WebSocketDisconnect
from strawberry.fastapi import GraphQLRouter
from contextlib import asynccontextmanager
# FIX: Import BaseSettings directly from pydantic v1.
from pydantic import BaseSettings, Field
from typing import List
import asyncio
import json
import aioredis
import os

# --- Import the generated gRPC client code ---
from . import core_pb2
from . import core_pb2_grpc


# 1. Centralized Configuration Management
# ----------------------------------------
# Loads configuration from a .env file using pydantic's built-in settings management.
class Settings(BaseSettings):
    core_service_url: str = Field(default="localhost:50051", env="CORE_SERVICE_URL")

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()

APP_MODE = os.getenv("APP_MODE", "mock")
print(f"[Startup] Running in {APP_MODE} mode")
if APP_MODE == "mock":
    # Use mock logic here
    pass

# 2. Shared gRPC Client & Lifespan Management
# ---------------------------------------------
# This dictionary will hold our shared gRPC client stub.
shared_resources = {}

@asynccontextmanager
async def lifespan(app: FastAPI):
    # This code runs ONCE when the application starts up.
    print(f"Connecting to Core Service at {settings.core_service_url}...")
    channel = grpc.aio.insecure_channel(settings.core_service_url)
    stub = core_pb2_grpc.CoreServiceStub(channel)
    shared_resources["grpc_stub"] = stub
    print("Connection to Core Service established.")
    
    yield  # The application is now running
    
    # This code runs ONCE when the application shuts down.
    await channel.close()
    print("Connection to Core Service closed.")


# 3. FastAPI Application Setup
# ----------------------------
# We pass our lifespan manager to the FastAPI constructor.
app = FastAPI(title="StreetCred Clash API Gateway", lifespan=lifespan)


# 4. GraphQL Schema Definition
# ----------------------------
# The Strawberry schema remains mostly the same, but with improved type hints.
@strawberry.type
class MovePlayerResponse:
    success: bool
    message: str

@strawberry.type
class Query:
    @strawberry.field
    def hello(self) -> str:
        return "Hello from StreetCred Clash API Gateway!"

@strawberry.type
class Mutation:
    @strawberry.mutation
    async def move_player(self, x: int, y: int, info) -> MovePlayerResponse:
        """
        The resolver now gets the shared gRPC stub from the Strawberry context,
        avoiding the creation of a new channel for every request.
        """
        print(f"Gateway received move_player request for coordinates: ({x}, {y})")

        # Get the shared gRPC stub from the Strawberry context
        grpc_stub = info.context["grpc_stub"]

        try:
            # Create the gRPC request object
            grpc_request = core_pb2.MovePlayerRequest(user_id="user-123", target_x=x, target_y=y)

            # Make the async RPC call using the reused stub
            print("Forwarding request to Core Service...")
            response = await grpc_stub.MovePlayer(grpc_request)
            print(f"Received response from Core Service: {response.message}")

            return MovePlayerResponse(
                success=response.success,
                message=response.message
            )
        except grpc.aio.AioRpcError as e:
            # Handle cases where the Core Service is unavailable or returns an error.
            print(f"Error calling Core Service: {e.details()}")
            return MovePlayerResponse(
                success=False,
                message="The Core Service is currently unavailable."
            )

schema = strawberry.Schema(query=Query, mutation=Mutation)

def get_context():
    return {"grpc_stub": shared_resources.get("grpc_stub")}

graphql_app = GraphQLRouter(schema, context_getter=get_context)

app.include_router(graphql_app, prefix="/graphql")

@app.get("/healthz")
def health_check():
    return {"status": "ok"}

@app.post("/test/emit-event")
async def emit_test_event(event_type: str = "xp.earned", player_id: str = "test-player"):
    """Test endpoint to manually emit game events for WebSocket testing"""
    import uuid
    from datetime import datetime
    
    # Create a test game event
    test_event = {
        "event_type": event_type,
        "player_id": player_id,
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "payload": {}
    }
    
    # Add type-specific payload
    if event_type == "xp.earned":
        test_event["payload"] = {"amount": 25}
    elif event_type == "streak.milestone":
        test_event["payload"] = {"streak": 5, "badge": "Consistent Trader"}
    elif event_type == "streak.reset":
        test_event["payload"] = {"lost_streak": 7, "reason": "inactivity_timeout"}
    elif event_type == "drip.minted":
        test_event["payload"] = {"badge": "Diamond Spray"}
    
    # Broadcast immediately for testing (bypassing Redis)
    await manager.broadcast(json.dumps(test_event))
    
    return {
        "status": "success", 
        "message": f"Emitted {event_type} event for {player_id}",
        "event": test_event,
        "active_connections": len(manager.active_connections)
    }

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        print(f"[WebSocket] Client connected. Total connections: {len(self.active_connections)}")

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)
        print(f"[WebSocket] Client disconnected. Total connections: {len(self.active_connections)}")

    async def broadcast(self, message: str):
        if not self.active_connections:
            print("[WebSocket] No active connections to broadcast to")
            return
            
        disconnected = []
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except Exception as e:
                print(f"[WebSocket] Failed to send message to client: {e}")
                disconnected.append(connection)
        
        # Remove disconnected clients
        for conn in disconnected:
            self.disconnect(conn)

manager = ConnectionManager()

@app.websocket("/ws/game-events")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        # Send a welcome message
        welcome_msg = {
            "event_type": "connection.established",
            "player_id": "system",
            "timestamp": "2024-01-01T00:00:00Z",
            "payload": {"message": "Connected to StreetCred game events"}
        }
        await websocket.send_text(json.dumps(welcome_msg))
        
        # Keep connection alive and handle incoming messages
        while True:
            try:
                # Wait for any message from client (ping/pong, etc.)
                await asyncio.wait_for(websocket.receive_text(), timeout=30.0)
            except asyncio.TimeoutError:
                # Send ping to keep connection alive
                ping_msg = {
                    "event_type": "ping",
                    "player_id": "system", 
                    "timestamp": "2024-01-01T00:00:00Z",
                    "payload": {}
                }
                await websocket.send_text(json.dumps(ping_msg))
            except WebSocketDisconnect:
                break
    except WebSocketDisconnect:
        pass
    finally:
        manager.disconnect(websocket)

# To broadcast a GameEvent from anywhere in the app:
# await manager.broadcast(json.dumps(game_event_dict))

@app.on_event("startup")
async def start_redis_listener():
    async def redis_listener():
        retry_count = 0
        max_retries = 5
        
        while retry_count < max_retries:
            try:
                print(f"[Redis] Attempting to connect to Redis (attempt {retry_count + 1}/{max_retries})")
                redis = await aioredis.create_redis("redis://localhost:6379")
                print("[Redis] Connected to Redis successfully")
                
                res = await redis.subscribe("game-events")
                ch = res[0]
                print("[Redis] Subscribed to 'game-events' channel")
                
                while await ch.wait_message():
                    try:
                        msg = await ch.get(encoding="utf-8")
                        print(f"[Redis] Received event: {msg[:100]}...")  # Log first 100 chars
                        await manager.broadcast(msg)
                        print(f"[Redis] Broadcasted to {len(manager.active_connections)} WebSocket clients")
                    except Exception as e:
                        print(f"[Redis] Error processing message: {e}")
                        
            except Exception as e:
                retry_count += 1
                print(f"[Redis] Connection failed: {e}")
                if retry_count < max_retries:
                    wait_time = 2 ** retry_count  # Exponential backoff
                    print(f"[Redis] Retrying in {wait_time} seconds...")
                    await asyncio.sleep(wait_time)
                else:
                    print(f"[Redis] Max retries ({max_retries}) exceeded. Redis listener failed to start.")
                    break
    
    import asyncio
    asyncio.create_task(redis_listener())

if __name__ == "__main__":
    print("API Gateway service started.")