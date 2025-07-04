use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum GameEventType {
    #[serde(rename = "xp.earned")]
    XpEarned,
    #[serde(rename = "streak.milestone")]
    StreakMilestone,
    #[serde(rename = "streak.reset")]
    StreakReset,
    #[serde(rename = "badge.minted")]
    BadgeMinted,
    #[serde(rename = "drip.flex")]
    DripFlex,
    #[serde(rename = "pvp.result")]
    PvpResult,
    #[serde(rename = "trade.resolved")]
    TradeResolved,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GameEvent {
    pub event_type: GameEventType,
    pub player_id: String,
    pub amount: Option<u32>,
    pub badge: Option<String>,
    pub streak: Option<u32>,
    pub timestamp: String,
    pub payload: Option<serde_json::Value>,
}

impl GameEvent {
    pub fn new(event_type: GameEventType, player_id: String) -> Self {
        Self {
            event_type,
            player_id,
            amount: None,
            badge: None,
            streak: None,
            timestamp: chrono::Utc::now().to_rfc3339(),
            payload: None,
        }
    }

    pub fn pvp_result(winner: String, loser: String) -> Self {
        let mut payload = serde_json::Map::new();
        payload.insert("winner".to_string(), serde_json::Value::String(winner.clone()));
        payload.insert("loser".to_string(), serde_json::Value::String(loser.clone()));
        Self {
            event_type: GameEventType::PvpResult,
            player_id: winner,
            amount: None,
            badge: None,
            streak: None,
            timestamp: chrono::Utc::now().to_rfc3339(),
            payload: Some(serde_json::Value::Object(payload)),
        }
    }

    pub fn streak_reset(player_id: String, lost_streak: u32, reason: String) -> Self {
        let mut payload = serde_json::Map::new();
        payload.insert("lost_streak".to_string(), serde_json::Value::Number(lost_streak.into()));
        payload.insert("reason".to_string(), serde_json::Value::String(reason));
        
        Self {
            event_type: GameEventType::StreakReset,
            player_id,
            amount: None,
            badge: None,
            streak: Some(lost_streak),
            timestamp: chrono::Utc::now().to_rfc3339(),
            payload: Some(serde_json::Value::Object(payload)),
        }
    }
    
    pub fn trade_resolved(
        player_id: String,
        trade_id: String,
        symbol: String,
        pnl: f64,
        volume: f64,
        is_mock: bool,
    ) -> Self {
        let mut payload = serde_json::Map::new();
        payload.insert("trade_id".to_string(), serde_json::Value::String(trade_id));
        payload.insert("symbol".to_string(), serde_json::Value::String(symbol));
        payload.insert("pnl".to_string(), serde_json::Value::Number(serde_json::Number::from_f64(pnl).unwrap_or_else(|| serde_json::Number::from(0))));
        payload.insert("volume".to_string(), serde_json::Value::Number(serde_json::Number::from_f64(volume).unwrap_or_else(|| serde_json::Number::from(0))));
        payload.insert("is_mock".to_string(), serde_json::Value::Bool(is_mock));
        
        Self {
            event_type: GameEventType::TradeResolved,
            player_id,
            amount: None,
            badge: None,
            streak: None,
            timestamp: chrono::Utc::now().to_rfc3339(),
            payload: Some(serde_json::Value::Object(payload)),
        }
    }
} 