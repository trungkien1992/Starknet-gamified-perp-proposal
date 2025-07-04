// This file will handle Starknet-related interactions.
use anyhow::{Context, Result};
use starknet_accounts::{Account, ExecutionEncoding, SingleOwnerAccount};
use starknet_core::types::{Call, Felt};
use starknet_providers::jsonrpc::{HttpTransport, JsonRpcClient};
use starknet_signers::{LocalWallet, SigningKey};
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::Mutex;
use tracing::info;
use url::Url;

use crate::config::Config;
use crate::health::HealthChecker;

#[derive(Clone)]
pub struct StarknetClient {
    account: SingleOwnerAccount<JsonRpcClient<HttpTransport>, LocalWallet>,
    config: Arc<Config>,
}

impl StarknetClient {
    pub async fn new(config: Arc<Config>) -> Result<Self> {
        let rpc_url = Url::parse(&config.starknet_rpc_url)?;
        let transport = HttpTransport::new(rpc_url);
        let provider = JsonRpcClient::new(transport);

        let signing_key = SigningKey::from_secret_scalar(Felt::from_hex(&config.private_key)?);
        let wallet = LocalWallet::from(signing_key);

        let account = SingleOwnerAccount::new(
            provider,
            wallet,
            Felt::from_hex(&config.account_address)?,
            Felt::from_hex(&config.starknet_chain_id)?,
            ExecutionEncoding::New,
        );

        Ok(Self {
            account,
            config,
        })
    }

    pub async fn execute_mint(
        &self,
        user_id: &str,
        health_checker: Arc<Mutex<HealthChecker>>,
    ) -> Result<String> {
        let start_time = std::time::Instant::now();

        let mint_call = Call {
            to: Felt::from_hex(&self.config.scdrip_contract_address)?,
            selector: Felt::from_hex(&self.config.mint_function_selector)?,
            calldata: vec![Felt::from_dec_str(&format!("{}", user_id.len()))?],
        };

        info!("Executing mint transaction for user: {}", user_id);

        let result = tokio::time::timeout(
            Duration::from_secs(self.config.transaction_timeout_seconds),
            self.account.execute_v3(vec![mint_call]).send(),
        )
        .await
        .context("Transaction timeout")?
        .context("Transaction execution failed")?;

        let tx_hash = format!("0x{:x}", result.transaction_hash);
        let duration = start_time.elapsed();

        info!(
            "Transaction successful! Hash: {}, Duration: {:?}",
            tx_hash, duration
        );

        // Record success in health checker
        {
            let mut health = health_checker.lock().await;
            health.record_transaction_success(tx_hash.clone());
        }

        Ok(tx_hash)
    }
} 