use anyhow::{Context, Result};
use serde::Deserialize;
use std::env;

#[derive(Debug, Clone, Deserialize)]
pub struct Config {
    // Kafka Configuration
    pub kafka_brokers: String,
    pub kafka_topic: String,
    pub kafka_group_id: String,
    
    // Starknet Configuration
    pub starknet_rpc_url: String,
    pub starknet_chain_id: String,
    pub account_address: String,
    pub private_key: String,
    pub scdrip_contract_address: String,
    pub mint_function_selector: String,
    
    // Transaction Configuration
    pub transaction_timeout_seconds: u64,
}

impl Config {
    pub fn new() -> Result<Self> {
        let config = Config {
            // Kafka Configuration
            kafka_brokers: env::var("KAFKA_BROKERS")
                .unwrap_or_else(|_| "localhost:9092".to_string()),
            kafka_topic: env::var("KAFKA_TOPIC")
                .unwrap_or_else(|_| "trade.closed".to_string()),
            kafka_group_id: env::var("KAFKA_GROUP_ID")
                .unwrap_or_else(|_| "game-logic-service".to_string()),
            
            // Starknet Configuration
            starknet_rpc_url: env::var("STARKNET_RPC_URL")
                .unwrap_or_else(|_| "http://localhost:5050".to_string()),
            starknet_chain_id: env::var("STARKNET_CHAIN_ID")
                .unwrap_or_else(|_| "0x4b4154414e41".to_string()), // Katana devnet
            account_address: env::var("STARKNET_ACCOUNT_ADDRESS")
                .context("STARKNET_ACCOUNT_ADDRESS environment variable is required")?,
            private_key: env::var("STARKNET_PRIVATE_KEY")
                .context("STARKNET_PRIVATE_KEY environment variable is required")?,
            scdrip_contract_address: env::var("SCDRIP_CONTRACT_ADDRESS")
                .context("SCDRIP_CONTRACT_ADDRESS environment variable is required")?,
            mint_function_selector: env::var("MINT_FUNCTION_SELECTOR")
                .unwrap_or_else(|_| "0x2f0b3f571981132d9017d9e4e6d4bb62948080a49d2f1b8e3cf62f4147559e47".to_string()),
            
            // Transaction Configuration
            transaction_timeout_seconds: env::var("TRANSACTION_TIMEOUT_SECONDS")
                .unwrap_or_else(|_| "300".to_string())
                .parse()
                .context("TRANSACTION_TIMEOUT_SECONDS must be a valid number")?,
        };
        
        Ok(config)
    }
    
    pub fn validate(&self) -> Result<()> {
        // Validate required fields
        if self.account_address.is_empty() {
            return Err(anyhow::anyhow!("Account address cannot be empty"));
        }
        
        if self.private_key.is_empty() {
            return Err(anyhow::anyhow!("Private key cannot be empty"));
        }
        
        if self.scdrip_contract_address.is_empty() {
            return Err(anyhow::anyhow!("SCDrip contract address cannot be empty"));
        }
        
        // Validate hex format for Starknet addresses
        if !self.account_address.starts_with("0x") {
            return Err(anyhow::anyhow!("Account address must be a valid hex string starting with 0x"));
        }
        
        if !self.private_key.starts_with("0x") {
            return Err(anyhow::anyhow!("Private key must be a valid hex string starting with 0x"));
        }
        
        if !self.scdrip_contract_address.starts_with("0x") {
            return Err(anyhow::anyhow!("SCDrip contract address must be a valid hex string starting with 0x"));
        }
        
        // Validate timeout
        if self.transaction_timeout_seconds == 0 {
            return Err(anyhow::anyhow!("Transaction timeout must be greater than 0"));
        }
        
        Ok(())
    }
} 