use serde::{Deserialize, Serialize};
use anyhow::Result;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TileEvent {
    pub player_id: String,
    pub tile_id: u32,
    pub position: (i32, i32),
    pub event_type: TileEventType,
    pub timestamp: u64,
    pub metadata: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TileEventType {
    Claimed,
    Upgraded,
    Interacted,
    Transferred,
    ResourceHarvested,
}

impl TileEvent {
    pub fn new(player_id: String, position: (i32, i32), event_type: TileEventType) -> Self {
        Self {
            player_id,
            tile_id: Self::position_to_tile_id(position),
            position,
            event_type,
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
            metadata: serde_json::json!({}),
        }
    }

    pub fn with_metadata(mut self, metadata: serde_json::Value) -> Self {
        self.metadata = metadata;
        self
    }

    fn position_to_tile_id(position: (i32, i32)) -> u32 {
        ((position.0 as u32) << 16) | (position.1 as u32 & 0xFFFF)
    }
} 