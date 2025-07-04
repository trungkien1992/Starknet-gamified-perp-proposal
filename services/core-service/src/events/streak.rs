use serde::{Deserialize, Serialize};
use anyhow::Result;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreakEvent {
    pub player_id: String,
    pub streak_type: String,
    pub current_streak: u32,
    pub event_type: StreakEventType,
    pub timestamp: u64,
    pub metadata: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum StreakEventType {
    Started,
    Extended,
    Broken,
    RewardEarned,
    MultiplierUpdated,
}

impl StreakEvent {
    pub fn new(player_id: String, streak_type: String, current_streak: u32, event_type: StreakEventType) -> Self {
        Self {
            player_id,
            streak_type,
            current_streak,
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