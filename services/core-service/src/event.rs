// This file will handle Kafka event publishing.
use anyhow::{Context, Result};
use rdkafka::producer::{FutureProducer, FutureRecord};
use rdkafka::ClientConfig;
use std::sync::Arc;
use std::time::Duration;
use tracing::info;

use crate::config::Config;
use crate::core::MovePlayerRequest;

pub struct EventPublisher {
    producer: FutureProducer,
    config: Arc<Config>,
}

impl EventPublisher {
    pub fn new(config: Arc<Config>) -> Result<Self> {
        let producer: FutureProducer = ClientConfig::new()
            .set("bootstrap.servers", &config.kafka_brokers)
            .set("message.timeout.ms", "5000")
            .create()
            .context("Failed to create Kafka producer")?;
        Ok(Self { producer, config })
    }

    pub async fn publish_trade_closed_event(&self, user_id: &str, tx_hash: &str) -> Result<()> {
        let trade_id = format!("trade_{}", chrono::Utc::now().timestamp());
        let pnl = 150.50; // Mock profitable trade
        let leverage = 2.0; // NEW: mock leverage
        let trade_closed_event = serde_json::json!({
            "user_id": user_id,
            "trade_id": trade_id,
            "pnl": pnl,
            "leverage": leverage,
            "timestamp": chrono::Utc::now().to_rfc3339(),
            "transaction_hash": tx_hash,
        });
        match self
            .producer
            .send(
                FutureRecord::to("trade.closed")
                    .payload(&serde_json::to_string(&trade_closed_event)?)
                    .key(user_id),
                Duration::from_secs(5),
            )
            .await
        {
            Ok(_) => {
                info!(
                    "Trade.closed event published to Kafka for user: {} (PnL: {}, Leverage: {})",
                    user_id, pnl, leverage
                );
                Ok(())
            }
            Err((e, _)) => Err(anyhow::anyhow!("Failed to publish trade.closed event: {}", e)),
        }
    }

    pub async fn publish_trade_event(
        &self,
        tx_hash: &str,
        user_id: &str,
        action: &str,
        status: &str,
    ) -> Result<()> {
        let event = serde_json::json!({
            "transaction_hash": tx_hash,
            "user_id": user_id,
            "action": action,
            "status": status,
            "timestamp": chrono::Utc::now().to_rfc3339(),
            "contract_address": self.config.scdrip_contract_address,
        });

        match self
            .producer
            .send(
                FutureRecord::to(&self.config.kafka_topic)
                    .payload(&serde_json::to_string(&event)?)
                    .key("starknet-trade"),
                Duration::from_secs(5),
            )
            .await
        {
            Ok(_) => {
                info!("Trade event published to Kafka: {}", tx_hash);
                Ok(())
            }
            Err((e, _)) => Err(anyhow::anyhow!("Failed to publish Kafka event: {}", e)),
        }
    }

    pub async fn publish_player_moved_event(&self, req: &MovePlayerRequest) -> Result<()> {
        let event_payload = serde_json::json!({
            "user_id": req.user_id.clone(),
            "target_x": req.target_x,
            "target_y": req.target_y,
            "timestamp_ms": chrono::Utc::now().timestamp_millis(),
        });

        let payload_str = event_payload.to_string();
        let record = FutureRecord::to("player-events")
            .payload(&payload_str)
            .key(&req.user_id);

        match self.producer.send(record, Duration::from_secs(0)).await {
            Ok(_) => {
                info!("PlayerMoved event sent to Kafka successfully.");
                Ok(())
            }
            Err((e, _)) => {
                anyhow::bail!("Failed to send event to Kafka: {}", e)
            }
        }
    }
} 