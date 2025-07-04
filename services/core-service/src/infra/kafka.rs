use rdkafka::producer::{FutureProducer, FutureRecord};
use rdkafka::ClientConfig;
use serde::{Deserialize, Serialize};
use anyhow::Result;
use std::time::Duration;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KafkaGameEvent {
    pub event_type: String,
    pub player_id: String,
    pub data: serde_json::Value,
    pub timestamp: u64,
}

#[async_trait::async_trait]
pub trait GameEventDispatcher: Send + Sync {
    async fn dispatch(&self, event: &crate::events::game_event::GameEvent) -> Result<()>;
}

#[derive(Clone)]
pub struct KafkaEventDispatcher {
    producer: FutureProducer,
}

impl KafkaEventDispatcher {
    pub fn new(bootstrap_servers: &str) -> Result<Self> {
        let producer: FutureProducer = ClientConfig::new()
            .set("bootstrap.servers", bootstrap_servers)
            .set("message.timeout.ms", "5000")
            .create()?;
        Ok(Self { producer })
    }
}

#[async_trait::async_trait]
impl GameEventDispatcher for KafkaEventDispatcher {
    async fn dispatch(&self, event: &crate::events::game_event::GameEvent) -> Result<()> {
        let event_json = serde_json::to_string(event)?;
        let record = FutureRecord::to("game-events")
            .payload(event_json.as_bytes())
            .key(&event.player_id);
        match self.producer.send(record, Duration::from_secs(5)).await {
            Ok(_) => Ok(()),
            Err((e, _)) => Err(anyhow::anyhow!("Failed to send event: {}", e)),
        }
    }
}

impl KafkaEventDispatcher {
    pub async fn send_player_move(&self, player_id: &str, direction: &str, position: (i32, i32)) -> Result<()> {
        let kafka_event = KafkaGameEvent {
            event_type: "player_move".to_string(),
            player_id: player_id.to_string(),
            data: serde_json::json!({
                "direction": direction,
                "position": {
                    "x": position.0,
                    "y": position.1
                }
            }),
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
        };

        // Convert to standard GameEvent for dispatch
        let event = crate::events::game_event::GameEvent::new(
            crate::events::game_event::GameEventType::XpEarned, // Use appropriate type
            kafka_event.player_id
        );
        self.dispatch(&event).await
    }

    pub async fn send_tile_interaction(&self, player_id: &str, tile_id: u32, interaction_type: &str) -> Result<()> {
        let kafka_event = KafkaGameEvent {
            event_type: "tile_interaction".to_string(),
            player_id: player_id.to_string(),
            data: serde_json::json!({
                "tile_id": tile_id,
                "interaction_type": interaction_type
            }),
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
        };

        // Convert to standard GameEvent for dispatch
        let event = crate::events::game_event::GameEvent::new(
            crate::events::game_event::GameEventType::XpEarned, // Use appropriate type
            kafka_event.player_id
        );
        self.dispatch(&event).await
    }

    pub async fn send_pvp_match(&self, match_id: &str, player1_id: &str, player2_id: &str, status: &str) -> Result<()> {
        let kafka_event = KafkaGameEvent {
            event_type: "pvp_match".to_string(),
            player_id: player1_id.to_string(),
            data: serde_json::json!({
                "match_id": match_id,
                "player1_id": player1_id,
                "player2_id": player2_id,
                "status": status
            }),
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
        };

        // Convert to standard GameEvent for dispatch
        let event = crate::events::game_event::GameEvent::new(
            crate::events::game_event::GameEventType::XpEarned, // Use appropriate type
            kafka_event.player_id
        );
        self.dispatch(&event).await
    }

    pub async fn send_streak_update(&self, player_id: &str, streak_type: &str, current_streak: u32) -> Result<()> {
        let kafka_event = KafkaGameEvent {
            event_type: "streak_update".to_string(),
            player_id: player_id.to_string(),
            data: serde_json::json!({
                "streak_type": streak_type,
                "current_streak": current_streak
            }),
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
        };

        // Convert to standard GameEvent for dispatch
        let event = crate::events::game_event::GameEvent::new(
            crate::events::game_event::GameEventType::StreakMilestone, // Use appropriate type
            kafka_event.player_id
        );
        self.dispatch(&event).await
    }

    pub async fn send_reward_claim(&self, player_id: &str, reward_type: &str, amount: u32) -> Result<()> {
        let kafka_event = KafkaGameEvent {
            event_type: "reward_claim".to_string(),
            player_id: player_id.to_string(),
            data: serde_json::json!({
                "reward_type": reward_type,
                "amount": amount
            }),
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
        };

        // Convert to standard GameEvent for dispatch
        let event = crate::events::game_event::GameEvent::new(
            crate::events::game_event::GameEventType::XpEarned, // Use appropriate type
            kafka_event.player_id
        );
        self.dispatch(&event).await
    }
} 