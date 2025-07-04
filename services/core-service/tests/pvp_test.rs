use core_service::game_engine::pvp::*;
use core_service::events::game_event::{GameEvent, GameEventType};
use core_service::infra::GameEventDispatcher;
use anyhow::Result;
use async_trait::async_trait;
use std::sync::{Arc, Mutex};
use tokio;

/// Mock event dispatcher for testing
#[derive(Debug, Clone)]
pub struct MockEventDispatcher {
    pub events: Arc<Mutex<Vec<GameEvent>>>,
}

impl MockEventDispatcher {
    pub fn new() -> Self {
        Self {
            events: Arc::new(Mutex::new(Vec::new())),
        }
    }
    
    pub fn get_events(&self) -> Vec<GameEvent> {
        self.events.lock().unwrap().clone()
    }
    
    pub fn clear_events(&self) {
        self.events.lock().unwrap().clear();
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
async fn test_pvp_match_creation() {
    let mut manager = PvpMatchManager::new();
    
    // Create a new match
    let match_id = manager.create_match("player1".to_string(), "player2".to_string()).unwrap();
    
    // Verify match exists
    let match_data = manager.get_match(&match_id).unwrap();
    assert_eq!(match_data.player1_id, "player1");
    assert_eq!(match_data.player2_id, "player2");
    assert_eq!(match_data.status, PvpStatus::Pending);
    assert_eq!(match_data.rounds.len(), 0);
    
    // Verify players are tracked
    assert_eq!(manager.get_player_match_id("player1"), Some(&match_id));
    assert_eq!(manager.get_player_match_id("player2"), Some(&match_id));
    
    // Try to create another match with same player - should fail
    assert!(manager.create_match("player1".to_string(), "player3".to_string()).is_err());
}

#[tokio::test]
async fn test_pvp_match_lifecycle() {
    let mut match_data = PvpMatch::new("player1".to_string(), "player2".to_string());
    
    // Start match
    assert!(match_data.start_match().is_ok());
    assert_eq!(match_data.status, PvpStatus::Active);
    
    // Cannot start again
    assert!(match_data.start_match().is_err());
    
    // Process rounds
    let round1 = match_data.process_round(PvpAction::Attack, PvpAction::Defend).unwrap();
    assert_eq!(round1.round_number, 1);
    assert_eq!(match_data.rounds.len(), 1);
    
    let round2 = match_data.process_round(PvpAction::Special, PvpAction::Attack).unwrap();
    assert_eq!(round2.round_number, 2);
    assert_eq!(match_data.rounds.len(), 2);
    
    let round3 = match_data.process_round(PvpAction::Heal, PvpAction::Attack).unwrap();
    assert_eq!(round3.round_number, 3);
    assert_eq!(match_data.rounds.len(), 3);
    
    // Match should be completed after 3 rounds
    assert_eq!(match_data.status, PvpStatus::Completed);
    assert!(match_data.winner.is_some());
    assert!(match_data.ended_at.is_some());
}

#[tokio::test]
async fn test_pvp_outcome_resolution() {
    let mock_dispatcher = Arc::new(MockEventDispatcher::new());
    let pvp_service = PvPService::new(mock_dispatcher.clone());
    
    // Create and complete a match
    let mut match_data = PvpMatch::new("alice".to_string(), "bob".to_string());
    match_data.start_match().unwrap();
    
    // Process rounds to complete the match
    match_data.process_round(PvpAction::Attack, PvpAction::Defend).unwrap();
    match_data.process_round(PvpAction::Special, PvpAction::Attack).unwrap(); 
    match_data.process_round(PvpAction::Attack, PvpAction::Heal).unwrap();
    
    assert_eq!(match_data.status, PvpStatus::Completed);
    
    // Create trade outcomes
    let trade_outcomes = vec![
        TradeOutcome {
            player_id: "alice".to_string(),
            pnl: 250.0, // Alice made profit
            volume: 1000.0,
            accuracy: 0.8,
        },
        TradeOutcome {
            player_id: "bob".to_string(),
            pnl: -50.0, // Bob lost money
            volume: 800.0,
            accuracy: 0.6,
        },
    ];
    
    // Resolve the PvP outcome
    let resolution = pvp_service.resolve_pvp_outcome(&mut match_data, trade_outcomes).await.unwrap();
    
    // Verify resolution results
    assert_eq!(resolution.winner, "alice"); // Alice should win with better trade performance
    assert_eq!(resolution.loser, "bob");
    assert!(resolution.xp_gained > 0);
    assert!(resolution.xp_lost > 0);
    assert!(!resolution.streak_broken); // Bob's loss wasn't significant enough
    
    // Verify events were emitted
    let events = mock_dispatcher.get_events();
    assert!(!events.is_empty());
    
    // Check for PvP result event
    let pvp_event = events.iter().find(|e| matches!(e.event_type, GameEventType::PvpResult));
    assert!(pvp_event.is_some());
    
    // Check for XP earned event
    let xp_event = events.iter().find(|e| matches!(e.event_type, GameEventType::XpEarned));
    assert!(xp_event.is_some());
    assert_eq!(xp_event.unwrap().player_id, "alice");
}

#[tokio::test]
async fn test_streak_breaking_scenario() {
    let mock_dispatcher = Arc::new(MockEventDispatcher::new());
    let pvp_service = PvPService::new(mock_dispatcher.clone());
    
    let mut match_data = PvpMatch::new("winner".to_string(), "loser".to_string());
    match_data.start_match().unwrap();
    
    // Complete the match (winner wins all rounds)
    match_data.process_round(PvpAction::Attack, PvpAction::Defend).unwrap();
    match_data.process_round(PvpAction::Special, PvpAction::Heal).unwrap();
    match_data.process_round(PvpAction::Attack, PvpAction::Defend).unwrap();
    
    // Create trade outcomes with significant loss for the loser
    let trade_outcomes = vec![
        TradeOutcome {
            player_id: "winner".to_string(),
            pnl: 500.0,
            volume: 2000.0,
            accuracy: 0.9,
        },
        TradeOutcome {
            player_id: "loser".to_string(),
            pnl: -150.0, // Significant loss should break streak
            volume: 1500.0,
            accuracy: 0.3,
        },
    ];
    
    let resolution = pvp_service.resolve_pvp_outcome(&mut match_data, trade_outcomes).await.unwrap();
    
    // Verify streak was broken
    assert!(resolution.streak_broken);
    
    // Check for streak reset event
    let events = mock_dispatcher.get_events();
    let streak_reset_event = events.iter().find(|e| matches!(e.event_type, GameEventType::StreakReset));
    assert!(streak_reset_event.is_some());
    assert_eq!(streak_reset_event.unwrap().player_id, "loser");
}

#[tokio::test]
async fn test_trade_outcome_integration() {
    let mut match_data = PvpMatch::new("trader1".to_string(), "trader2".to_string());
    match_data.start_match().unwrap();
    
    // Process first round
    let round1 = match_data.process_round(PvpAction::Attack, PvpAction::Defend).unwrap();
    
    // Add trade outcome to the round
    let trade_outcome = TradeOutcome {
        player_id: "trader1".to_string(),
        pnl: 100.0,
        volume: 500.0,
        accuracy: 0.75,
    };
    
    match_data.add_trade_outcome(round1.round_number, trade_outcome.clone()).unwrap();
    
    // Verify trade outcome was added
    let updated_round = &match_data.rounds[0];
    assert!(updated_round.trade_outcome.is_some());
    assert_eq!(updated_round.trade_outcome.as_ref().unwrap().player_id, "trader1");
    assert_eq!(updated_round.trade_outcome.as_ref().unwrap().pnl, 100.0);
    
    // Try to add outcome to non-existent round
    assert!(match_data.add_trade_outcome(99, trade_outcome).is_err());
}

#[tokio::test]
async fn test_pvp_stats_tracking() {
    let mut stats = PvpStats::new("player1".to_string());
    
    // Initial state
    assert_eq!(stats.wins, 0);
    assert_eq!(stats.losses, 0);
    assert_eq!(stats.get_win_rate(), 0.0);
    
    // Create a completed match where player1 wins
    let mut match_data = PvpMatch::new("player1".to_string(), "player2".to_string());
    match_data.start_match().unwrap();
    match_data.process_round(PvpAction::Attack, PvpAction::Defend).unwrap();
    match_data.process_round(PvpAction::Special, PvpAction::Heal).unwrap();
    match_data.process_round(PvpAction::Attack, PvpAction::Defend).unwrap();
    
    // Force player1 as winner for test
    match_data.winner = Some("player1".to_string());
    
    // Update stats
    stats.update_from_match(&match_data);
    
    // Verify stats updated
    assert_eq!(stats.wins, 1);
    assert_eq!(stats.losses, 0);
    assert_eq!(stats.get_win_rate(), 1.0);
    assert!(stats.total_damage_dealt > 0);
    
    // Test with a loss
    let mut loss_match = PvpMatch::new("player1".to_string(), "player3".to_string());
    loss_match.winner = Some("player3".to_string());
    loss_match.rounds.push(PvpRound {
        round_number: 1,
        player1_action: PvpAction::Defend,
        player2_action: PvpAction::Attack,
        player1_damage: 0,
        player2_damage: 25,
        winner: Some("player3".to_string()),
        trade_outcome: None,
    });
    
    stats.update_from_match(&loss_match);
    
    assert_eq!(stats.wins, 1);
    assert_eq!(stats.losses, 1);
    assert_eq!(stats.get_win_rate(), 0.5);
}

#[tokio::test]
async fn test_performance_score_calculation() {
    let mock_dispatcher = Arc::new(MockEventDispatcher::new());
    let pvp_service = PvPService::new(mock_dispatcher);
    
    // Create match with mixed PvP results
    let mut match_data = PvpMatch::new("player1".to_string(), "player2".to_string());
    match_data.rounds = vec![
        PvpRound {
            round_number: 1,
            player1_action: PvpAction::Attack,
            player2_action: PvpAction::Defend,
            player1_damage: 20,
            player2_damage: 0,
            winner: Some("player1".to_string()),
            trade_outcome: None,
        },
        PvpRound {
            round_number: 2,
            player1_action: PvpAction::Defend,
            player2_action: PvpAction::Special,
            player1_damage: 0,
            player2_damage: 30,
            winner: Some("player2".to_string()),
            trade_outcome: None,
        },
        PvpRound {
            round_number: 3,
            player1_action: PvpAction::Attack,
            player2_action: PvpAction::Heal,
            player1_damage: 25,
            player2_damage: 0,
            winner: Some("player1".to_string()),
            trade_outcome: None,
        },
    ];
    
    // Test trade outcomes
    let player1_outcome = TradeOutcome {
        player_id: "player1".to_string(),
        pnl: 200.0,
        volume: 1000.0,
        accuracy: 0.8,
    };
    
    let player2_outcome = TradeOutcome {
        player_id: "player2".to_string(),
        pnl: 50.0,
        volume: 800.0,
        accuracy: 0.6,
    };
    
    // Calculate scores
    let player1_score = pvp_service.calculate_performance_score(&match_data, "player1", &player1_outcome);
    let player2_score = pvp_service.calculate_performance_score(&match_data, "player2", &player2_outcome);
    
    // Player1 should have higher score (2/3 PvP wins + better trading)
    assert!(player1_score > player2_score);
    
    // Scores should be between 0 and 1
    assert!(player1_score >= 0.0 && player1_score <= 1.0);
    assert!(player2_score >= 0.0 && player2_score <= 1.0);
}

#[tokio::test]
async fn test_match_manager_concurrent_operations() {
    let mut manager = PvpMatchManager::new();
    
    // Create multiple matches
    let match1_id = manager.create_match("p1".to_string(), "p2".to_string()).unwrap();
    let match2_id = manager.create_match("p3".to_string(), "p4".to_string()).unwrap();
    
    // Verify both matches exist
    assert!(manager.get_match(&match1_id).is_some());
    assert!(manager.get_match(&match2_id).is_some());
    assert_eq!(manager.get_active_matches().len(), 2);
    
    // Complete one match
    let completed_match = manager.complete_match(&match1_id);
    assert!(completed_match.is_some());
    assert_eq!(manager.get_active_matches().len(), 1);
    
    // Players from completed match should be available
    assert!(manager.create_match("p1".to_string(), "p5".to_string()).is_ok());
    assert_eq!(manager.get_active_matches().len(), 2);
}

#[tokio::test]
async fn test_xp_reward_calculation() {
    let mock_dispatcher = Arc::new(MockEventDispatcher::new());
    let pvp_service = PvPService::new(mock_dispatcher);
    
    let winner_outcome = TradeOutcome {
        player_id: "winner".to_string(),
        pnl: 300.0,
        volume: 1500.0,
        accuracy: 0.9,
    };
    
    let loser_outcome = TradeOutcome {
        player_id: "loser".to_string(),
        pnl: -100.0,
        volume: 1200.0,
        accuracy: 0.4,
    };
    
    let (xp_gained, xp_lost) = pvp_service.calculate_xp_reward(&winner_outcome, &loser_outcome);
    
    // Winner should get base XP + bonuses
    assert!(xp_gained >= 100); // At least base XP
    assert!(xp_gained > 100);  // Should have bonuses for good performance
    
    // Loser should lose some XP but not too much
    assert!(xp_lost > 0);
    assert!(xp_lost <= 100); // Shouldn't lose more than base XP
}