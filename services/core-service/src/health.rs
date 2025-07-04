use std::time::{Duration, Instant};
use anyhow::Result;
use tracing::{info, warn, error};
use tokio::time::timeout;
use serde::{Serialize, Deserialize};
use url::Url;

use starknet_providers::jsonrpc::{HttpTransport, JsonRpcClient};
use starknet_providers::Provider;

#[derive(Debug, Serialize, Deserialize)]
pub struct HealthStatus {
    pub status: String,
    pub timestamp: String,
    pub uptime_seconds: u64,
    pub starknet_connected: bool,
    pub kafka_connected: bool,
    pub last_transaction_hash: Option<String>,
    pub error_count: u64,
    pub success_count: u64,
}

#[derive(Debug)]
pub struct HealthChecker {
    start_time: Instant,
    starknet_client: JsonRpcClient<HttpTransport>,
    last_transaction_hash: Option<String>,
    error_count: u64,
    success_count: u64,
}

impl HealthChecker {
    pub fn new(starknet_rpc_url: String) -> Result<Self> {
        let rpc_url = Url::parse(&starknet_rpc_url)?;
        let transport = HttpTransport::new(rpc_url);
        let client = JsonRpcClient::new(transport);
        
        Ok(Self {
            start_time: Instant::now(),
            starknet_client: client,
            last_transaction_hash: None,
            error_count: 0,
            success_count: 0,
        })
    }
    
    pub async fn check_starknet_connection(&self) -> bool {
        match timeout(Duration::from_secs(5), self.starknet_client.chain_id()).await {
            Ok(Ok(_)) => {
                info!("Starknet connection healthy");
                true
            }
            Ok(Err(e)) => {
                error!("Starknet connection failed: {}", e);
                false
            }
            Err(_) => {
                error!("Starknet connection timeout");
                false
            }
        }
    }
    
    pub async fn get_health_status(&self) -> HealthStatus {
        let starknet_connected = self.check_starknet_connection().await;
        
        HealthStatus {
            status: if starknet_connected { "healthy".to_string() } else { "degraded".to_string() },
            timestamp: chrono::Utc::now().to_rfc3339(),
            uptime_seconds: self.start_time.elapsed().as_secs(),
            starknet_connected,
            kafka_connected: true, // TODO: Implement Kafka health check
            last_transaction_hash: self.last_transaction_hash.clone(),
            error_count: self.error_count,
            success_count: self.success_count,
        }
    }
    
    pub fn record_transaction_success(&mut self, tx_hash: String) {
        self.success_count += 1;
        self.last_transaction_hash = Some(tx_hash);
        info!("Transaction recorded as successful. Total: {}", self.success_count);
    }
    
    pub fn record_transaction_error(&mut self) {
        self.error_count += 1;
        warn!("Transaction recorded as failed. Total errors: {}", self.error_count);
    }
    
    pub fn get_success_rate(&self) -> f64 {
        let total = self.success_count + self.error_count;
        if total == 0 {
            0.0
        } else {
            self.success_count as f64 / total as f64
        }
    }
} 