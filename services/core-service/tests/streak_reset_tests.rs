#[cfg(test)]
mod streak_reset_tests {
    use std::sync::Arc;
    use core_service::game_engine::player::Player;
    use core_service::game_engine::streak::{StreakManager, StreakType};
    use core_service::events::game_event::{GameEvent, GameEventType};
    use core_service::infra::GameEventDispatcher;
    use anyhow::Result;
    use async_trait::async_trait;
    use std::sync::Mutex;

    // Mock event dispatcher for testing
    struct MockEventDispatcher {
        events: Arc<Mutex<Vec<GameEvent>>>,
    }

    impl MockEventDispatcher {
        fn new() -> Self {
            Self {
                events: Arc::new(Mutex::new(Vec::new())),
            }
        }

        fn get_events(&self) -> Vec<GameEvent> {
            self.events.lock().unwrap().clone()
        }
    }

    #[async_trait]
    impl GameEventDispatcher for MockEventDispatcher {
        async fn dispatch(&self, event: &GameEvent) -> Result<()> {
            self.events.lock().unwrap().push(event.clone());
            Ok(())
        }
    }

    #[tokio::test]
    async fn test_streak_reset_on_inactivity() {
        let mut streak_manager = StreakManager::new();
        let mock_dispatcher = Arc::new(MockEventDispatcher::new());

        // Create a player with a current streak but no recent trade
        let mut player = Player::new("test_player".to_string());
        
        // Simulate player having a streak
        let _ = streak_manager.update_streak(&player.id, StreakType::Daily);
        let _ = streak_manager.update_streak(&player.id, StreakType::Daily);
        let _ = streak_manager.update_streak(&player.id, StreakType::Daily);
        
        // Verify streak exists
        let streak = streak_manager.get_streak(&player.id, StreakType::Daily);
        assert!(streak.is_some());
        assert!(streak.unwrap().current_streak > 0);

        // Player hasn't traded (last_trade_at is None), so should trigger reset
        let players = vec![player];
        
        // Check for inactive players and reset streaks
        let events = streak_manager
            .check_inactive_players_and_reset_streaks(&players, mock_dispatcher.clone())
            .await
            .unwrap();

        // Verify that streak reset events were generated
        assert!(!events.is_empty());
        
        let dispatched_events = mock_dispatcher.get_events();
        assert!(!dispatched_events.is_empty());
        
        // Check that the event is a streak reset event
        let reset_event = &dispatched_events[0];
        assert!(matches!(reset_event.event_type, GameEventType::StreakReset));
        assert_eq!(reset_event.player_id, "test_player");
        assert!(reset_event.streak.is_some());
        assert!(reset_event.streak.unwrap() > 0);
    }

    #[tokio::test]
    async fn test_no_streak_reset_for_active_player() {
        let mut streak_manager = StreakManager::new();
        let mock_dispatcher = Arc::new(MockEventDispatcher::new());

        // Create a player with recent trade activity
        let mut player = Player::new("active_player".to_string());
        player.record_trade(); // This sets last_trade_at to current time
        
        // Simulate player having a streak
        let _ = streak_manager.update_streak(&player.id, StreakType::Daily);
        
        // Verify streak exists
        let streak = streak_manager.get_streak(&player.id, StreakType::Daily);
        assert!(streak.is_some());
        assert!(streak.unwrap().current_streak > 0);

        let players = vec![player];
        
        // Check for inactive players and reset streaks
        let events = streak_manager
            .check_inactive_players_and_reset_streaks(&players, mock_dispatcher.clone())
            .await
            .unwrap();

        // Verify that no events were generated for active player
        assert!(events.is_empty());
        
        let dispatched_events = mock_dispatcher.get_events();
        assert!(dispatched_events.is_empty());
    }

    #[test]
    fn test_player_trade_tracking() {
        let mut player = Player::new("trade_test_player".to_string());
        
        // Initially, player hasn't traded
        assert!(!player.has_traded_within(24 * 60 * 60));
        
        // Record a trade
        player.record_trade();
        
        // Now player has traded recently
        assert!(player.has_traded_within(24 * 60 * 60));
        assert!(player.has_traded_within(1)); // Even within 1 second
    }

    #[test]
    fn test_streak_reset_event_creation() {
        let event = GameEvent::streak_reset(
            "test_player".to_string(),
            5,
            "inactivity_timeout".to_string(),
        );

        assert!(matches!(event.event_type, GameEventType::StreakReset));
        assert_eq!(event.player_id, "test_player");
        assert_eq!(event.streak, Some(5));
        assert!(event.payload.is_some());
        
        // Check payload contains expected fields
        let payload = event.payload.unwrap();
        assert!(payload.get("lost_streak").is_some());
        assert!(payload.get("reason").is_some());
    }
}