use anyhow::Result;
use async_trait::async_trait;
use crate::events::game_event::{GameEvent, GameEventType};
use crate::infra::GameEventDispatcher;
use std::sync::Arc;

#[async_trait]
pub trait RewardServiceTrait: Send + Sync {
    async fn mint_drip_nft(&self, player_id: &str) -> Result<bool>;
}

#[derive(Clone)]
pub struct RewardService {
    dispatcher: Arc<dyn GameEventDispatcher>,
}

impl RewardService {
    pub fn new(dispatcher: Arc<dyn GameEventDispatcher>) -> Self {
        Self { dispatcher }
    }
}

#[async_trait]
impl RewardServiceTrait for RewardService {
    async fn mint_drip_nft(&self, player_id: &str) -> Result<bool> {
        // TODO: Implement NFT mint logic
        let mut event = GameEvent::new(GameEventType::BadgeMinted, player_id.to_string());
        event.badge = Some("Legendary Drip".to_string());
        self.dispatcher.dispatch(&event).await?;
        Ok(true)
    }
} 