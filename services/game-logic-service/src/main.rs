use std::time::Duration;
use tokio::time::timeout;
use anyhow::Result;
use tracing::{info, error, warn};
use rdkafka::consumer::{Consumer, StreamConsumer};
use rdkafka::ClientConfig;
use serde::{Deserialize, Serialize};
use url::Url;
use anyhow::Context;
use rdkafka::Message;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::Mutex;
use serde_json::json;
use axum::{Router, routing::get, extract::Path, response::Json};
use serde_json::json as axum_json;
use std::net::SocketAddr;

// Starknet imports (aligned with core-service)
use starknet_core::types::{Call, Felt};
use starknet_providers::jsonrpc::{HttpTransport, JsonRpcClient};
use starknet_accounts::{Account, SingleOwnerAccount};
use starknet_signers::{LocalWallet, SigningKey};
use starknet_accounts::ExecutionEncoding;

// Local modules
pub mod config;

use config::Config;

mod territory;
use territory::{GameMap, Player};

// Trade event structure
#[derive(Debug, Deserialize, Serialize)]
pub struct TradeClosed {
    pub user_id: String,
    pub trade_id: String,
    pub pnl: f64,
    pub leverage: f64,
    pub timestamp: String,
    pub transaction_hash: String,
}

// InkRewarded event structure
#[derive(Debug, Serialize, Deserialize)]
pub struct InkRewarded {
    pub user_id: String,
    pub trade_id: String,
    pub ink_reward: i64,
    pub new_balance: i64,
    pub timestamp: String,
}

// NFT minting service
pub struct GameLogicService {
    config: Config,
    kafka_consumer: StreamConsumer,
    starknet_account: SingleOwnerAccount<JsonRpcClient<HttpTransport>, LocalWallet>,
    ink_store: Arc<Mutex<HashMap<String, i64>>>,
    kafka_producer: rdkafka::producer::FutureProducer,
}

impl GameLogicService {
    async fn new(config: Config) -> Result<Self> {
        // Validate configuration
        config.validate()?;
        
        // Initialize Kafka consumer
        let kafka_consumer: StreamConsumer = ClientConfig::new()
            .set("bootstrap.servers", &config.kafka_brokers)
            .set("group.id", &config.kafka_group_id)
            .set("auto.offset.reset", "earliest")
            .set("enable.auto.commit", "false")
            .create()
            .context("Failed to create Kafka consumer")?;
        
        // Subscribe to trade.closed topic
        kafka_consumer.subscribe(&[&config.kafka_topic])?;
        
        // Initialize Kafka producer
        let kafka_producer: rdkafka::producer::FutureProducer = ClientConfig::new()
            .set("bootstrap.servers", &config.kafka_brokers)
            .set("message.timeout.ms", "5000")
            .create()
            .context("Failed to create Kafka producer")?;
        
        // Initialize Starknet provider
        let rpc_url = Url::parse(&config.starknet_rpc_url)?;
        let transport = HttpTransport::new(rpc_url);
        let provider = JsonRpcClient::new(transport);
        
        // Create signing key and wallet
        let signing_key = SigningKey::from_secret_scalar(Felt::from_hex(&config.private_key)?);
        let wallet = LocalWallet::from(signing_key);
        
        // Create Starknet account
        let starknet_account = SingleOwnerAccount::new(
            provider,
            wallet,
            Felt::from_hex(&config.account_address)?,
            Felt::from_hex(&config.starknet_chain_id)?,
            ExecutionEncoding::New,
        );
        
        info!("Game logic service initialized successfully");
        
        Ok(Self {
            config,
            kafka_consumer,
            starknet_account,
            ink_store: Arc::new(Mutex::new(HashMap::new())),
            kafka_producer,
        })
    }
    
