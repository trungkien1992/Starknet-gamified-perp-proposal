use serde::{Deserialize, Serialize};
use anyhow::Result;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RewardEvent {
    pub player_id: String,
    pub reward_type: String,
    pub amount: u32,
    pub timestamp: u64,
    pub metadata: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum RewardType {
    Coins,
    Experience,
    Badge,
    Item,
    Multiplier,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RewardConfig {
    pub reward_type: RewardType,
    pub base_amount: u32,
    pub multiplier: f32,
    pub max_amount: u32,
}

impl RewardEvent {
    pub fn new(player_id: String, reward_type: String, amount: u32) -> Self {
        Self {
            player_id,
            reward_type,
            amount,
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

    pub fn calculate_reward(base_amount: u32, multiplier: f32, max_amount: u32) -> u32 {
        let calculated = (base_amount as f32 * multiplier) as u32;
        calculated.min(max_amount)
    }
} 