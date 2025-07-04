use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use anyhow::Result;
use async_trait::async_trait;
use std::str::FromStr;

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

#[async_trait]
pub trait PvpServiceTrait: Send + Sync {
    // Add async methods as needed for mocking
    async fn start_match(&self, player1_id: &str, player2_id: &str) -> Result<bool>;
}

#[derive(Clone)]
pub struct PvPService;

impl PvPService {
    pub fn new() -> Self {
        Self
    }
}

#[async_trait]
impl PvpServiceTrait for PvPService {
    async fn start_match(&self, _player1_id: &str, _player2_id: &str) -> Result<bool> {
        // TODO: Implement PvP match start logic
        Ok(true)
    }
}

impl PvpMatch {
    pub fn new(player1_id: String, player2_id: String) -> Self {
        Self {
            id: format!("{}_{}", player1_id, player2_id),
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
        };

        self.rounds.push(round.clone());

        // Check if match is over (best of 3 rounds)
        if self.rounds.len() >= 3 {
            self.end_match();
        }

        Ok(round)
    }

    fn calculate_damage(&self, action1: &PvpAction, action2: &PvpAction) -> (u32, u32) {
        use rand::Rng;
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
} 