    async fn start_consuming(&self) -> Result<()> {
        info!("Starting to consume messages from topic: {}", self.config.kafka_topic);
        
        loop {
            match timeout(
                Duration::from_secs(30), // 30 second timeout
                self.kafka_consumer.recv()
            ).await {
                Ok(Ok(message)) => {
                    if let Some(payload) = message.payload() {
                        match self.process_trade_event(payload).await {
                            Ok(_) => {
                                info!("Successfully processed trade event");
                                // Commit the offset after successful processing
                                if let Err(e) = self.kafka_consumer.commit_message(&message, rdkafka::consumer::CommitMode::Async) {
                                    warn!("Failed to commit message offset: {}", e);
                                }
                            }
                            Err(e) => {
                                error!("Failed to process trade event: {}", e);
                                // Don't commit offset on error - message will be reprocessed
                            }
                        }
                    }
                }
                Ok(Err(e)) => {
                    error!("Kafka consumer error: {}", e);
                }
                Err(_) => {
                    // Timeout - this is normal, just continue
                    continue;
                }
            }
        }
    }
    
    async fn process_trade_event(&self, payload: &[u8]) -> Result<()> {
        let trade_event: TradeClosed = serde_json::from_slice(payload)
            .context("Failed to deserialize trade event")?;
        info!("Processing trade event for user: {}, PnL: {}, Leverage: {}", trade_event.user_id, trade_event.pnl, trade_event.leverage);
        let ink_reward = if trade_event.pnl > 0.0 {
            (trade_event.pnl * trade_event.leverage * 10.0).round() as i64
        } else {
            0
        };
        let new_balance = {
            let mut store = self.ink_store.lock().await;
            let entry = store.entry(trade_event.user_id.clone()).or_insert(0);
            *entry += ink_reward;
            info!("User {} new ink balance: {} (added {})", trade_event.user_id, *entry, ink_reward);
            *entry
        };
        // --- GameMap and Player usage with persistence ---
        let game_map_path = "game_map.json";
        let mut game_map = match territory::GameMap::load_from_file(game_map_path) {
            Ok(map) => map,
            Err(_) => GameMap::new(10, 10),
        };
        let player = Player {
            wallet: trade_event.user_id.clone(),
            ink: new_balance,
            streak: 0,
        };
        // Tag a tile (for demo, always (0,0))
        if ink_reward > 0 {
            let tile_id = (0, 0); // Replace with actual logic
            game_map.tag_tile(&player, tile_id, ink_reward);
            info!("Tagged tile {:?} for user {} with {} ink", tile_id, player.wallet, ink_reward);
            // Save updated game map
            if let Err(e) = game_map.save_to_file(game_map_path) {
                error!("Failed to save GameMap: {}", e);
            }
            // Save player state (for demo, one file per player)
            let player_path = format!("player_{}.json", player.wallet);
            if let Err(e) = player.save_to_file(&player_path) {
                error!("Failed to save Player: {}", e);
            }
        }
        // --- End GameMap and Player usage with persistence ---
        // Emit InkRewarded event
        let ink_rewarded = InkRewarded {
            user_id: trade_event.user_id.clone(),
            trade_id: trade_event.trade_id.clone(),
            ink_reward,
            new_balance,
            timestamp: chrono::Utc::now().to_rfc3339(),
        };
        let payload = serde_json::to_string(&ink_rewarded)?;
        let record = rdkafka::producer::FutureRecord::to("ink.rewarded")
            .payload(&payload)
            .key(&trade_event.user_id);
        match self.kafka_producer.send(record, std::time::Duration::from_secs(5)).await {
            Ok(_) => info!("InkRewarded event emitted for user {}: {} ink (new balance: {})", trade_event.user_id, ink_reward, new_balance),
            Err((e, _)) => error!("Failed to emit InkRewarded event: {}", e),
        }
        // Check if trade was profitable
        if trade_event.pnl > 0.0 {
            info!("Profitable trade detected! Minting NFT for user: {}", trade_event.user_id);
            // Mint NFT on Starknet
            match self.mint_nft(&trade_event.user_id, &trade_event.trade_id).await {
                Ok(tx_hash) => {
                    info!("Successfully minted NFT for user: {}. Transaction hash: {}", trade_event.user_id, tx_hash);
                }
                Err(e) => {
                    error!("Failed to mint NFT for user: {}: {}", trade_event.user_id, e);
                    return Err(e);
                }
            }
        } else {
            info!("Trade was not profitable (PnL: {}), skipping NFT mint", trade_event.pnl);
        }
        Ok(())
    }
    
