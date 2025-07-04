from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
import grpc
import asyncio

from ..core_pb2_grpc import CoreServiceStub
from ..core_pb2 import MovePlayerRequest

router = APIRouter(prefix="/player", tags=["player"])

# Pydantic models for request/response
class PlayerMoveRequest(BaseModel):
    user_id: str
    direction: str

class PlayerMoveResponse(BaseModel):
    success: bool
    message: str

class PlayerInfo(BaseModel):
    id: str
    position_x: int
    position_y: int
    health: int
    score: int
    level: int
    experience: int

class PlayerStats(BaseModel):
    total_moves: int
    tiles_owned: int
    pvp_wins: int
    pvp_losses: int
    current_streak: int
    longest_streak: int

# Dependency to get gRPC client
async def get_grpc_client() -> CoreServiceStub:
    channel = grpc.aio.insecure_channel('localhost:50051')
    return CoreServiceStub(channel)

@router.post("/move", response_model=PlayerMoveResponse)
async def move_player(
    request: PlayerMoveRequest,
    grpc_client: CoreServiceStub = Depends(get_grpc_client)
):
    """Move a player in the specified direction"""
    try:
        grpc_request = MovePlayerRequest(
            user_id=request.user_id,
            direction=request.direction
        )
        
        response = await grpc_client.move_player(grpc_request)
        
        return PlayerMoveResponse(
            success=response.success,
            message=response.message
        )
    except grpc.RpcError as e:
        raise HTTPException(status_code=500, detail=f"gRPC error: {e.details()}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/{player_id}", response_model=PlayerInfo)
async def get_player_info(
    player_id: str,
    grpc_client: CoreServiceStub = Depends(get_grpc_client)
):
    """Get player information"""
    try:
        # TODO: Implement get_player_info gRPC call
        # For now, return mock data
        return PlayerInfo(
            id=player_id,
            position_x=0,
            position_y=0,
            health=100,
            score=0,
            level=1,
            experience=0
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/{player_id}/stats", response_model=PlayerStats)
async def get_player_stats(
    player_id: str,
    grpc_client: CoreServiceStub = Depends(get_grpc_client)
):
    """Get player statistics"""
    try:
        # TODO: Implement get_player_stats gRPC call
        # For now, return mock data
        return PlayerStats(
            total_moves=0,
            tiles_owned=0,
            pvp_wins=0,
            pvp_losses=0,
            current_streak=0,
            longest_streak=0
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/{player_id}/tiles")
async def get_player_tiles(
    player_id: str,
    grpc_client: CoreServiceStub = Depends(get_grpc_client)
):
    """Get tiles owned by the player"""
    try:
        # TODO: Implement get_player_tiles gRPC call
        # For now, return mock data
        return {"tiles": []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/{player_id}/pvp-matches")
async def get_player_pvp_matches(
    player_id: str,
    grpc_client: CoreServiceStub = Depends(get_grpc_client)
):
    """Get PvP matches for the player"""
    try:
        # TODO: Implement get_player_pvp_matches gRPC call
        # For now, return mock data
        return {"matches": []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/{player_id}/streaks")
async def get_player_streaks(
    player_id: str,
    grpc_client: CoreServiceStub = Depends(get_grpc_client)
):
    """Get player streaks"""
    try:
        # TODO: Implement get_player_streaks gRPC call
        # For now, return mock data
        return {"streaks": []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}") 