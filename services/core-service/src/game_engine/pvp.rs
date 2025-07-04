use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use anyhow::Result;
use async_trait::async_trait;
use std::str::FromStr;
use crate::events::game_event::{GameEvent, GameEventType};
use crate::infra::GameEventDispatcher;
use std::sync::Arc;
use tracing::{info, warn, error};
use rand::Rng;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PvpMatch {
    pub id: String,
    pub player1_id: String,
    pub player2_id: String,
    pub status: PvpStatus,
    pub rounds: Vec<PvpRound>,
    pub winner: Option<String>,
    pub created_at: u64,
    pub ended_at: Option<u64>,
    pub xp_reward: u32,
    pub streak_effect: bool,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum PvpStatus {
    Pending,
    Active,
    Completed,
    Cancelled,
}

impl FromStr for PvpStatus {
    type Err = ();
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "Pending" => Ok(PvpStatus::Pending),
            "Active" => Ok(PvpStatus::Active),
            "Completed" => Ok(PvpStatus::Completed),
            "Cancelled" => Ok(PvpStatus::Cancelled),
            _ => Err(())
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PvpRound {
    pub round_number: u32,
    pub player1_action: PvpAction,
    pub player2_action: PvpAction,
    pub player1_damage: u32,
    pub player2_damage: u32,
    pub winner: Option<String>,
    pub trade_outcome: Option<TradeOutcome>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TradeOutcome {
    pub player_id: String,
    pub pnl: f64,
    pub volume: f64,
    pub accuracy: f32, // 0.0-1.0
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum PvpAction {
    Attack,
    Defend,
    Special,
    Heal,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PvpStats {
    pub player_id: String,
    pub wins: u32,
    pub losses: u32,
    pub total_damage_dealt: u32,
    pub total_damage_taken: u32,
    pub average_rounds: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PvpResolution {
    pub winner: String,
    pub loser: String,
    pub xp_gained: u32,
    pub xp_lost: u32,
    pub streak_broken: bool,
    pub badge_earned: Option<String>,
}

#[async_trait]
pub trait PvpServiceTrait: Send + Sync {
    // Add async methods as needed for mocking
    async fn start_match(&self, player1_id: &str, player2_id: &str) -> Result<bool>;
    async fn resolve_pvp_outcome(&self, match_data: &mut PvpMatch, trade_outcomes: Vec<TradeOutcome>) -> Result<PvpResolution>;
}

#[derive(Clone)]
pub struct PvPService {
    event_dispatcher: Arc<dyn GameEventDispatcher>,
}

impl PvPService {
    pub fn new(event_dispatcher: Arc<dyn GameEventDispatcher>) -> Self {
        Self { event_dispatcher }
    }
    
    /// Calculate XP reward based on match performance
    pub fn calculate_xp_reward(&self, winner_performance: &TradeOutcome, loser_performance: &TradeOutcome) -> (u32, u32) {
        let base_xp = 100;
        
        // Winner gets more XP for better performance
        let winner_xp = base_xp + (winner_performance.pnl.abs() as u32) + (winner_performance.accuracy * 50.0) as u32;
        
        // Loser loses XP but not too much to avoid discouragement
        let loser_xp_loss = (base_xp / 2).min((loser_performance.pnl.abs() as u32) / 2);
        
        (winner_xp, loser_xp_loss)
    }
    
    /// Check if a badge should be earned
    fn check_badge_eligibility(&self, _resolution: &PvpResolution, winner_stats: &PvpStats) -> Option<String> {
        // Award badges based on performance milestones
        if winner_stats.wins == 1 {
            Some("First Victory".to_string())
        } else if winner_stats.wins == 10 {
            Some("PvP Veteran".to_string())
        } else if winner_stats.wins == 50 {
            Some("Arena Champion".to_string())
        } else if winner_stats.get_win_rate() >= 0.8 && winner_stats.wins >= 20 {
            Some("Dominator".to_string())
        } else {
            None
        }
    }
    
    /// Determine the overall winner based on PvP rounds and trade outcomes
    fn determine_overall_winner(
        &self,
        match_data: &PvpMatch,
        player1_outcome: &TradeOutcome,
        player2_outcome: &TradeOutcome,
    ) -> Result<(String, String, TradeOutcome, TradeOutcome)> {
        
        // Calculate weighted scores
        let player1_score = self.calculate_performance_score(match_data, &match_data.player1_id, player1_outcome);
        let player2_score = self.calculate_performance_score(match_data, &match_data.player2_id, player2_outcome);
        
        if player1_score > player2_score {
            Ok((
                match_data.player1_id.clone(),
                match_data.player2_id.clone(),
                player1_outcome.clone(),
                player2_outcome.clone(),
            ))
        } else {
            Ok((
                match_data.player2_id.clone(),
                match_data.player1_id.clone(),
                player2_outcome.clone(),
                player1_outcome.clone(),
            ))
        }
    }
    
    /// Calculate performance score combining PvP rounds and trading results
    pub fn calculate_performance_score(&self, match_data: &PvpMatch, player_id: &str, trade_outcome: &TradeOutcome) -> f64 {
        // PvP round wins (60% weight)
        let round_wins = match_data.rounds.iter()
            .filter(|round| round.winner.as_ref().map(|w| w.as_str()) == Some(player_id))
            .count() as f64;
        let pvp_score = (round_wins / match_data.rounds.len() as f64) * 0.6;
        
        // Trading performance (40% weight)
        let trade_score = {
            let normalized_pnl = (trade_outcome.pnl / 1000.0).max(-1.0).min(1.0); // Normalize to -1 to 1
            let accuracy_bonus = trade_outcome.accuracy as f64 * 0.5;
            ((normalized_pnl + 1.0) / 2.0 + accuracy_bonus).min(1.0) * 0.4
        };
        
        pvp_score + trade_score
    }
    
    /// Emit relevant game events for PvP resolution
    async fn emit_pvp_events(&self, resolution: &PvpResolution, match_data: &PvpMatch) -> Result<()> {
        // Emit PvP result event
        let pvp_event = GameEvent::pvp_result(resolution.winner.clone(), resolution.loser.clone());
        self.event_dispatcher.dispatch(&pvp_event).await.map_err(|e| {
            warn!("Failed to dispatch PvP result event: {}", e);
            e
        })?;
        
        // Emit XP gained event for winner
        let mut winner_xp_event = GameEvent::new(GameEventType::XpEarned, resolution.winner.clone());
        winner_xp_event.amount = Some(resolution.xp_gained);
        winner_xp_event.payload = Some(serde_json::json!({
            "source": "pvp_victory",
            "match_id": match_data.id,
            "opponent": resolution.loser
        }));
        self.event_dispatcher.dispatch(&winner_xp_event).await.map_err(|e| {
            warn!("Failed to dispatch winner XP event: {}", e);
            e
        })?;
        
        // Emit streak reset event for loser if applicable
        if resolution.streak_broken {
            let streak_reset_event = GameEvent::streak_reset(
                resolution.loser.clone(),
                1, // Will be updated with actual streak from database
                "PvP defeat".to_string(),
            );
            self.event_dispatcher.dispatch(&streak_reset_event).await.map_err(|e| {
                warn!("Failed to dispatch streak reset event: {}", e);
                e
            })?;
        }
        
        // Emit badge event if badge was earned
        if let Some(badge) = &resolution.badge_earned {
            let mut badge_event = GameEvent::new(GameEventType::BadgeMinted, resolution.winner.clone());
            badge_event.badge = Some(badge.clone());
            badge_event.payload = Some(serde_json::json!({
                "badge_type": badge,
                "earned_via": "pvp_victory",
                "match_id": match_data.id
            }));
            self.event_dispatcher.dispatch(&badge_event).await.map_err(|e| {
                warn!("Failed to dispatch badge event: {}", e);
                e
            })?;
        }
        
        Ok(())
    }
}

#[async_trait]
impl PvpServiceTrait for PvPService {
    async fn start_match(&self, _player1_id: &str, _player2_id: &str) -> Result<bool> {
        // TODO: Implement PvP match start logic
        Ok(true)
    }
    
    async fn resolve_pvp_outcome(&self, match_data: &mut PvpMatch, trade_outcomes: Vec<TradeOutcome>) -> Result<PvpResolution> {
        info!("Resolving PvP outcome for match: {}", match_data.id);
        
        if match_data.status != PvpStatus::Completed {
            return Err(anyhow::anyhow!("Match must be completed to resolve outcome"));
        }
        
        // Find the best trade outcome for each player
        let player1_outcome = trade_outcomes.iter()
            .find(|outcome| outcome.player_id == match_data.player1_id)
            .cloned()
            .unwrap_or_else(|| TradeOutcome {
                player_id: match_data.player1_id.clone(),
                pnl: 0.0,
                volume: 0.0,
                accuracy: 0.0,
            });
            
        let player2_outcome = trade_outcomes.iter()
            .find(|outcome| outcome.player_id == match_data.player2_id)
            .cloned()
            .unwrap_or_else(|| TradeOutcome {
                player_id: match_data.player2_id.clone(),
                pnl: 0.0,
                volume: 0.0,
                accuracy: 0.0,
            });
        
        // Determine winner based on combined trade performance and PvP rounds
        let (winner, loser, winner_outcome, loser_outcome) = self.determine_overall_winner(
            match_data, &player1_outcome, &player2_outcome
        )?;
        
        // Calculate XP rewards
        let (xp_gained, xp_lost) = self.calculate_xp_reward(&winner_outcome, &loser_outcome);
        
        // Check for streak effects
        let streak_broken = loser_outcome.pnl < -100.0; // Significant loss breaks streak
        
        let resolution = PvpResolution {
            winner: winner.clone(),
            loser: loser.clone(),
            xp_gained,
            xp_lost,
            streak_broken,
            badge_earned: None, // Will be determined after stats update
        };
        
        // Emit game events
        self.emit_pvp_events(&resolution, match_data).await?;
        
        info!("PvP outcome resolved: {} beats {} (+{} XP, -{} XP)", 
              winner, loser, xp_gained, xp_lost);
        
        Ok(resolution)
    }
}

impl PvpMatch {
    pub fn new(player1_id: String, player2_id: String) -> Self {
        Self {
            id: format!("{}_{}_{}", player1_id, player2_id, chrono::Utc::now().timestamp()),
            player1_id,
            player2_id,
            status: PvpStatus::Pending,
            rounds: Vec::new(),
            winner: None,
            created_at: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
            ended_at: None,
            xp_reward: 0,
            streak_effect: false,
        }
    }

    pub fn start_match(&mut self) -> Result<()> {
        if self.status != PvpStatus::Pending {
            return Err(anyhow::anyhow!("Match is not in pending status"));
        }
        
        self.status = PvpStatus::Active;
        Ok(())
    }

    pub fn process_round(&mut self, player1_action: PvpAction, player2_action: PvpAction) -> Result<PvpRound> {
        if self.status != PvpStatus::Active {
            return Err(anyhow::anyhow!("Match is not active"));
        }

        let round_number = self.rounds.len() as u32 + 1;
        
        // Calculate damage based on actions
        let (player1_damage, player2_damage) = self.calculate_damage(&player1_action, &player2_action);
        
        // Determine round winner
        let winner = if player1_damage > player2_damage {
            Some(self.player1_id.clone())
        } else if player2_damage > player1_damage {
            Some(self.player2_id.clone())
        } else {
            None
        };

        let round = PvpRound {
            round_number,
            player1_action,
            player2_action,
            player1_damage,
            player2_damage,
            winner,
            trade_outcome: None, // Will be populated with actual trade data
        };

        self.rounds.push(round.clone());

        // Check if match is over (best of 3 rounds)
        if self.rounds.len() >= 3 {
            self.end_match();
        }

        Ok(round)
    }
    
    /// Add trade outcome data to a specific round
    pub fn add_trade_outcome(&mut self, round_number: u32, outcome: TradeOutcome) -> Result<()> {
        if let Some(round) = self.rounds.iter_mut().find(|r| r.round_number == round_number) {
            round.trade_outcome = Some(outcome);
            Ok(())
        } else {
            Err(anyhow::anyhow!("Round {} not found", round_number))
        }
    }

    fn calculate_damage(&self, action1: &PvpAction, action2: &PvpAction) -> (u32, u32) {
        let mut rng = rand::thread_rng();
        
        let base_damage = rng.gen_range(10..30);
        
        let (damage1, damage2) = match (action1, action2) {
            (PvpAction::Attack, PvpAction::Defend) => (base_damage / 2, 0),
            (PvpAction::Defend, PvpAction::Attack) => (0, base_damage / 2),
            (PvpAction::Attack, PvpAction::Attack) => (base_damage, base_damage),
            (PvpAction::Defend, PvpAction::Defend) => (0, 0),
            (PvpAction::Special, _) => (base_damage * 2, base_damage),
            (_, PvpAction::Special) => (base_damage, base_damage * 2),
            (PvpAction::Heal, _) => (0, base_damage),
            (_, PvpAction::Heal) => (base_damage, 0),
        };

        (damage1, damage2)
    }

    pub fn end_match(&mut self) {
        self.status = PvpStatus::Completed;
        self.ended_at = Some(
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs()
        );

        // Determine overall winner
        let mut player1_wins = 0;
        let mut player2_wins = 0;

        for round in &self.rounds {
            if let Some(winner) = &round.winner {
                if winner == &self.player1_id {
                    player1_wins += 1;
                } else {
                    player2_wins += 1;
                }
            }
        }

        self.winner = if player1_wins > player2_wins {
            Some(self.player1_id.clone())
        } else if player2_wins > player1_wins {
            Some(self.player2_id.clone())
        } else {
            None
        };
    }

    pub fn cancel_match(&mut self) -> Result<()> {
        if self.status == PvpStatus::Completed {
            return Err(anyhow::anyhow!("Cannot cancel completed match"));
        }
        
        self.status = PvpStatus::Cancelled;
        self.ended_at = Some(
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs()
        );
        
        Ok(())
    }

    pub fn get_match_duration(&self) -> Option<u64> {
        self.ended_at.map(|end_time| end_time - self.created_at)
    }

    pub fn get_total_damage(&self) -> (u32, u32) {
        let mut player1_total = 0;
        let mut player2_total = 0;

        for round in &self.rounds {
            player1_total += round.player1_damage;
            player2_total += round.player2_damage;
        }

        (player1_total, player2_total)
    }

    pub fn is_player_in_match(&self, player_id: &str) -> bool {
        self.player1_id == player_id || self.player2_id == player_id
    }

    pub fn get_opponent(&self, player_id: &str) -> Option<&String> {
        if self.player1_id == player_id {
            Some(&self.player2_id)
        } else if self.player2_id == player_id {
            Some(&self.player1_id)
        } else {
            None
        }
    }
}

impl PvpStats {
    pub fn new(player_id: String) -> Self {
        Self {
            player_id,
            wins: 0,
            losses: 0,
            total_damage_dealt: 0,
            total_damage_taken: 0,
            average_rounds: 0.0,
        }
    }

    pub fn update_from_match(&mut self, match_data: &PvpMatch) {
        if !match_data.is_player_in_match(&self.player_id) {
            return;
        }

        let (damage_dealt, damage_taken) = if match_data.player1_id == self.player_id {
            match_data.get_total_damage()
        } else {
            let (p1_damage, p2_damage) = match_data.get_total_damage();
            (p2_damage, p1_damage)
        };

        self.total_damage_dealt += damage_dealt;
        self.total_damage_taken += damage_taken;

        if let Some(winner) = &match_data.winner {
            if winner == &self.player_id {
                self.wins += 1;
            } else {
                self.losses += 1;
            }
        }

        // Update average rounds
        let total_matches = self.wins + self.losses;
        if total_matches > 0 {
            self.average_rounds = (match_data.rounds.len() as f32 + self.average_rounds * (total_matches - 1) as f32) / total_matches as f32;
        }
    }

    pub fn get_win_rate(&self) -> f32 {
        let total_matches = self.wins + self.losses;
        if total_matches == 0 {
            0.0
        } else {
            self.wins as f32 / total_matches as f32
        }
    }

    pub fn get_kdr(&self) -> f32 {
        if self.total_damage_taken == 0 {
            self.total_damage_dealt as f32
        } else {
            self.total_damage_dealt as f32 / self.total_damage_taken as f32
        }
    }
    
    /// Update stats with XP changes from PvP
    pub fn apply_pvp_result(&mut self, resolution: &PvpResolution) {
        if resolution.winner == self.player_id {
            self.wins += 1;
        } else if resolution.loser == self.player_id {
            self.losses += 1;
        }
    }
}

/// PvP match manager for handling multiple concurrent matches
#[derive(Debug, Clone)]
pub struct PvpMatchManager {
    active_matches: HashMap<String, PvpMatch>,
    player_matches: HashMap<String, String>, // player_id -> match_id
}

impl PvpMatchManager {
    pub fn new() -> Self {
        Self {
            active_matches: HashMap::new(),
            player_matches: HashMap::new(),
        }
    }
    
    /// Create a new PvP match
    pub fn create_match(&mut self, player1_id: String, player2_id: String) -> Result<String> {
        // Check if either player is already in a match
        if self.player_matches.contains_key(&player1_id) {
            return Err(anyhow::anyhow!("Player {} is already in a match", player1_id));
        }
        if self.player_matches.contains_key(&player2_id) {
            return Err(anyhow::anyhow!("Player {} is already in a match", player2_id));
        }
        
        let match_data = PvpMatch::new(player1_id.clone(), player2_id.clone());
        let match_id = match_data.id.clone();
        
        self.active_matches.insert(match_id.clone(), match_data);
        self.player_matches.insert(player1_id, match_id.clone());
        self.player_matches.insert(player2_id, match_id.clone());
        
        Ok(match_id)
    }
    
    /// Get a match by ID
    pub fn get_match(&self, match_id: &str) -> Option<&PvpMatch> {
        self.active_matches.get(match_id)
    }
    
    /// Get a mutable match by ID
    pub fn get_match_mut(&mut self, match_id: &str) -> Option<&mut PvpMatch> {
        self.active_matches.get_mut(match_id)
    }
    
    /// Get match ID for a player
    pub fn get_player_match_id(&self, player_id: &str) -> Option<&String> {
        self.player_matches.get(player_id)
    }
    
    /// Complete and remove a match
    pub fn complete_match(&mut self, match_id: &str) -> Option<PvpMatch> {
        if let Some(match_data) = self.active_matches.remove(match_id) {
            self.player_matches.remove(&match_data.player1_id);
            self.player_matches.remove(&match_data.player2_id);
            Some(match_data)
        } else {
            None
        }
    }
    
    /// Get all active matches
    pub fn get_active_matches(&self) -> &HashMap<String, PvpMatch> {
        &self.active_matches
    }
}