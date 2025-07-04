use std::env;
use anyhow::{Result, Context};
use tracing::info;

#[derive(Debug, Clone)]
pub struct Config {
    // gRPC settings
    pub grpc_port: u16,
    
    // Kafka settings
    pub kafka_brokers: String,
    pub kafka_topic: String,
    
    // Starknet settings
    pub starknet_rpc_url: String,
    pub starknet_chain_id: String,
    pub account_address: String,
    pub private_key: String,
    pub scdrip_contract_address: String,
    pub mint_function_selector: String,
    
    // Security settings
    pub max_fee_per_gas: u64,
    pub transaction_timeout_seconds: u64,
}

impl Config {
    pub fn from_env() -> Result<Self> {
        let config = Self {
            // gRPC settings
            grpc_port: env::var("GRPC_PORT")
                .unwrap_or_else(|_| "50051".to_string())
                .parse()
                .context("Invalid GRPC_PORT")?,
            
            // Kafka settings
            kafka_brokers: env::var("KAFKA_BROKERS")
                .unwrap_or_else(|_| "localhost:9092".to_string()),
            kafka_topic: env::var("KAFKA_TOPIC")
                .unwrap_or_else(|_| "trade-events".to_string()),
            
            // Starknet settings
            starknet_rpc_url: env::var("STARKNET_RPC_URL")
                .unwrap_or_else(|_| "http://localhost:5050".to_string()),
            starknet_chain_id: env::var("STARKNET_CHAIN_ID")
                .unwrap_or_else(|_| "0x4b4154414e41".to_string()), // Katana devnet
            account_address: env::var("STARKNET_ACCOUNT_ADDRESS")
                .context("STARKNET_ACCOUNT_ADDRESS is required")?,
            private_key: env::var("STARKNET_PRIVATE_KEY")
                .context("STARKNET_PRIVATE_KEY is required")?,
            scdrip_contract_address: env::var("SCDRIP_CONTRACT_ADDRESS")
                .context("SCDRIP_CONTRACT_ADDRESS is required")?,
            mint_function_selector: env::var("MINT_FUNCTION_SELECTOR")
                .unwrap_or_else(|_| "0x12345678".to_string()),
            
            // Security settings
            max_fee_per_gas: env::var("MAX_FEE_PER_GAS")
                .unwrap_or_else(|_| "1000000000000000".to_string()) // 0.001 ETH
                .parse()
                .context("Invalid MAX_FEE_PER_GAS")?,
            transaction_timeout_seconds: env::var("TRANSACTION_TIMEOUT_SECONDS")
                .unwrap_or_else(|_| "300".to_string()) // 5 minutes
                .parse()
                .context("Invalid TRANSACTION_TIMEOUT_SECONDS")?,
        };
        
        info!("Configuration loaded successfully");
        info!("gRPC Port: {}", config.grpc_port);
        info!("Kafka Brokers: {}", config.kafka_brokers);
        info!("Starknet RPC: {}", config.starknet_rpc_url);
        info!("SCDrip Contract: {}", config.scdrip_contract_address);
        
        Ok(config)
    }
    
    pub fn validate(&self) -> Result<()> {
        // Validate required fields
        if self.account_address.is_empty() {
            anyhow::bail!("STARKNET_ACCOUNT_ADDRESS cannot be empty");
        }
        if self.private_key.is_empty() {
            anyhow::bail!("STARKNET_PRIVATE_KEY cannot be empty");
        }
        if self.scdrip_contract_address.is_empty() {
            anyhow::bail!("SCDRIP_CONTRACT_ADDRESS cannot be empty");
        }
        
        // Validate Starknet addresses format
        if !self.account_address.starts_with("0x") {
            anyhow::bail!("STARKNET_ACCOUNT_ADDRESS must start with 0x");
        }
        if !self.scdrip_contract_address.starts_with("0x") {
            anyhow::bail!("SCDRIP_CONTRACT_ADDRESS must start with 0x");
        }
        
        Ok(())
    }
} 