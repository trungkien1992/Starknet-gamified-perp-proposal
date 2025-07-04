use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use anyhow::Result;
use async_trait::async_trait;
use crate::events::game_event::{GameEvent, GameEventType};
use crate::infra::GameEventDispatcher;
use std::sync::Arc;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Streak {
    pub player_id: String,
    pub current_streak: u32,
    pub longest_streak: u32,
    pub streak_type: StreakType,
    pub last_activity: u64,
    pub streak_start: u64,
    pub rewards_claimed: Vec<u32>,
    pub multiplier: f32,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum StreakType {
    Daily,
    Weekly,
    Monthly,
    ConsecutiveWins,
    ConsecutiveMoves,
    ResourceHarvest,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreakReward {
    pub streak_count: u32,
    pub reward_type: String,
    pub reward_amount: u32,
    pub multiplier_bonus: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreakConfig {
    pub max_streak: u32,
    pub reset_threshold: u64, // seconds
    pub rewards: Vec<StreakReward>,
    pub multiplier_cap: f32,
}

impl Streak {
    pub fn new(player_id: String) -> Self {
        let current_time = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs();

        Self {
            player_id,
            current_streak: 0,
            longest_streak: 0,
            streak_type: StreakType::Daily,
            last_activity: current_time,
            streak_start: current_time,
            rewards_claimed: Vec::new(),
            multiplier: 1.0,
        }
    }

    pub fn update(&mut self, config: &StreakConfig) -> Result<()> {
        let current_time = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs();

        // Check if streak should reset
        if current_time - self.last_activity > config.reset_threshold {
            self.reset_streak();
        } else {
            // Increment streak
            self.current_streak += 1;
            if self.current_streak > self.longest_streak {
                self.longest_streak = self.current_streak;
            }
        }

        self.last_activity = current_time;

        // Update multiplier based on current streak
        self.update_multiplier(config);

        Ok(())
    }

    pub fn reset_streak(&mut self) {
        self.current_streak = 0;
        self.multiplier = 1.0;
        self.streak_start = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs();
    }

    fn update_multiplier(&mut self, config: &StreakConfig) {
        // Calculate multiplier based on current streak
        let base_multiplier = 1.0 + (self.current_streak as f32 * 0.1);
        self.multiplier = base_multiplier.min(config.multiplier_cap);
    }

    pub fn get_available_rewards<'a>(&self, config: &'a StreakConfig) -> Vec<&'a StreakReward> {
        config.rewards
            .iter()
            .filter(|reward| {
                reward.streak_count <= self.current_streak && 
                !self.rewards_claimed.contains(&reward.streak_count)
            })
            .collect()
    }

    pub fn claim_reward(&mut self, streak_count: u32, config: &StreakConfig) -> Result<StreakReward> {
        // Check if reward is available
        if !self.get_available_rewards(config)
            .iter()
            .any(|r| r.streak_count == streak_count) {
            return Err(anyhow::anyhow!("Reward not available for streak count {}", streak_count));
        }

        // Find the reward
        let reward = config.rewards
            .iter()
            .find(|r| r.streak_count == streak_count)
            .ok_or_else(|| anyhow::anyhow!("Reward not found"))?;

        // Mark as claimed
        self.rewards_claimed.push(streak_count);

        // Apply multiplier bonus
        self.multiplier += reward.multiplier_bonus;
        self.multiplier = self.multiplier.min(config.multiplier_cap);

        Ok(reward.clone())
    }

    pub fn get_streak_duration(&self) -> u64 {
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs() - self.streak_start
    }

    pub fn get_time_until_reset(&self, config: &StreakConfig) -> u64 {
        let time_since_last_activity = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs() - self.last_activity;

        if time_since_last_activity >= config.reset_threshold {
            0
        } else {
            config.reset_threshold - time_since_last_activity
        }
    }

    pub fn is_active(&self, config: &StreakConfig) -> bool {
        let current_time = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs();

        current_time - self.last_activity <= config.reset_threshold
    }

    pub fn get_streak_progress(&self, config: &StreakConfig) -> f32 {
        if config.max_streak == 0 {
            0.0
        } else {
            (self.current_streak as f32 / config.max_streak as f32).min(1.0)
        }
    }
}

impl StreakConfig {
    pub fn daily() -> Self {
        Self {
            max_streak: 30,
            reset_threshold: 86400, // 24 hours
            rewards: vec![
                StreakReward { streak_count: 3, reward_type: "coins".to_string(), reward_amount: 100, multiplier_bonus: 0.1 },
                StreakReward { streak_count: 7, reward_type: "coins".to_string(), reward_amount: 300, multiplier_bonus: 0.2 },
                StreakReward { streak_count: 14, reward_type: "coins".to_string(), reward_amount: 600, multiplier_bonus: 0.3 },
                StreakReward { streak_count: 30, reward_type: "coins".to_string(), reward_amount: 1500, multiplier_bonus: 0.5 },
            ],
            multiplier_cap: 3.0,
        }
    }

    pub fn weekly() -> Self {
        Self {
            max_streak: 12,
            reset_threshold: 604800, // 7 days
            rewards: vec![
                StreakReward { streak_count: 2, reward_type: "coins".to_string(), reward_amount: 500, multiplier_bonus: 0.2 },
                StreakReward { streak_count: 4, reward_type: "coins".to_string(), reward_amount: 1000, multiplier_bonus: 0.3 },
                StreakReward { streak_count: 8, reward_type: "coins".to_string(), reward_amount: 2000, multiplier_bonus: 0.4 },
                StreakReward { streak_count: 12, reward_type: "coins".to_string(), reward_amount: 5000, multiplier_bonus: 0.6 },
            ],
            multiplier_cap: 4.0,
        }
    }

    pub fn consecutive_wins() -> Self {
        Self {
            max_streak: 10,
            reset_threshold: 0, // Resets immediately on loss
            rewards: vec![
                StreakReward { streak_count: 3, reward_type: "badge".to_string(), reward_amount: 1, multiplier_bonus: 0.1 },
                StreakReward { streak_count: 5, reward_type: "badge".to_string(), reward_amount: 1, multiplier_bonus: 0.2 },
                StreakReward { streak_count: 10, reward_type: "badge".to_string(), reward_amount: 1, multiplier_bonus: 0.3 },
            ],
            multiplier_cap: 2.0,
        }
    }
}

pub struct StreakManager {
    streaks: HashMap<String, Streak>,
    configs: HashMap<StreakType, StreakConfig>,
}

impl StreakManager {
    pub fn new() -> Self {
        let mut configs = HashMap::new();
        configs.insert(StreakType::Daily, StreakConfig::daily());
        configs.insert(StreakType::Weekly, StreakConfig::weekly());
        configs.insert(StreakType::ConsecutiveWins, StreakConfig::consecutive_wins());

        Self {
            streaks: HashMap::new(),
            configs,
        }
    }

    pub fn get_or_create_streak(&mut self, player_id: &str, streak_type: StreakType) -> &mut Streak {
        let key = format!("{}:{:?}", player_id, streak_type);
        self.streaks.entry(key).or_insert_with(|| {
            let mut streak = Streak::new(player_id.to_string());
            streak.streak_type = streak_type;
            streak
        })
    }

    pub fn update_streak(&mut self, player_id: &str, streak_type: StreakType) -> Result<()> {
        let config = self.configs.get(&streak_type)
            .ok_or_else(|| anyhow::anyhow!("No config found for streak type"))?
            .clone();
        let streak = self.get_or_create_streak(player_id, streak_type.clone());
        
        streak.update(&config)
    }

    pub fn get_streak(&self, player_id: &str, streak_type: StreakType) -> Option<&Streak> {
        let key = format!("{}:{:?}", player_id, streak_type);
        self.streaks.get(&key)
    }

    pub fn claim_reward(&mut self, player_id: &str, streak_type: StreakType, streak_count: u32) -> Result<StreakReward> {
        let config = self.configs.get(&streak_type)
            .ok_or_else(|| anyhow::anyhow!("No config found for streak type"))?
            .clone();
        let streak = self.get_or_create_streak(player_id, streak_type.clone());
        
        streak.claim_reward(streak_count, &config)
    }

    pub fn get_all_streaks(&self, player_id: &str) -> Vec<&Streak> {
        self.streaks
            .iter()
            .filter(|(key, _)| key.starts_with(player_id))
            .map(|(_, streak)| streak)
            .collect()
    }

    pub fn reset_streak(&mut self, player_id: &str, streak_type: StreakType) {
        let streak = self.get_or_create_streak(player_id, streak_type);
        streak.reset_streak();
    }

    pub async fn check_inactive_players_and_reset_streaks(
        &mut self, 
        players: &[crate::game_engine::player::Player],
        dispatcher: Arc<dyn GameEventDispatcher>
    ) -> Result<Vec<GameEvent>> {
        let mut events = Vec::new();
        let inactive_threshold = 24 * 60 * 60; // 24 hours in seconds
        
        for player in players {
            // Check if player hasn't traded in 24 hours
            if !player.has_traded_within(inactive_threshold) {
                // Check all streak types for this player
                for streak_type in [StreakType::Daily, StreakType::Weekly, StreakType::ConsecutiveWins] {
                    if let Some(streak) = self.get_streak(&player.id, streak_type.clone()) {
                        if streak.current_streak > 0 {
                            let lost_streak = streak.current_streak;
                            
                            // Reset the streak
                            self.reset_streak(&player.id, streak_type.clone());
                            
                            // Create and dispatch the event
                            let event = GameEvent::streak_reset(
                                player.id.clone(),
                                lost_streak,
                                "inactivity_timeout".to_string()
                            );
                            
                            // Dispatch the event
                            if let Err(e) = dispatcher.dispatch(&event).await {
                                eprintln!("Failed to dispatch streak reset event for player {}: {}", player.id, e);
                            }
                            
                            events.push(event);
                        }
                    }
                }
            }
        }
        
        Ok(events)
    }
}

#[async_trait]
pub trait StreakServiceTrait: Send + Sync {
    async fn update_streak(&self, player_id: &str) -> Result<bool>;
}

#[derive(Clone)]
pub struct StreakService {
    dispatcher: Arc<dyn GameEventDispatcher>,
}

impl StreakService {
    pub fn new(dispatcher: Arc<dyn GameEventDispatcher>) -> Self {
        Self { dispatcher }
    }
}

#[async_trait]
impl StreakServiceTrait for StreakService {
    async fn update_streak(&self, player_id: &str) -> Result<bool> {
        // TODO: Implement streak update logic
        let mut event = GameEvent::new(GameEventType::StreakMilestone, player_id.to_string());
        event.streak = Some(3); // Example: 3-day streak
        self.dispatcher.dispatch(&event).await?;
        Ok(true)
    }
} 