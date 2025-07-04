use crate::infra::GameEventDispatcher;
use crate::events::game_event::GameEvent;
use anyhow::Result;
use async_trait::async_trait;
use std::sync::Arc;
use redis::{AsyncCommands, Client as RedisClient};
use tracing::{info, warn, error};

#[derive(Clone)]
pub struct CompositeDispatcher {
    dispatchers: Vec<Arc<dyn GameEventDispatcher>>,
}

impl CompositeDispatcher {
    pub fn new(dispatchers: Vec<Arc<dyn GameEventDispatcher>>) -> Self {
        Self { dispatchers }
    }
}

#[async_trait]
impl GameEventDispatcher for CompositeDispatcher {
    async fn dispatch(&self, event: &GameEvent) -> Result<()> {
        for dispatcher in &self.dispatchers {
            dispatcher.dispatch(event).await?;
        }
        Ok(())
    }
}

#[derive(Clone)]
pub struct WebSocketEventDispatcher {
    redis_client: RedisClient,
    channel_name: String,
}

impl WebSocketEventDispatcher {
    pub fn new(redis_url: Option<String>) -> Result<Self> {
        let redis_url = redis_url.unwrap_or_else(|| "redis://localhost:6379".to_string());
        let redis_client = RedisClient::open(redis_url)?;
        
        Ok(Self {
            redis_client,
            channel_name: "game-events".to_string(),
        })
    }
    
    pub fn with_channel(mut self, channel: String) -> Self {
        self.channel_name = channel;
        self
    }
}

#[async_trait]
impl GameEventDispatcher for WebSocketEventDispatcher {
    async fn dispatch(&self, event: &GameEvent) -> Result<()> {
        info!("Dispatching WebSocket event: {:?} for player {}", event.event_type, event.player_id);
        
        // Get Redis connection
        let mut conn = match self.redis_client.get_async_connection().await {
            Ok(conn) => conn,
            Err(e) => {
                error!("Failed to connect to Redis: {}", e);
                return Err(anyhow::anyhow!("Redis connection failed: {}", e));
            }
        };
        
        // Serialize the event to JSON
        let event_json = match serde_json::to_string(event) {
            Ok(json) => json,
            Err(e) => {
                error!("Failed to serialize game event: {}", e);
                return Err(anyhow::anyhow!("Event serialization failed: {}", e));
            }
        };
        
        // Publish to Redis channel
        match conn.publish::<&str, &str, i32>(&self.channel_name, &event_json).await {
            Ok(subscriber_count) => {
                info!("Published event to {} subscribers on channel '{}'", 
                      subscriber_count, self.channel_name);
                Ok(())
            }
            Err(e) => {
                warn!("Failed to publish to Redis channel '{}': {}", self.channel_name, e);
                Err(anyhow::anyhow!("Redis publish failed: {}", e))
            }
        }
    }
} 