    async fn mint_nft(&self, user_id: &str, trade_id: &str) -> Result<String> {
        let start_time = std::time::Instant::now();
        
        // Create a unique token ID based on user_id and trade_id
        let token_id = format!("{}_{}", user_id, trade_id);
        let token_id_hash = format!("{}", token_id.len()); // Simple hash for demo
        
        // Create the mint function call
        let mint_call = Call {
            to: Felt::from_hex(&self.config.scdrip_contract_address)?,
            selector: Felt::from_hex(&self.config.mint_function_selector)?,
            calldata: vec![
                // Token ID (you might want to use a more sophisticated ID generation)
                Felt::from_dec_str(&token_id_hash)?,
                // Additional parameters as needed by your contract
            ],
        };
        
        info!("Executing NFT mint transaction for user: {} (token_id: {})", user_id, token_id);
        
        // Execute transaction with timeout
        let result = timeout(
            Duration::from_secs(self.config.transaction_timeout_seconds),
            self.starknet_account.execute_v3(vec![mint_call]).send()
        ).await
        .context("Transaction timeout")?
        .context("Transaction execution failed")?;
        
        let tx_hash = format!("0x{:x}", result.transaction_hash);
        let duration = start_time.elapsed();
        
        info!("NFT mint transaction successful! Hash: {}, Duration: {:?}", tx_hash, duration);
        
        Ok(tx_hash)
    }
    
    pub async fn get_ink_balance(&self, user_id: &str) -> i64 {
        let store = self.ink_store.lock().await;
        *store.get(user_id).unwrap_or(&0)
    }
}

async fn ink_balance_handler(Path(user): Path<String>) -> Json<serde_json::Value> {
    let player_path = format!("player_{}.json", user);
    match territory::Player::load_from_file(&player_path) {
        Ok(player) => Json(axum_json!({ "wallet": player.wallet, "ink": player.ink, "streak": player.streak })),
        Err(_) => Json(axum_json!({ "error": "Player not found" })),
    }
}

async fn tile_handler(Path((x, y)): Path<(u32, u32)>) -> Json<serde_json::Value> {
    let game_map_path = "game_map.json";
    match territory::GameMap::load_from_file(game_map_path) {
        Ok(game_map) => {
            match game_map.get_tile((x, y)) {
                Some(tile) => Json(axum_json!({
                    "id": tile.id,
                    "owner": tile.owner,
                    "ink": tile.ink,
                    "contested": tile.contested
                })),
                None => Json(axum_json!({ "error": "Tile not found" })),
            }
        },
        Err(_) => Json(axum_json!({ "error": "Game map not found" })),
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize tracing
    tracing_subscriber::fmt::init();
    info!("Starting Game Logic Service...");
    dotenv::dotenv().ok();
    let config = Config::new()?;
    let service = GameLogicService::new(config).await?;
    // Start Axum HTTP server in background
    let app = Router::new()
        .route("/ink_balance/:user", get(ink_balance_handler))
        .route("/tile/:x/:y", get(tile_handler));
    let addr = SocketAddr::from(([127, 0, 0, 1], 8080));
    let http_server = axum::Server::bind(&addr).serve(app.into_make_service());
    tokio::spawn(async move {
        if let Err(e) = http_server.await {
            error!("HTTP server error: {}", e);
        }
    });
    // Start consuming messages
    if let Err(e) = service.start_consuming().await {
        error!("Service error: {}", e);
        return Err(e.into());
    }
    Ok(())
}

// Re-export types for testing
// Note: Config is already imported at the top, so no need to re-export 