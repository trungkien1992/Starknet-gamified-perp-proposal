use serde::{Deserialize, Serialize};
use anyhow::{Result, Context};
use std::sync::Arc;
use tracing::{info, warn, error};
use async_trait::async_trait;
use rand::Rng;

use crate::config::Config;
use crate::infra::{ExtendedApiClient, TradeSide, TradeStatus, GameEventDispatcher};
use crate::events::game_event::GameEvent;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Trade {
    pub id: String,
    pub player_id: String,
    pub symbol: String,
    pub side: TradeSide,
    pub amount: f64,
    pub leverage: f64,
    pub entry_price: f64,
    pub exit_price: Option<f64>,
    pub pnl: f64,
    pub status: TradeStatus,
    pub timestamp: u64,
    pub fees: f64,
    pub is_mock: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TradeRequest {
    pub player_id: String,
    pub symbol: String,
    pub side: TradeSide,
    pub amount: f64,
    pub leverage: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TradeResult {
    pub trade: Trade,
    pub success: bool,
    pub error_message: Option<String>,
}

#[async_trait]
pub trait TradeServiceTrait: Send + Sync {
    async fn execute_trade(&self, request: TradeRequest) -> Result<TradeResult>;
    async fn close_trade(&self, trade_id: &str, player_id: &str) -> Result<TradeResult>;
    async fn get_trade(&self, trade_id: &str) -> Result<Option<Trade>>;
}

#[derive(Clone)]
pub struct TradeService {
    extended_client: Option<ExtendedApiClient>,
    event_dispatcher: Arc<dyn GameEventDispatcher>,
    config: Arc<Config>,
}

impl TradeService {
    pub fn new(
        config: Arc<Config>,
        event_dispatcher: Arc<dyn GameEventDispatcher>,
    ) -> Result<Self> {
        info!("Initializing Trade Service");
        
        // Try to initialize Extended API client
        let extended_client = match ExtendedApiClient::new(config.clone()) {
            Ok(client) => {
                info!("Extended API client initialized successfully");
                Some(client)
            }
            Err(e) => {
                warn!("Failed to initialize Extended API client: {}. Will use mock trades.", e);
                None
            }
        };
        
        Ok(Self {
            extended_client,
            event_dispatcher,
            config,
        })
    }
    
    /// Execute a trade using Extended API or fallback to mock
    async fn execute_real_trade(&self, request: &TradeRequest) -> Result<Trade> {
        if let Some(client) = &self.extended_client {
            // Check API health first
            if client.health_check().await.unwrap_or(false) {
                info!("Extended API is healthy, executing real trade");
                
                match client.execute_trade(
                    &request.player_id,
                    &request.symbol,
                    request.side.clone(),
                    request.amount,
                    request.leverage,
                ).await {
                    Ok(trade_response) => {
                        info!("Real trade executed successfully: {}", trade_response.trade_id);
                        
                        let trade = Trade {
                            id: trade_response.trade_id,
                            player_id: trade_response.player_id,
                            symbol: trade_response.symbol,
                            side: trade_response.side,
                            amount: trade_response.amount,
                            leverage: request.leverage,
                            entry_price: trade_response.entry_price,
                            exit_price: trade_response.exit_price,
                            pnl: trade_response.pnl,
                            status: trade_response.status,
                            timestamp: trade_response.timestamp,
                            fees: trade_response.fees,
                            is_mock: false,
                        };
                        
                        return Ok(trade);
                    }
                    Err(e) => {
                        warn!("Extended API trade failed: {}. Falling back to mock.", e);
                    }
                }
            } else {
                warn!("Extended API health check failed. Falling back to mock trade.");
            }
        }
        
        // Fallback to mock trade
        self.execute_mock_trade(request)
    }
    
    /// Execute a mock trade for testing/fallback
    fn execute_mock_trade(&self, request: &TradeRequest) -> Result<Trade> {
        info!("Executing mock trade for player: {}", request.player_id);
        
        let mut rng = rand::thread_rng();
        
        // Generate realistic mock data
        let base_price = match request.symbol.as_str() {
            "ETH-USD" => 2000.0,
            "BTC-USD" => 45000.0,
            "SOL-USD" => 100.0,
            _ => 1000.0,
        };
        
        let entry_price = base_price * (0.98 + rng.gen::<f64>() * 0.04); // ±2% variation
        let price_change = (rng.gen::<f64>() - 0.5) * 0.1; // ±5% price movement
        let exit_price = entry_price * (1.0 + price_change);
        
        // Calculate PnL based on position side
        let price_diff = exit_price - entry_price;
        let position_pnl = match request.side {
            TradeSide::Long => price_diff,
            TradeSide::Short => -price_diff,
        };
        
        let pnl = (position_pnl / entry_price) * request.amount * request.leverage;
        let fees = request.amount * 0.001; // 0.1% fee
        
        let trade_id = format!("mock_{}_{}", request.player_id, 
                              std::time::SystemTime::now()
                                  .duration_since(std::time::UNIX_EPOCH)
                                  .unwrap()
                                  .as_millis());
        
        let trade = Trade {
            id: trade_id,
            player_id: request.player_id.clone(),
            symbol: request.symbol.clone(),
            side: request.side.clone(),
            amount: request.amount,
            leverage: request.leverage,
            entry_price,
            exit_price: Some(exit_price),
            pnl: pnl - fees,
            status: TradeStatus::Closed,
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
            fees,
            is_mock: true,
        };
        
        info!("Mock trade generated: PnL {:.2}, entry {:.2}, exit {:.2}", 
              trade.pnl, trade.entry_price, trade.exit_price.unwrap_or(0.0));
        
        Ok(trade)
    }
    
    /// Close a real trade using Extended API
    async fn close_real_trade(&self, trade_id: &str, player_id: &str) -> Result<Trade> {
        if let Some(client) = &self.extended_client {
            if client.health_check().await.unwrap_or(false) {
                match client.close_trade(trade_id, player_id).await {
                    Ok(trade_response) => {
                        let trade = Trade {
                            id: trade_response.trade_id,
                            player_id: trade_response.player_id,
                            symbol: trade_response.symbol,
                            side: trade_response.side,
                            amount: trade_response.amount,
                            leverage: 1.0, // Will be updated from stored data
                            entry_price: trade_response.entry_price,
                            exit_price: trade_response.exit_price,
                            pnl: trade_response.pnl,
                            status: trade_response.status,
                            timestamp: trade_response.timestamp,
                            fees: trade_response.fees,
                            is_mock: false,
                        };
                        
                        return Ok(trade);
                    }
                    Err(e) => {
                        warn!("Failed to close real trade: {}", e);
                    }
                }
            }
        }
        
        anyhow::bail!("Cannot close trade: Extended API not available")
    }
    
    /// Emit trade resolved event
    async fn emit_trade_resolved_event(&self, trade: &Trade) -> Result<()> {
        let event = GameEvent::trade_resolved(
            trade.player_id.clone(),
            trade.id.clone(),
            trade.symbol.clone(),
            trade.pnl,
            trade.amount,
            trade.is_mock,
        );
        
        self.event_dispatcher.dispatch(&event).await
            .context("Failed to dispatch trade resolved event")?;
        
        info!("Trade resolved event emitted for trade: {}", trade.id);
        Ok(())
    }
}

#[async_trait]
impl TradeServiceTrait for TradeService {
    async fn execute_trade(&self, request: TradeRequest) -> Result<TradeResult> {
        info!("Executing trade request: {} {} {} with {}x leverage", 
              request.player_id, request.symbol, 
              serde_json::to_string(&request.side).unwrap_or_default(), 
              request.leverage);
        
        match self.execute_real_trade(&request).await {
            Ok(trade) => {
                // Emit trade resolved event
                if let Err(e) = self.emit_trade_resolved_event(&trade).await {
                    warn!("Failed to emit trade resolved event: {}", e);
                }
                
                Ok(TradeResult {
                    trade,
                    success: true,
                    error_message: None,
                })
            }
            Err(e) => {
                error!("Trade execution failed: {}", e);
                Ok(TradeResult {
                    trade: Trade {
                        id: "failed".to_string(),
                        player_id: request.player_id,
                        symbol: request.symbol,
                        side: request.side,
                        amount: request.amount,
                        leverage: request.leverage,
                        entry_price: 0.0,
                        exit_price: None,
                        pnl: 0.0,
                        status: TradeStatus::Failed,
                        timestamp: std::time::SystemTime::now()
                            .duration_since(std::time::UNIX_EPOCH)
                            .unwrap()
                            .as_secs(),
                        fees: 0.0,
                        is_mock: false,
                    },
                    success: false,
                    error_message: Some(e.to_string()),
                })
            }
        }
    }
    
    async fn close_trade(&self, trade_id: &str, player_id: &str) -> Result<TradeResult> {
        info!("Closing trade: {} for player: {}", trade_id, player_id);
        
        match self.close_real_trade(trade_id, player_id).await {
            Ok(trade) => {
                // Emit trade resolved event for closure
                if let Err(e) = self.emit_trade_resolved_event(&trade).await {
                    warn!("Failed to emit trade resolved event for closure: {}", e);
                }
                
                Ok(TradeResult {
                    trade,
                    success: true,
                    error_message: None,
                })
            }
            Err(e) => {
                error!("Trade closure failed: {}", e);
                Ok(TradeResult {
                    trade: Trade {
                        id: trade_id.to_string(),
                        player_id: player_id.to_string(),
                        symbol: "UNKNOWN".to_string(),
                        side: TradeSide::Long,
                        amount: 0.0,
                        leverage: 1.0,
                        entry_price: 0.0,
                        exit_price: None,
                        pnl: 0.0,
                        status: TradeStatus::Failed,
                        timestamp: std::time::SystemTime::now()
                            .duration_since(std::time::UNIX_EPOCH)
                            .unwrap()
                            .as_secs(),
                        fees: 0.0,
                        is_mock: false,
                    },
                    success: false,
                    error_message: Some(e.to_string()),
                })
            }
        }
    }
    
    async fn get_trade(&self, trade_id: &str) -> Result<Option<Trade>> {
        info!("Fetching trade: {}", trade_id);
        
        if let Some(client) = &self.extended_client {
            match client.get_trade(trade_id).await {
                Ok(trade_response) => {
                    let trade = Trade {
                        id: trade_response.trade_id,
                        player_id: trade_response.player_id,
                        symbol: trade_response.symbol,
                        side: trade_response.side,
                        amount: trade_response.amount,
                        leverage: 1.0, // Default value, should be stored separately
                        entry_price: trade_response.entry_price,
                        exit_price: trade_response.exit_price,
                        pnl: trade_response.pnl,
                        status: trade_response.status,
                        timestamp: trade_response.timestamp,
                        fees: trade_response.fees,
                        is_mock: false,
                    };
                    
                    Ok(Some(trade))
                }
                Err(e) => {
                    warn!("Failed to fetch trade from Extended API: {}", e);
                    Ok(None)
                }
            }
        } else {
            warn!("Extended API client not available");
            Ok(None)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::game_engine::dispatcher::WebSocketEventDispatcher;
    
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
    
    #[tokio::test]
    async fn test_mock_trade_execution() {
        let config = create_test_config();
        let dispatcher = Arc::new(WebSocketEventDispatcher::new(None).unwrap());
        let trade_service = TradeService::new(config, dispatcher).unwrap();
        
        let request = TradeRequest {
            player_id: "test_player".to_string(),
            symbol: "ETH-USD".to_string(),
            side: TradeSide::Long,
            amount: 100.0,
            leverage: 2.0,
        };
        
        let result = trade_service.execute_trade(request).await.unwrap();
        assert!(result.success);
        assert!(result.trade.is_mock);
        assert_eq!(result.trade.player_id, "test_player");
        assert_eq!(result.trade.symbol, "ETH-USD");
    }
    
    #[test]
    fn test_trade_service_creation() {
        let config = create_test_config();
        let dispatcher = Arc::new(WebSocketEventDispatcher::new(None).unwrap());
        let trade_service = TradeService::new(config, dispatcher);
        assert!(trade_service.is_ok());
    }
}