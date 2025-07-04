use crate::infra::starknet::StarknetClient;
use crate::events::reward::RewardEvent;
use crate::events::tile::TileEvent;
use crate::events::pvp::PvpEvent;
use crate::events::streak::StreakEvent;
use crate::game_engine::player::PlayerService;
use crate::game_engine::tile::TileService;
use crate::game_engine::tile::TileServiceTrait;
use crate::game_engine::rewards::RewardService;
use crate::game_engine::rewards::RewardServiceTrait;
use crate::game_engine::streak::StreakService;
use crate::game_engine::streak::StreakServiceTrait;
use crate::game_engine::pvp::PvPService;
use crate::infra::kafka::KafkaEventDispatcher;
use crate::infra::db::Database;
use anyhow::Result;
use crate::game_engine::dispatcher::CompositeDispatcher;
use crate::infra::GameEventDispatcher;
use std::sync::Arc;
use crate::events::game_event::{GameEvent, GameEventType};
use sqlx::Row;

#[derive(Clone)]
pub struct GameEngine {
    pub dispatcher: Arc<dyn GameEventDispatcher>,
    pub starknet: StarknetClient,
    pub publisher: KafkaEventDispatcher,
    pub conquest: TileService,
    pub streaks: StreakService,
    pub pvp: PvPService,
    pub rewards: RewardService,
    pub db: Database,
}

pub struct MoveData {
    pub target_x: i32,
    pub target_y: i32,
}

#[derive(Debug)]
pub struct RewardSummary {
    pub ink: u32,
    pub nft_minted: bool,
    pub streak_updated: bool,
    pub conquest: Option<String>,
}

impl GameEngine {
    pub fn new(
        dispatcher: Arc<dyn GameEventDispatcher>,
        starknet: StarknetClient,
        publisher: KafkaEventDispatcher,
        conquest: TileService,
        streaks: StreakService,
        pvp: PvPService,
        rewards: RewardService,
        db: Database,
    ) -> Self {
        Self { dispatcher, starknet, publisher, conquest, streaks, pvp, rewards, db }
    }

    pub async fn process_move(&self, player_id: String, move_data: MoveData) -> Result<RewardSummary> {
        // 1. Validate move
        let valid = self.conquest.validate_tile_move(&player_id, &move_data).await?;
        if !valid {
            return Err(anyhow::anyhow!("Invalid move"));
        }
        // 2. Update player position/state
        self.conquest.update_player_position(&player_id, &move_data).await?;
        // 3. Mint NFT if eligible
        let nft_minted = self.rewards.mint_drip_nft(&player_id).await?;
        // 4. Update streaks
        let streak_updated = self.streaks.update_streak(&player_id).await?;
        // 5. Publish events
        let xp_amount = 25;
        let mut xp_event = GameEvent::new(GameEventType::XpEarned, player_id.clone());
        xp_event.amount = Some(xp_amount);
        self.dispatcher.dispatch(&xp_event).await?;
        self.publisher.send_player_move(&player_id, "move", (move_data.target_x, move_data.target_y)).await?;
        // 6. Return summary
        Ok(RewardSummary {
            ink: 10,
            nft_minted,
            streak_updated,
            conquest: Some("tile_id".to_string()),
        })
    }

    pub async fn finalize_pvp_match(&self, mut pvp_match: crate::game_engine::pvp::PvpMatch) -> Result<()> {
        // Begin DB transaction
        let mut tx = self.db.begin_transaction().await?;
        
        // Check if match is already completed in DB
        let query = sqlx::query("SELECT status FROM pvp_sessions WHERE id = $1")
            .bind(&pvp_match.id);
        let row = query.fetch_optional(&mut *tx).await?;
        if let Some(row) = row {
            let status: String = row.get("status");
            if status == "Completed" {
                return Ok(()); // Already finalized, skip
            }
        }
        
        // Ensure match is completed and winner is set
        if pvp_match.status != crate::game_engine::pvp::PvpStatus::Completed || pvp_match.winner.is_none() {
            pvp_match.end_match();
        }
        
        let winner = match &pvp_match.winner {
            Some(w) => w.clone(),
            None => {
                return Err(anyhow::anyhow!("No winner for PvP match"));
            }
        };
        
        let loser = if pvp_match.player1_id == winner {
            pvp_match.player2_id.clone()
        } else {
            pvp_match.player1_id.clone()
        };
        
        // Emit PvP result event
        let event = GameEvent::pvp_result(winner.clone(), loser.clone());
        self.dispatcher.dispatch(&event).await?;
        
        // Grant XP and update streak for winner
        let xp_amount = 50;
        let mut xp_event = GameEvent::new(GameEventType::XpEarned, winner.clone());
        xp_event.amount = Some(xp_amount);
        self.dispatcher.dispatch(&xp_event).await?;
        
        self.streaks.update_streak(&winner).await?;
        
        // Persist PvP result atomically
        self.db.save_pvp_result_tx(&pvp_match, &mut tx).await?;
        
        tx.commit().await?;
        Ok(())
    }
} 