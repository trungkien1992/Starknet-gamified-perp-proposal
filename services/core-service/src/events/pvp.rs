use serde::{Deserialize, Serialize};
use anyhow::Result;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PvpEvent {
    pub match_id: String,
    pub player1_id: String,
    pub player2_id: String,
    pub event_type: PvpEventType,
    pub timestamp: u64,
    pub metadata: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum PvpEventType {
    MatchStarted,
    RoundCompleted,
    MatchEnded,
    PlayerJoined,
    PlayerLeft,
}

impl PvpEvent {
    pub fn new(match_id: String, player1_id: String, player2_id: String, event_type: PvpEventType) -> Self {
        Self {
            match_id,
            player1_id,
            player2_id,
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
} 