use serde::{Deserialize, Serialize};
use anyhow::{Result, Context};
use reqwest::{Client, header::{HeaderMap, HeaderValue, AUTHORIZATION, CONTENT_TYPE}};
use std::sync::Arc;
use tracing::{info, warn, error};
use crate::config::Config;
use starknet_core::types::Felt;
use starknet_signers::{LocalWallet, SigningKey, Signer};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TradeRequest {
    pub player_id: String,
    pub symbol: String,
    pub side: TradeSide,
    pub amount: f64,
    pub leverage: f64,
    pub timestamp: u64,
    pub signature: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TradeSide {
    #[serde(rename = "long")]
    Long,
    #[serde(rename = "short")]
    Short,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TradeResponse {
    pub trade_id: String,
    pub player_id: String,
    pub symbol: String,
    pub side: TradeSide,
    pub amount: f64,
    pub entry_price: f64,
    pub exit_price: Option<f64>,
    pub pnl: f64,
    pub status: TradeStatus,
    pub timestamp: u64,
    pub fees: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TradeStatus {
    #[serde(rename = "pending")]
    Pending,
    #[serde(rename = "open")]
    Open,
    #[serde(rename = "closed")]
    Closed,
    #[serde(rename = "failed")]
    Failed,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ErrorResponse {
    pub error: String,
    pub code: Option<u32>,
    pub details: Option<serde_json::Value>,
}

#[derive(Clone)]
pub struct ExtendedApiClient {
    client: Client,
    config: Arc<Config>,
    wallet: LocalWallet,
}

impl ExtendedApiClient {
    pub fn new(config: Arc<Config>) -> Result<Self> {
        info!("Initializing Extended API client");
        
        let client = Client::new();
        
        // Initialize Starknet wallet for signing
        let private_key = config.private_key.trim_start_matches("0x");
        let signing_key = SigningKey::from_secret_scalar(
            Felt::from_hex(private_key)
                .context("Invalid private key format")?
        );
        let wallet = LocalWallet::from(signing_key);
        
        Ok(Self {
            client,
            config,
            wallet,
        })
    }
    
    /// Execute a trade via Extended API
    pub async fn execute_trade(
        &self,
        player_id: &str,
        symbol: &str,
        side: TradeSide,
        amount: f64,
        leverage: f64,
    ) -> Result<TradeResponse> {
        info!("Executing trade: {} {} {} with {}x leverage", 
              player_id, symbol, serde_json::to_string(&side).unwrap_or_default(), leverage);
        
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)?
            .as_secs();
        
        // Create message to sign
        let message = self.create_trade_message(player_id, symbol, &side, amount, leverage, timestamp)?;
        
        // Sign the message with Starknet wallet
        let signature = self.sign_message(&message).await?;
        
        let trade_request = TradeRequest {
            player_id: player_id.to_string(),
            symbol: symbol.to_string(),
            side,
            amount,
            leverage,
            timestamp,
            signature,
        };
        
        // Make API request
        let mut headers = HeaderMap::new();
        headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
        
        if let Some(api_key) = &self.config.extended_api_key {
            headers.insert(
                AUTHORIZATION,
                HeaderValue::from_str(&format!("Bearer {}", api_key))
                    .context("Invalid API key format")?
            );
        }
        
        let url = format!("{}/v1/trade", self.config.extended_api_url);
        
        let response = self.client
            .post(&url)
            .headers(headers)
            .json(&trade_request)
            .send()
            .await
            .context("Failed to send trade request")?;
        
        if response.status().is_success() {
            let trade_response: TradeResponse = response
                .json()
                .await
                .context("Failed to parse trade response")?;
            
            info!("Trade executed successfully: ID {}", trade_response.trade_id);
            Ok(trade_response)
        } else {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_default();
            
            // Try to parse error response
            if let Ok(error_response) = serde_json::from_str::<ErrorResponse>(&error_text) {
                error!("Extended API error: {} ({})", error_response.error, status);
                anyhow::bail!("Extended API error: {} ({})", error_response.error, status);
            } else {
                error!("Extended API error: {} - {}", status, error_text);
                anyhow::bail!("Extended API error: {} - {}", status, error_text);
            }
        }
    }
    
    /// Get trade status by ID
    pub async fn get_trade(&self, trade_id: &str) -> Result<TradeResponse> {
        info!("Fetching trade status: {}", trade_id);
        
        let mut headers = HeaderMap::new();
        if let Some(api_key) = &self.config.extended_api_key {
            headers.insert(
                AUTHORIZATION,
                HeaderValue::from_str(&format!("Bearer {}", api_key))
                    .context("Invalid API key format")?
            );
        }
        
        let url = format!("{}/v1/trade/{}", self.config.extended_api_url, trade_id);
        
        let response = self.client
            .get(&url)
            .headers(headers)
            .send()
            .await
            .context("Failed to fetch trade")?;
        
        if response.status().is_success() {
            let trade_response: TradeResponse = response
                .json()
                .await
                .context("Failed to parse trade response")?;
            
            Ok(trade_response)
        } else {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_default();
            anyhow::bail!("Failed to fetch trade: {} - {}", status, error_text);
        }
    }
    
    /// Close a trade position
    pub async fn close_trade(&self, trade_id: &str, player_id: &str) -> Result<TradeResponse> {
        info!("Closing trade: {} for player {}", trade_id, player_id);
        
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)?
            .as_secs();
        
        // Create message to sign for closing trade
        let message = format!("close_trade:{trade_id}:{player_id}:{timestamp}");
        let signature = self.sign_message(&message).await?;
        
        let mut headers = HeaderMap::new();
        headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
        
        if let Some(api_key) = &self.config.extended_api_key {
            headers.insert(
                AUTHORIZATION,
                HeaderValue::from_str(&format!("Bearer {}", api_key))
                    .context("Invalid API key format")?
            );
        }
        
        let close_request = serde_json::json!({
            "trade_id": trade_id,
            "player_id": player_id,
            "timestamp": timestamp,
            "signature": signature
        });
        
        let url = format!("{}/v1/trade/{}/close", self.config.extended_api_url, trade_id);
        
        let response = self.client
            .post(&url)
            .headers(headers)
            .json(&close_request)
            .send()
            .await
            .context("Failed to close trade")?;
        
        if response.status().is_success() {
            let trade_response: TradeResponse = response
                .json()
                .await
                .context("Failed to parse close trade response")?;
            
            info!("Trade closed successfully: ID {}", trade_response.trade_id);
            Ok(trade_response)
        } else {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_default();
            anyhow::bail!("Failed to close trade: {} - {}", status, error_text);
        }
    }
    
    /// Check API health
    pub async fn health_check(&self) -> Result<bool> {
        let url = format!("{}/health", self.config.extended_api_url);
        
        match self.client.get(&url).send().await {
            Ok(response) => Ok(response.status().is_success()),
            Err(e) => {
                warn!("Extended API health check failed: {}", e);
                Ok(false)
            }
        }
    }
    
    /// Create a message string for signing
    fn create_trade_message(
        &self,
        player_id: &str,
        symbol: &str,
        side: &TradeSide,
        amount: f64,
        leverage: f64,
        timestamp: u64,
    ) -> Result<String> {
        let side_str = match side {
            TradeSide::Long => "long",
            TradeSide::Short => "short",
        };
        
        Ok(format!(
            "trade:{player_id}:{symbol}:{side_str}:{amount}:{leverage}:{timestamp}"
        ))
    }
    
    /// Sign a message using Starknet private key
    async fn sign_message(&self, message: &str) -> Result<String> {
        // Hash the message (simplified - in production use proper Starknet message hashing)
        let message_hash = keccak256(message.as_bytes());
        let message_felt = Felt::from_bytes_be_slice(&message_hash);
        
        // Sign with the wallet
        let signature = self.wallet.sign_hash(&message_felt).await
            .context("Failed to sign message")?;
        
        // Convert signature to hex string
        Ok(format!("0x{:064x}{:064x}", signature.r, signature.s))
    }
}

/// Simple Keccak256 implementation for message hashing
fn keccak256(input: &[u8]) -> [u8; 32] {
    use sha3::{Digest, Keccak256};
    let mut hasher = Keccak256::new();
    hasher.update(input);
    hasher.finalize().into()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Arc;
    
    fn create_test_config() -> Arc<Config> {
        Arc::new(Config {
            grpc_port: 50051,
            kafka_brokers: "localhost:9092".to_string(),
            kafka_topic: "test".to_string(),
            starknet_rpc_url: "http://localhost:5050".to_string(),
            starknet_chain_id: "0x534e5f5345504f4c4941".to_string(),
            account_address: "0x1234567890123456789012345678901234567890".to_string(),
            private_key: "0x1234567890123456789012345678901234567890123456789012345678901234".to_string(),
            scdrip_contract_address: "0x1234567890123456789012345678901234567890".to_string(),
            mint_function_selector: "0x12345678".to_string(),
            max_fee_per_gas: 1000000000000000,
            transaction_timeout_seconds: 300,
            extended_api_url: "https://api.extended.finance".to_string(),
            extended_api_key: Some("test_key".to_string()),
        })
    }
    
    #[test]
    fn test_extended_client_creation() {
        let config = create_test_config();
        let client = ExtendedApiClient::new(config);
        assert!(client.is_ok());
    }
    
    #[test]
    fn test_trade_message_creation() {
        let config = create_test_config();
        let client = ExtendedApiClient::new(config).unwrap();
        
        let message = client.create_trade_message(
            "player1",
            "ETH-USD",
            &TradeSide::Long,
            100.0,
            2.0,
            1234567890
        ).unwrap();
        
        assert_eq!(message, "trade:player1:ETH-USD:long:100:2:1234567890");
    }
}