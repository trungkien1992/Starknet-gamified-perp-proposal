use std::sync::Arc;
use std::time::Duration;
use anyhow::Result;
use tokio::time::interval;
use crate::game_engine::streak::StreakManager;
use crate::infra::{db::Database, GameEventDispatcher};

pub struct StreakScheduler {
    streak_manager: Arc<tokio::sync::Mutex<StreakManager>>,
    database: Database,
    dispatcher: Arc<dyn GameEventDispatcher>,
}

impl StreakScheduler {
    pub fn new(
        streak_manager: Arc<tokio::sync::Mutex<StreakManager>>,
        database: Database,
        dispatcher: Arc<dyn GameEventDispatcher>,
    ) -> Self {
        Self {
            streak_manager,
            database,
            dispatcher,
        }
    }

    pub async fn start_streak_monitoring(&self) -> Result<()> {
        let mut interval = interval(Duration::from_secs(6 * 60 * 60)); // 6 hours
        
        loop {
            interval.tick().await;
            
            if let Err(e) = self.check_and_reset_inactive_streaks().await {
                eprintln!("Error checking inactive streaks: {}", e);
            }
        }
    }

    async fn check_and_reset_inactive_streaks(&self) -> Result<()> {
        // Get all players from the database
        let players = self.database.get_all_active_players().await
            .unwrap_or_else(|e| {
                eprintln!("Failed to get players for streak checking: {}", e);
                Vec::new()
            });

        let mut streak_manager = self.streak_manager.lock().await;
        
        // Check for inactive players and reset streaks
        let events = streak_manager
            .check_inactive_players_and_reset_streaks(&players, self.dispatcher.clone())
            .await?;

        println!("Processed {} streak reset events", events.len());
        
        Ok(())
    }
}

// Add this trait to the StreakScheduler for easy spawning
impl StreakScheduler {
    pub fn spawn_background_task(self: Arc<Self>) -> tokio::task::JoinHandle<()> {
        tokio::spawn(async move {
            if let Err(e) = self.start_streak_monitoring().await {
                eprintln!("Streak monitoring task failed: {}", e);
            }
        })
    }
}