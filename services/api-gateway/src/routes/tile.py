from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
import grpc

from ..core_pb2_grpc import CoreServiceStub

router = APIRouter(prefix="/tile", tags=["tile"])

# Pydantic models
class TileInfo(BaseModel):
    id: int
    position_x: int
    position_y: int
    owner_id: Optional[str]
    level: int
    tile_type: str
    last_updated: int

class TileClaimRequest(BaseModel):
    player_id: str
    position_x: int
    position_y: int

class TileUpgradeRequest(BaseModel):
    player_id: str
    tile_id: int

class TileInteractionRequest(BaseModel):
    player_id: str
    tile_id: int
    interaction_type: str

# Dependency to get gRPC client
async def get_grpc_client() -> CoreServiceStub:
    import grpc.aio
    channel = grpc.aio.insecure_channel('localhost:50051')
    return CoreServiceStub(channel)

@router.get("/{tile_id}", response_model=TileInfo)
async def get_tile_info(
    tile_id: int,
    grpc_client: CoreServiceStub = Depends(get_grpc_client)
):
    """Get tile information"""
    try:
        # TODO: Implement get_tile_info gRPC call
        # For now, return mock data
        return TileInfo(
            id=tile_id,
            position_x=0,
            position_y=0,
            owner_id=None,
            level=1,
            tile_type="empty",
            last_updated=0
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.post("/claim")
async def claim_tile(
    request: TileClaimRequest,
    grpc_client: CoreServiceStub = Depends(get_grpc_client)
):
    """Claim a tile at the specified position"""
    try:
        # TODO: Implement claim_tile gRPC call
        return {"success": True, "message": f"Tile claimed at ({request.position_x}, {request.position_y})"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.post("/upgrade")
async def upgrade_tile(
    request: TileUpgradeRequest,
    grpc_client: CoreServiceStub = Depends(get_grpc_client)
):
    """Upgrade a tile"""
    try:
        # TODO: Implement upgrade_tile gRPC call
        return {"success": True, "message": f"Tile {request.tile_id} upgraded"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.post("/interact")
async def interact_with_tile(
    request: TileInteractionRequest,
    grpc_client: CoreServiceStub = Depends(get_grpc_client)
):
    """Interact with a tile"""
    try:
        # TODO: Implement interact_with_tile gRPC call
        return {"success": True, "message": f"Interaction with tile {request.tile_id} completed"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/nearby/{player_id}")
async def get_nearby_tiles(
    player_id: str,
    radius: int = 5,
    grpc_client: CoreServiceStub = Depends(get_grpc_client)
):
    """Get tiles near the player"""
    try:
        # TODO: Implement get_nearby_tiles gRPC call
        # For now, return mock data
        return {"tiles": []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/map/region")
async def get_map_region(
    center_x: int,
    center_y: int,
    width: int = 10,
    height: int = 10,
    grpc_client: CoreServiceStub = Depends(get_grpc_client)
):
    """Get a region of the map"""
    try:
        # TODO: Implement get_map_region gRPC call
        # For now, return mock data
        tiles = []
        for x in range(center_x - width//2, center_x + width//2 + 1):
            for y in range(center_y - height//2, center_y + height//2 + 1):
                tiles.append({
                    "id": f"{x}_{y}",
                    "position_x": x,
                    "position_y": y,
                    "owner_id": None,
                    "level": 1,
                    "tile_type": "empty"
                })
        return {"tiles": tiles}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/leaderboard")
async def get_tile_leaderboard(
    grpc_client: CoreServiceStub = Depends(get_grpc_client)
):
    """Get tile ownership leaderboard"""
    try:
        # TODO: Implement get_tile_leaderboard gRPC call
        # For now, return mock data
        return {"leaderboard": []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}") 