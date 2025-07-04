use sqlx::{PgPool, Row, Transaction, Postgres};
use serde::{Deserialize, Serialize};
use anyhow::Result;
use std::collections::HashMap;
use std::str::FromStr;
use uuid::Uuid;
use crate::game_engine::pvp::PvpMatch;
use sqlx::postgres::PgPoolOptions;
use std::net::ToSocketAddrs;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlayerRecord {
    pub id: Uuid,
    pub position_x: i32,
    pub position_y: i32,
    pub health: u32,
    pub score: u32,
    pub level: u8,
    pub experience: u32,
    pub last_move: u64,
    pub created_at: u64,
    pub updated_at: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TileRecord {
    pub id: u32,
    pub position_x: i32,
    pub position_y: i32,
    pub owner_id: Option<Uuid>,
    pub level: u8,
    pub tile_type: String,
    pub last_updated: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PvpMatchRecord {
    pub id: Uuid,
    pub player1_id: Uuid,
    pub player2_id: Uuid,
    pub status: String,
    pub winner: Option<Uuid>,
    pub created_at: u64,
    pub ended_at: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StreakRecord {
    pub player_id: Uuid,
    pub streak_type: String,
    pub current_streak: u32,
    pub longest_streak: u32,
    pub last_activity: u64,
    pub streak_start: u64,
    pub multiplier: f32,
}

#[derive(Clone)]
pub struct Database {
    pool: PgPool,
}

impl Database {
    pub async fn new(database_url: &str) -> Result<Self> {
        tracing::info!("=== Database::new called ===");
        tracing::info!("Database URL provided: {}", database_url);
        tracing::info!("DATABASE_URL env var: {:?}", std::env::var("DATABASE_URL"));
        tracing::info!("SQLX_OFFLINE env var: {:?}", std::env::var("SQLX_OFFLINE"));
        
        // Check if we're in a test environment
        tracing::info!("CARGO_MANIFEST_DIR: {:?}", std::env::var("CARGO_MANIFEST_DIR"));
        tracing::info!("OUT_DIR: {:?}", std::env::var("OUT_DIR"));
        
        // Check for sqlx-data.json in various locations
        let possible_paths = [
            "sqlx-data.json",
            "../sqlx-data.json",
            "../../sqlx-data.json",
            "services/core-service/sqlx-data.json",
        ];
        
        for path in &possible_paths {
            let exists = std::path::Path::new(path).exists();
            tracing::info!("sqlx-data.json at {}: {}", path, exists);
        }
        
        // Log environment variables
        tracing::info!("DATABASE_URL: {:?}", std::env::var("DATABASE_URL"));
        tracing::info!("USER: {:?}", std::env::var("USER"));
        tracing::info!("PWD: {:?}", std::env::var("PWD"));
        // Log resolved IP for host.docker.internal
        match ("host.docker.internal", 5432).to_socket_addrs() {
            Ok(addrs) => {
                for addr in addrs {
                    tracing::info!("host.docker.internal resolves to: {}", addr);
                }
            },
            Err(e) => tracing::error!("Failed to resolve host.docker.internal: {}", e),
        }
        
        tracing::info!("Attempting to connect to database with PgPoolOptions::new()...");
        let pool = match PgPoolOptions::new()
            .max_connections(2)
            .acquire_timeout(std::time::Duration::from_secs(10))
            .connect(database_url)
            .await {
            Ok(pool) => {
                tracing::info!("Successfully connected to database with custom pool options");
                pool
            },
            Err(e) => {
                tracing::error!("PgPoolOptions::connect failed: {}", e);
                tracing::error!("Error chain: {:#?}", e);
                return Err(e.into());
            }
        };
        tracing::info!("=== End Database::new ===");
        Ok(Self { pool })
    }

    // Player operations
    pub async fn create_player(&self, player: &crate::game_engine::player::Player) -> Result<()> {
        let _query = sqlx::query(
            r#"
            INSERT INTO players (id, position_x, position_y, health, score, level, experience, last_move, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            "#
        )
        .bind(&player.id)
        .bind(player.position.0)
        .bind(player.position.1)
        .bind(player.health as i32)
        .bind(player.score as i32)
        .bind(player.level as i16)
        .bind(player.experience as i32)
        .bind(player.last_move as i64)
        .bind(player.last_move as i64)
        .bind(player.last_move as i64)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    pub async fn get_player(&self, player_id: &str) -> Result<Option<crate::game_engine::player::Player>> {
        let _query = sqlx::query(
            r#"
            SELECT id, position_x, position_y, health, score, level, experience, last_move, created_at, updated_at
            FROM players
            WHERE id = $1
            "#
        )
        .bind(player_id);
        
        let row = _query.fetch_optional(&self.pool).await?;

        if let Some(row) = row {
            let player = crate::game_engine::player::Player {
                id: row.get::<String, _>("id"),
                position: (row.get::<i32, _>("position_x"), row.get::<i32, _>("position_y")),
                health: row.get::<i32, _>("health") as u32,
                score: row.get::<i32, _>("score") as u32,
                level: row.get::<i16, _>("level") as u8,
                experience: row.get::<i32, _>("experience") as u32,
                last_move: row.get::<i64, _>("last_move") as u64,
                last_trade_at: row.try_get::<Option<i64>, _>("last_trade_at").ok().flatten().map(|t| t as u64),
                inventory: Vec::new(),
            };
            Ok(Some(player))
        } else {
            Ok(None)
        }
    }

    pub async fn update_player(&self, player: &crate::game_engine::player::Player) -> Result<()> {
        let _query = sqlx::query(
            r#"
            UPDATE players
            SET position_x = $2, position_y = $3, health = $4, score = $5, level = $6, experience = $7, last_move = $8, updated_at = $9
            WHERE id = $1
            "#
        )
        .bind(&player.id)
        .bind(player.position.0)
        .bind(player.position.1)
        .bind(player.health as i32)  // Convert u32 to i32
        .bind(player.score as i32)   // Convert u32 to i32
        .bind(player.level as i16)   // Convert u8 to i16
        .bind(player.experience as i32) // Convert u32 to i32
        .bind(player.last_move as i64)  // Convert u64 to i64
        .bind(player.last_move as i64) // Use last_move as updated_at
        .execute(&self.pool)
        .await?;

        tracing::info!("Updated player {} in database", player.id);
        Ok(())
    }

    // Tile operations
    pub async fn create_tile(&self, tile: &crate::game_engine::tile::Tile) -> Result<()> {
        tracing::info!("create_tile: tile.id (u32): {}", tile.id);
        tracing::info!("create_tile: tile.position: {:?}", tile.position);
        tracing::info!("create_tile: tile.owner: {:?}", tile.owner);
        tracing::info!("create_tile: tile.level (u8): {}", tile.level);
        tracing::info!("create_tile: tile.tile_type: {:?} as string: {}", tile.tile_type, tile.tile_type.to_string());
        tracing::info!("create_tile: tile.last_updated (u64): {}", tile.last_updated);
        // Log type conversions for validation
        tracing::info!("=== create_tile type validation ===");
        tracing::info!("tile.id: {} (u32) -> binding as i32: {}", tile.id, tile.id as i32);
        tracing::info!("tile.position.0: {} (i32)", tile.position.0);
        tracing::info!("tile.position.1: {} (i32)", tile.position.1);
        tracing::info!("tile.owner: {:?} (Option<String>)", tile.owner);
        tracing::info!("tile.level: {} (u8) -> binding as i32: {}", tile.level, tile.level as i32);
        tracing::info!("tile.tile_type: {:?} -> binding as string: {}", tile.tile_type, tile.tile_type.to_string());
        tracing::info!("tile.last_updated: {} (u64) -> binding as i64: {}", tile.last_updated, tile.last_updated as i64);
        tracing::info!("=== End create_tile type validation ===");
        
        let _query = sqlx::query(
            r#"
            INSERT INTO tiles (id, position_x, position_y, owner_id, level, tile_type, last_updated)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            "#
        )
        .bind(tile.id as i32)
        .bind(tile.position.0)
        .bind(tile.position.1)
        .bind(&tile.owner)
        .bind(tile.level as i32)
        .bind(tile.tile_type.to_string())
        .bind(tile.last_updated as i64)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    pub async fn get_tile(&self, tile_id: i32) -> Result<Option<crate::game_engine::tile::Tile>> {
        let _query = sqlx::query(
            r#"
            SELECT id, position_x, position_y, owner_id, level, tile_type, last_updated
            FROM tiles
            WHERE id = $1
            "#
        )
        .bind(tile_id);
        
        let row = _query.fetch_optional(&self.pool).await?;
        
        if let Some(row) = row {
            let id: i32 = row.get("id");
            let position_x: i32 = row.get("position_x");
            let position_y: i32 = row.get("position_y");
            let owner: Option<String> = row.get("owner_id");
            let level: i32 = row.get("level");
            let tile_type: String = row.get("tile_type");
            let last_updated: i64 = row.get("last_updated");
            tracing::info!("get_tile: id (i32): {}", id);
            tracing::info!("get_tile: position: ({}, {})", position_x, position_y);
            tracing::info!("get_tile: owner: {:?}", owner);
            tracing::info!("get_tile: level (i32): {}", level);
            tracing::info!("get_tile: tile_type (String): {}", tile_type);
            tracing::info!("get_tile: last_updated (i64): {}", last_updated);
            let tile = crate::game_engine::tile::Tile {
                id: id as u32,
                position: (position_x, position_y),
                owner,
                level: level as u8,
                tile_type: crate::game_engine::tile::TileType::Empty, // placeholder, will fix after validation
                resources: Vec::new(), // placeholder
                last_updated: last_updated as u64,
            };
            Ok(Some(tile))
        } else {
            Ok(None)
        }
    }

    pub async fn update_tile(&self, tile: &crate::game_engine::tile::Tile) -> Result<()> {
        tracing::info!("update_tile: tile.id (u32): {}", tile.id);
        tracing::info!("update_tile: tile.owner: {:?}", tile.owner);
        tracing::info!("update_tile: tile.tile_type: {:?} as string: {}", tile.tile_type, tile.tile_type.to_string());
        let _query = sqlx::query(
            r#"
            UPDATE tiles
            SET owner_id = $2, level = $3, tile_type = $4, last_updated = $5
            WHERE id = $1
            "#
        )
        .bind(tile.id as i32)
        .bind(tile.owner.clone())
        .bind(tile.level as i32)
        .bind(tile.tile_type.to_string())
        .bind(tile.last_updated as i64)
        .execute(&self.pool)
        .await?;

        tracing::info!("Updated tile {} in database", tile.id);
        Ok(())
    }

    pub async fn get_tiles_by_owner(&self, owner_id: &str) -> Result<Vec<crate::game_engine::tile::Tile>> {
        let _query = sqlx::query(
            r#"
            SELECT id, position_x, position_y, owner_id, level, tile_type, last_updated
            FROM tiles
            WHERE owner_id = $1
            "#
        )
        .bind(owner_id);
        
        let rows = _query.fetch_all(&self.pool).await?;

        let mut tiles = Vec::new();
        for row in rows {
            // Log type conversions for validation
            tracing::info!("=== get_tiles_by_owner type validation ===");
            let id: i32 = row.get::<i32, _>("id");
            let position_x: i32 = row.get::<i32, _>("position_x");
            let position_y: i32 = row.get::<i32, _>("position_y");
            let owner_id: String = row.get::<String, _>("owner_id");
            let level: i32 = row.get::<i32, _>("level");
            let tile_type: String = row.get::<String, _>("tile_type");
            let last_updated: i64 = row.get::<i64, _>("last_updated");
            
            tracing::info!("DB row values:");
            tracing::info!("  id: {} (i32) -> converting to u32: {}", id, id as u32);
            tracing::info!("  position_x: {} (i32)", position_x);
            tracing::info!("  position_y: {} (i32)", position_y);
            tracing::info!("  owner_id: {} (String) -> should be owner field", owner_id);
            tracing::info!("  level: {} (i32) -> converting to u8: {}", level, level as u8);
            tracing::info!("  tile_type: {} (String) -> needs parsing to TileType enum", tile_type);
            tracing::info!("  last_updated: {} (i64) -> converting to u64: {}", last_updated, last_updated as u64);
            tracing::info!("=== End get_tiles_by_owner type validation ===");
            
            let tile = crate::game_engine::tile::Tile {
                id: id as u32,
                position: (position_x, position_y),
                owner: Some(owner_id), // Convert owner_id to owner field
                level: level as u8,
                tile_type: crate::game_engine::tile::TileType::Empty, // placeholder, will fix after validation
                resources: Vec::new(), // placeholder
                last_updated: last_updated as u64,
            };
            tiles.push(tile);
        }
        
        tracing::info!("Loaded {} tiles for owner {}", tiles.len(), owner_id);
        Ok(tiles)
    }

    // PvP Match operations
    pub async fn create_pvp_match(&self, match_record: &crate::game_engine::pvp::PvpMatch) -> Result<()> {
        tracing::info!("create_pvp_match: id: {}", match_record.id);
        tracing::info!("create_pvp_match: player1_id: {}", match_record.player1_id);
        tracing::info!("create_pvp_match: player2_id: {}", match_record.player2_id);
        tracing::info!("create_pvp_match: status: {:?} as string: {}", match_record.status, format!("{:?}", match_record.status));
        tracing::info!("create_pvp_match: winner: {:?}", match_record.winner);
        tracing::info!("create_pvp_match: created_at: {}", match_record.created_at);
        tracing::info!("create_pvp_match: ended_at: {:?}", match_record.ended_at);
        let _query = sqlx::query(
            r#"
            INSERT INTO pvp_matches (id, player1_id, player2_id, status, winner, created_at, ended_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            "#
        )
        .bind(&match_record.id)
        .bind(&match_record.player1_id)
        .bind(&match_record.player2_id)
        .bind(format!("{:?}", match_record.status))
        .bind(&match_record.winner)
        .bind(match_record.created_at as i64)
        .bind(match_record.ended_at.map(|t| t as i64))
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    pub async fn update_pvp_match(&self, match_record: &crate::game_engine::pvp::PvpMatch) -> Result<()> {
        let _query = sqlx::query(
            r#"
            UPDATE pvp_matches
            SET status = $2, winner = $3, ended_at = $4
            WHERE id = $1
            "#
        )
        .bind(&match_record.id)
        .bind(format!("{:?}", match_record.status))
        .bind(&match_record.winner)
        .bind(match_record.ended_at.map(|t| t as i64))
        .execute(&self.pool)
        .await?;

        tracing::info!("Updated PvP match {} in database", match_record.id);
        Ok(())
    }

    pub async fn get_pvp_matches_by_player(&self, player_id: &str) -> Result<Vec<crate::game_engine::pvp::PvpMatch>> {
        let _query = sqlx::query(
            r#"
            SELECT id, player1_id, player2_id, status, winner, created_at, ended_at
            FROM pvp_matches
            WHERE player1_id = $1 OR player2_id = $1
            "#
        )
        .bind(player_id);
        
        let rows = _query.fetch_all(&self.pool).await?;

        let mut matches = Vec::new();
        for row in rows {
            // For PvPMatch, parse status_str outside the struct initializer
            let status_str: String = row.get::<String, _>("status");
            let status = match crate::game_engine::pvp::PvpStatus::from_str(&status_str) {
                Ok(s) => s,
                Err(_) => crate::game_engine::pvp::PvpStatus::Pending,
            };
            let match_record = crate::game_engine::pvp::PvpMatch {
                id: row.get::<String, _>("id"),
                player1_id: row.get::<String, _>("player1_id"),
                player2_id: row.get::<String, _>("player2_id"),
                status,
                winner: row.get::<Option<String>, _>("winner"),
                created_at: row.get::<i64, _>("created_at") as u64,
                ended_at: row.get::<Option<i64>, _>("ended_at").map(|t| t as u64),
                rounds: Vec::new(),
            };
            matches.push(match_record);
        }
        
        tracing::info!("Loaded {} PvP matches for player {}", matches.len(), player_id);
        Ok(matches)
    }

    // Streak operations
    pub async fn create_streak(&self, streak: &crate::game_engine::streak::Streak) -> Result<()> {
        tracing::info!("create_streak: streak.player_id: {}", streak.player_id);
        // Log StreakType to string conversion for validation
        tracing::info!("=== StreakType to string conversion validation ===");
        tracing::info!("streak.streak_type: {:?}", streak.streak_type);
        let streak_type_str = match streak.streak_type {
            crate::game_engine::streak::StreakType::Daily => "Daily".to_string(),
            crate::game_engine::streak::StreakType::Weekly => "Weekly".to_string(),
            crate::game_engine::streak::StreakType::Monthly => "Monthly".to_string(),
            crate::game_engine::streak::StreakType::ConsecutiveWins => "ConsecutiveWins".to_string(),
            crate::game_engine::streak::StreakType::ConsecutiveMoves => "ConsecutiveMoves".to_string(),
            crate::game_engine::streak::StreakType::ResourceHarvest => "ResourceHarvest".to_string(),
        };
        tracing::info!("Converted StreakType to string: '{}'", streak_type_str);
        tracing::info!("=== End StreakType to string conversion validation ===");
        tracing::info!("create_streak: streak.streak_type: {:?} as string: {}", streak.streak_type, streak_type_str);
        tracing::info!("create_streak: streak.current_streak: {}", streak.current_streak);
        tracing::info!("create_streak: streak.longest_streak: {}", streak.longest_streak);
        tracing::info!("create_streak: streak.last_activity: {}", streak.last_activity);
        tracing::info!("create_streak: streak.streak_start: {}", streak.streak_start);
        tracing::info!("create_streak: streak.multiplier: {}", streak.multiplier);
        let _query = sqlx::query(
            r#"
            INSERT INTO streaks (player_id, streak_type, current_streak, longest_streak, last_activity, streak_start, multiplier)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            ON CONFLICT (player_id, streak_type) DO UPDATE SET
                current_streak = $3, longest_streak = $4, last_activity = $5, multiplier = $7
            "#
        )
        .bind(&streak.player_id)
        .bind(streak_type_str)
        .bind(streak.current_streak as i32)
        .bind(streak.longest_streak as i32)
        .bind(streak.last_activity as i64)
        .bind(streak.streak_start as i64)
        .bind(streak.multiplier)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    pub async fn get_streak(&self, player_id: &str, streak_type: &str) -> Result<Option<crate::game_engine::streak::Streak>> {
        let _query = sqlx::query(
            r#"
            SELECT player_id, streak_type, current_streak, longest_streak, last_activity, streak_start, multiplier
            FROM streaks
            WHERE player_id = $1 AND streak_type = $2
            "#
        )
        .bind(player_id)
        .bind(streak_type);
        
        let row = _query.fetch_optional(&self.pool).await?;

        if let Some(row) = row {
            // Log Streak struct initialization for validation
            tracing::info!("=== get_streak struct initialization validation ===");
            let player_id: String = row.get::<String, _>("player_id");
            let streak_type_str: String = row.get::<String, _>("streak_type");
            let current_streak: i32 = row.get::<i32, _>("current_streak");
            let longest_streak: i32 = row.get::<i32, _>("longest_streak");
            let last_activity: i64 = row.get::<i64, _>("last_activity");
            let streak_start: i64 = row.get::<i64, _>("streak_start");
            let multiplier: f64 = row.get::<f64, _>("multiplier");
            
            tracing::info!("DB row values for Streak:");
            tracing::info!("  player_id: {} (String)", player_id);
            tracing::info!("  streak_type: {} (String) -> needs parsing to StreakType enum", streak_type_str);
            tracing::info!("  current_streak: {} (i32) -> converting to u32: {}", current_streak, current_streak as u32);
            tracing::info!("  longest_streak: {} (i32) -> converting to u32: {}", longest_streak, longest_streak as u32);
            tracing::info!("  last_activity: {} (i64) -> converting to u64: {}", last_activity, last_activity as u64);
            tracing::info!("  streak_start: {} (i64) -> converting to u64: {}", streak_start, streak_start as u64);
            tracing::info!("  multiplier: {} (f64) -> converting to f32: {}", multiplier, multiplier as f32);
            tracing::info!("  rewards_claimed: missing field in DB, will need to add",);
            tracing::info!("=== End get_streak struct initialization validation ===");
            
            let streak = crate::game_engine::streak::Streak {
                player_id,
                streak_type: crate::game_engine::streak::StreakType::Daily, // placeholder, will fix after validation
                current_streak: current_streak as u32,
                longest_streak: longest_streak as u32,
                last_activity: last_activity as u64,
                streak_start: streak_start as u64,
                multiplier: multiplier as f32,
                rewards_claimed: Vec::new(), // missing field, adding default
            };
            Ok(Some(streak))
        } else {
            Ok(None)
        }
    }

    pub async fn get_all_streaks(&self, player_id: &str) -> Result<Vec<crate::game_engine::streak::Streak>> {
        let _query = sqlx::query(
            r#"
            SELECT player_id, streak_type, current_streak, longest_streak, last_activity, streak_start, multiplier
            FROM streaks
            WHERE player_id = $1
            "#
        )
        .bind(player_id);
        
        let rows = _query.fetch_all(&self.pool).await?;

        let mut streaks = Vec::new();
        for row in rows {
            // Log Streak struct initialization for validation
            tracing::info!("=== get_all_streaks struct initialization validation ===");
            let player_id: String = row.get::<String, _>("player_id");
            let streak_type_str: String = row.get::<String, _>("streak_type");
            let current_streak: i32 = row.get::<i32, _>("current_streak");
            let longest_streak: i32 = row.get::<i32, _>("longest_streak");
            let last_activity: i64 = row.get::<i64, _>("last_activity");
            let streak_start: i64 = row.get::<i64, _>("streak_start");
            let multiplier: f64 = row.get::<f64, _>("multiplier");
            
            tracing::info!("DB row values for Streak:");
            tracing::info!("  player_id: {} (String)", player_id);
            tracing::info!("  streak_type: {} (String) -> needs parsing to StreakType enum", streak_type_str);
            tracing::info!("  current_streak: {} (i32) -> converting to u32: {}", current_streak, current_streak as u32);
            tracing::info!("  longest_streak: {} (i32) -> converting to u32: {}", longest_streak, longest_streak as u32);
            tracing::info!("  last_activity: {} (i64) -> converting to u64: {}", last_activity, last_activity as u64);
            tracing::info!("  streak_start: {} (i64) -> converting to u64: {}", streak_start, streak_start as u64);
            tracing::info!("  multiplier: {} (f64) -> converting to f32: {}", multiplier, multiplier as f32);
            tracing::info!("  rewards_claimed: missing field in DB, will need to add",);
            tracing::info!("=== End get_all_streaks struct initialization validation ===");
            
            let streak = crate::game_engine::streak::Streak {
                player_id,
                streak_type: crate::game_engine::streak::StreakType::Daily, // placeholder, will fix after validation
                current_streak: current_streak as u32,
                longest_streak: longest_streak as u32,
                last_activity: last_activity as u64,
                streak_start: streak_start as u64,
                multiplier: multiplier as f32,
                rewards_claimed: Vec::new(), // missing field, adding default
            };
            streaks.push(streak);
        }
        
        Ok(streaks)
    }

    // Migration function
    pub async fn run_migrations(&self) -> Result<()> {
        tracing::info!("=== STARTING DATABASE MIGRATIONS ===");
        
        // Log current working directory and file system state
        if let Ok(current_dir) = std::env::current_dir() {
            tracing::info!("Current working directory: {:?}", current_dir);
        }
        
        // Check if migration directory exists at different possible paths
        let possible_paths = vec![
            "../../scripts/migrations",
            "scripts/migrations", 
            "./scripts/migrations",
            "/app/scripts/migrations",
            "/app/../../scripts/migrations"
        ];
        
        tracing::info!("=== VALIDATING MIGRATION PATHS ===");
        for path in &possible_paths {
            let path_buf = std::path::PathBuf::from(path);
            tracing::info!("Checking migration path: {:?} -> exists: {}", path, path_buf.exists());
            if path_buf.exists() {
                tracing::info!("  Path is directory: {}", path_buf.is_dir());
                if let Ok(entries) = std::fs::read_dir(&path_buf) {
                    let files: Vec<_> = entries.filter_map(|e| e.ok()).collect();
                    tracing::info!("  Found {} files in directory", files.len());
                    for entry in files {
                        tracing::info!("Found migration file: {:?}", entry.file_name());
                    }
                }
            }
        }
        
        // Try to list contents of current directory
        tracing::info!("=== CONTENTS OF CURRENT DIRECTORY ===");
        if let Ok(entries) = std::fs::read_dir(".") {
            for entry in entries {
                if let Ok(entry) = entry {
                    tracing::info!("  {:?} (dir: {})", entry.file_name(), entry.file_type().map(|ft| ft.is_dir()).unwrap_or(false));
                }
            }
        }
        
        // Try to list contents of parent directories
        tracing::info!("=== CONTENTS OF PARENT DIRECTORIES ===");
        for i in 1..=3 {
            let parent_path = format!("{}", "../".repeat(i));
            if let Ok(entries) = std::fs::read_dir(&parent_path) {
                tracing::info!("Contents of {} directory:", parent_path);
                for entry in entries {
                    if let Ok(entry) = entry {
                        tracing::info!("  {:?} (dir: {})", entry.file_name(), entry.file_type().map(|ft| ft.is_dir()).unwrap_or(false));
                    }
                }
            }
        }
        
        // Validate our assumption about the correct path
        tracing::info!("=== VALIDATING ASSUMPTIONS ===");
        let assumed_correct_path = "scripts/migrations";
        let path_buf = std::path::PathBuf::from(assumed_correct_path);
        if path_buf.exists() && path_buf.is_dir() {
            tracing::info!("✅ VALIDATION SUCCESS: Found migrations at assumed path: {}", assumed_correct_path);
            if let Ok(entries) = std::fs::read_dir(&path_buf) {
                let files: Vec<_> = entries.filter_map(|e| e.ok()).collect();
                tracing::info!("✅ Found {} migration files at correct path", files.len());
                for entry in files {
                    tracing::info!("  ✅ Migration: {:?}", entry.file_name());
                }
            }
        } else {
            tracing::error!("❌ VALIDATION FAILED: Expected migrations at {} but not found", assumed_correct_path);
        }
        
        // Check the current path that's failing
        let current_failing_path = "../../scripts/migrations";
        let failing_path_buf = std::path::PathBuf::from(current_failing_path);
        tracing::info!("=== ANALYZING FAILING PATH ===");
        tracing::info!("Failing path: {} -> exists: {}", current_failing_path, failing_path_buf.exists());
        if failing_path_buf.exists() {
            tracing::info!("  Path is directory: {}", failing_path_buf.is_dir());
        } else {
            tracing::info!("  Path does not exist - this is the root cause of the error");
        }
        
        tracing::info!("=== ATTEMPTING MIGRATION WITH CURRENT PATH ===");
        sqlx::migrate!("scripts/migrations").run(&self.pool).await?;
        tracing::info!("Database migrations completed successfully");
        tracing::info!("=== END DATABASE MIGRATIONS ===");
        Ok(())
    }

    pub async fn save_pvp_result(&self, match_data: &PvpMatch) -> Result<()> {
        let rounds_json = serde_json::to_value(&match_data.rounds)?;
        let _query = sqlx::query(
            r#"
            INSERT INTO pvp_sessions (id, player1_id, player2_id, winner_id, status, created_at, ended_at, rounds)
            VALUES ($1, $2, $3, $4, $5, to_timestamp($6), to_timestamp($7), $8)
            ON CONFLICT (id) DO UPDATE SET
                winner_id = EXCLUDED.winner_id,
                status = EXCLUDED.status,
                ended_at = EXCLUDED.ended_at,
                rounds = EXCLUDED.rounds
            "#
        )
        .bind(&match_data.id)
        .bind(&match_data.player1_id)
        .bind(&match_data.player2_id)
        .bind(&match_data.winner)
        .bind("Completed")
        .bind(match_data.created_at as i64)
        .bind(match_data.ended_at.map(|t| t as i64))
        .bind(&rounds_json)
        .execute(&self.pool)
        .await?;
        
        tracing::info!("Saved PvP result for match {} to database", match_data.id);
        Ok(())
    }

    pub async fn save_pvp_result_tx(&self, match_data: &PvpMatch, tx: &mut Transaction<'_, Postgres>) -> Result<()> {
        let rounds_json = serde_json::to_value(&match_data.rounds)?;
        let _query = sqlx::query(
            r#"
            INSERT INTO pvp_sessions (id, player1_id, player2_id, winner_id, status, created_at, ended_at, rounds)
            VALUES ($1, $2, $3, $4, $5, to_timestamp($6), to_timestamp($7), $8)
            ON CONFLICT (id) DO UPDATE SET
                winner_id = EXCLUDED.winner_id,
                status = EXCLUDED.status,
                ended_at = EXCLUDED.ended_at,
                rounds = EXCLUDED.rounds
            "#
        )
        .bind(&match_data.id)
        .bind(&match_data.player1_id)
        .bind(&match_data.player2_id)
        .bind(&match_data.winner)
        .bind("Completed")
        .bind(match_data.created_at as i64)
        .bind(match_data.ended_at.map(|t| t as i64))
        .bind(&rounds_json)
        .execute(&mut **tx)
        .await?;
        
        tracing::info!("Saved PvP result for match {} to database (transaction)", match_data.id);
        Ok(())
    }

    pub async fn begin_transaction(&self) -> Result<sqlx::Transaction<'_, sqlx::Postgres>> {
        tracing::info!("Starting database transaction");
        let tx = self.pool.begin().await?;
        tracing::info!("Database transaction started successfully");
        Ok(tx)
    }

    pub async fn save_player(&self, player: &crate::game_engine::player::Player) -> Result<()> {
        tracing::info!("=== save_player called ===");
        tracing::info!("Player ID: {}", player.id);
        tracing::info!("Player position: {:?}", player.position);
        tracing::info!("Player health: {} (u32)", player.health);
        tracing::info!("Player score: {} (u32)", player.score);
        tracing::info!("Player level: {} (u8)", player.level);
        tracing::info!("Player experience: {} (u32)", player.experience);
        tracing::info!("Player last_move: {} (u64)", player.last_move);
        
        // Log type conversions
        tracing::info!("Type conversions:");
        tracing::info!("  health: {} -> {}", player.health, player.health as i32);
        tracing::info!("  score: {} -> {}", player.score, player.score as i32);
        tracing::info!("  level: {} -> {}", player.level, player.level as i16);
        tracing::info!("  experience: {} -> {}", player.experience, player.experience as i32);
        tracing::info!("  last_move: {} -> {}", player.last_move, player.last_move as i64);
        
        let _query = sqlx::query(
            r#"
            INSERT INTO players (id, position_x, position_y, health, score, level, experience, last_move, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            ON CONFLICT (id) DO UPDATE SET
                position_x = EXCLUDED.position_x,
                position_y = EXCLUDED.position_y,
                health = EXCLUDED.health,
                score = EXCLUDED.score,
                level = EXCLUDED.level,
                experience = EXCLUDED.experience,
                last_move = EXCLUDED.last_move,
                updated_at = EXCLUDED.updated_at
            "#
        )
        .bind(&player.id)
        .bind(player.position.0)
        .bind(player.position.1)
        .bind(player.health as i32)  // Convert u32 to i32
        .bind(player.score as i32)   // Convert u32 to i32
        .bind(player.level as i16)   // Convert u8 to i16
        .bind(player.experience as i32) // Convert u32 to i32
        .bind(player.last_move as i64)  // Convert u64 to i64
        .bind(player.last_move as i64) // Use last_move as created_at
        .bind(player.last_move as i64) // Use last_move as updated_at
        .execute(&self.pool)
        .await?;
        
        tracing::info!("Successfully saved player {} to database", player.id);
        tracing::info!("=== End save_player ===");
        Ok(())
    }

    pub async fn load_player(&self, player_id: &str) -> Result<Option<crate::game_engine::player::Player>> {
        let _query = sqlx::query(
            r#"
            SELECT id, position_x, position_y, health, score, level, experience, last_move, created_at, updated_at
            FROM players
            WHERE id = $1
            "#
        )
        .bind(player_id);
        
        let row = _query.fetch_optional(&self.pool).await?;
        
        if let Some(row) = row {
            let player = crate::game_engine::player::Player {
                id: row.get::<String, _>("id"),
                position: (row.get::<i32, _>("position_x"), row.get::<i32, _>("position_y")),
                health: row.get::<i32, _>("health") as u32,  // Convert i32 back to u32
                score: row.get::<i32, _>("score") as u32,    // Convert i32 back to u32
                level: row.get::<i16, _>("level") as u8,     // Convert i16 back to u8
                experience: row.get::<i32, _>("experience") as u32, // Convert i32 back to u32
                last_move: row.get::<i64, _>("last_move") as u64,   // Convert i64 back to u64
                last_trade_at: row.try_get::<Option<i64>, _>("last_trade_at").ok().flatten().map(|t| t as u64),
                inventory: Vec::new(), // TODO: Load inventory from separate table
            };
            Ok(Some(player))
        } else {
            Ok(None)
        }
    }

    pub async fn save_tile(&self, tile: &crate::game_engine::tile::Tile) -> Result<()> {
        tracing::info!("save_tile: tile.id (u32): {}", tile.id);
        tracing::info!("save_tile: tile.owner: {:?}", tile.owner);
        tracing::info!("save_tile: tile.tile_type: {:?} as string: {}", tile.tile_type, tile.tile_type.to_string());
        let _query = sqlx::query(
            r#"
            INSERT INTO tiles (id, position_x, position_y, owner_id, level, tile_type, last_updated)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            ON CONFLICT (id) DO UPDATE SET
                owner_id = EXCLUDED.owner_id,
                level = EXCLUDED.level,
                tile_type = EXCLUDED.tile_type,
                last_updated = EXCLUDED.last_updated
            "#
        )
        .bind(tile.id as i32)
        .bind(tile.position.0)
        .bind(tile.position.1)
        .bind(tile.owner.clone())
        .bind(tile.level as i32)
        .bind(tile.tile_type.to_string())
        .bind(tile.last_updated as i64)
        .execute(&self.pool)
        .await?;
        
        tracing::info!("Saved tile {} to database", tile.id);
        Ok(())
    }

    pub async fn load_tile(&self, tile_id: i32) -> Result<Option<crate::game_engine::tile::Tile>> {
        tracing::info!("load_tile: tile_id (i32): {}", tile_id);
        let _query = sqlx::query(
            r#"
            SELECT id, position_x, position_y, owner_id, level, tile_type, last_updated
            FROM tiles
            WHERE id = $1
            "#
        )
        .bind(tile_id);
        
        let row = _query.fetch_optional(&self.pool).await?;
        
        if let Some(row) = row {
            // Log Tile struct initialization for validation
            tracing::info!("=== load_tile struct initialization validation ===");
            let id: i32 = row.get::<i32, _>("id");
            let position_x: i32 = row.get::<i32, _>("position_x");
            let position_y: i32 = row.get::<i32, _>("position_y");
            let owner_id: String = row.get::<String, _>("owner_id");
            let level: i32 = row.get::<i32, _>("level");
            let tile_type: String = row.get::<String, _>("tile_type");
            let last_updated: i64 = row.get::<i64, _>("last_updated");
            
            tracing::info!("DB row values for Tile:");
            tracing::info!("  id: {} (i32) -> converting to u32: {}", id, id as u32);
            tracing::info!("  position_x: {} (i32)", position_x);
            tracing::info!("  position_y: {} (i32)", position_y);
            tracing::info!("  owner_id: {} (String) -> should be owner field", owner_id);
            tracing::info!("  level: {} (i32) -> converting to u8: {}", level, level as u8);
            tracing::info!("  tile_type: {} (String) -> needs parsing to TileType enum", tile_type);
            tracing::info!("  last_updated: {} (i64) -> converting to u64: {}", last_updated, last_updated as u64);
            tracing::info!("  resources: missing field in DB, will need to add",);
            tracing::info!("=== End load_tile struct initialization validation ===");
            
            let tile = crate::game_engine::tile::Tile {
                id: id as u32,
                position: (position_x, position_y),
                owner: Some(owner_id), // Convert owner_id to owner field
                level: level as u8,
                tile_type: crate::game_engine::tile::TileType::Empty, // placeholder, will fix after validation
                resources: Vec::new(), // placeholder
                last_updated: last_updated as u64,
            };
            Ok(Some(tile))
        } else {
            Ok(None)
        }
    }

    pub async fn save_pvp_match(&self, match_record: &crate::game_engine::pvp::PvpMatch) -> Result<()> {
        let _query = sqlx::query(
            r#"
            INSERT INTO pvp_matches (id, player1_id, player2_id, status, winner, created_at, ended_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            ON CONFLICT (id) DO UPDATE SET
                status = EXCLUDED.status,
                winner = EXCLUDED.winner,
                ended_at = EXCLUDED.ended_at
            "#
        )
        .bind(&match_record.id)
        .bind(&match_record.player1_id)
        .bind(&match_record.player2_id)
        .bind(format!("{:?}", match_record.status))
        .bind(&match_record.winner)
        .bind(match_record.created_at as i64)
        .bind(match_record.ended_at.map(|t| t as i64))
        .execute(&self.pool)
        .await?;
        
        tracing::info!("Saved PvP match {} to database", match_record.id);
        Ok(())
    }

    pub async fn save_streak(&self, streak: &crate::game_engine::streak::Streak) -> Result<()> {
        // Log StreakType binding for validation
        tracing::info!("=== save_streak StreakType binding validation ===");
        tracing::info!("streak.streak_type: {:?}", streak.streak_type);
        let streak_type_str = match streak.streak_type {
            crate::game_engine::streak::StreakType::Daily => "Daily".to_string(),
            crate::game_engine::streak::StreakType::Weekly => "Weekly".to_string(),
            crate::game_engine::streak::StreakType::Monthly => "Monthly".to_string(),
            crate::game_engine::streak::StreakType::ConsecutiveWins => "ConsecutiveWins".to_string(),
            crate::game_engine::streak::StreakType::ConsecutiveMoves => "ConsecutiveMoves".to_string(),
            crate::game_engine::streak::StreakType::ResourceHarvest => "ResourceHarvest".to_string(),
        };
        tracing::info!("Converted StreakType to string for binding: '{}'", streak_type_str);
        tracing::info!("=== End save_streak StreakType binding validation ===");
        let _query = sqlx::query(
            r#"
            INSERT INTO streaks (player_id, streak_type, current_streak, longest_streak, last_activity, streak_start, multiplier)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            ON CONFLICT (player_id, streak_type) DO UPDATE SET
                current_streak = EXCLUDED.current_streak,
                longest_streak = EXCLUDED.longest_streak,
                last_activity = EXCLUDED.last_activity,
                multiplier = EXCLUDED.multiplier
            "#
        )
        .bind(&streak.player_id)
        .bind(streak_type_str)
        .bind(streak.current_streak as i32)  // Convert u32 to i32
        .bind(streak.longest_streak as i32)  // Convert u32 to i32
        .bind(streak.last_activity as i64)   // Convert u64 to i64
        .bind(streak.streak_start as i64)    // Convert u64 to i64
        .bind(streak.multiplier as f64)      // Convert f32 to f64
        .execute(&self.pool)
        .await?;
        
        tracing::info!("Saved streak for player {} to database", streak.player_id);
        Ok(())
    }

    pub async fn load_streak(&self, player_id: &str, streak_type: &str) -> Result<Option<crate::game_engine::streak::Streak>> {
        let _query = sqlx::query(
            r#"
            SELECT player_id, streak_type, current_streak, longest_streak, last_activity, streak_start, multiplier
            FROM streaks
            WHERE player_id = $1 AND streak_type = $2
            "#
        )
        .bind(player_id)
        .bind(streak_type);
        
        let row = _query.fetch_optional(&self.pool).await?;
        
        if let Some(row) = row {
            let streak = crate::game_engine::streak::Streak {
                player_id: row.get::<String, _>("player_id"),
                streak_type: crate::game_engine::streak::StreakType::Daily, // Default to Daily, TODO: parse from string
                current_streak: row.get::<i32, _>("current_streak") as u32,  // Convert i32 back to u32
                longest_streak: row.get::<i32, _>("longest_streak") as u32,  // Convert i32 back to u32
                last_activity: row.get::<i64, _>("last_activity") as u64,    // Convert i64 back to u64
                streak_start: row.get::<i64, _>("streak_start") as u64,      // Convert i64 back to u64
                rewards_claimed: Vec::new(), // TODO: Load from JSON column
                multiplier: row.get::<f64, _>("multiplier") as f32,          // Convert f64 back to f32
            };
            Ok(Some(streak))
        } else {
            Ok(None)
        }
    }

    pub async fn get_streaks_by_player(&self, player_id: &str) -> Result<Vec<crate::game_engine::streak::Streak>> {
        let _query = sqlx::query(
            r#"
            SELECT player_id, streak_type, current_streak, longest_streak, last_activity, streak_start, multiplier
            FROM streaks
            WHERE player_id = $1
            "#
        )
        .bind(player_id);
        
        let rows = _query.fetch_all(&self.pool).await?;
        
        let mut streaks = Vec::new();
        for row in rows {
            let streak = crate::game_engine::streak::Streak {
                player_id: row.get::<String, _>("player_id"),
                streak_type: crate::game_engine::streak::StreakType::Daily, // Default to Daily, TODO: parse from string
                current_streak: row.get::<i32, _>("current_streak") as u32,  // Convert i32 back to u32
                longest_streak: row.get::<i32, _>("longest_streak") as u32,  // Convert i32 back to u32
                last_activity: row.get::<i64, _>("last_activity") as u64,    // Convert i64 back to u64
                streak_start: row.get::<i64, _>("streak_start") as u64,      // Convert i64 back to u64
                rewards_claimed: Vec::new(), // TODO: Load from JSON column
                multiplier: row.get::<f64, _>("multiplier") as f32,          // Convert f64 back to f32
            };
            streaks.push(streak);
        }
        
        tracing::info!("Loaded {} streaks for player {}", streaks.len(), player_id);
        Ok(streaks)
    }

    pub async fn get_all_active_players(&self) -> Result<Vec<crate::game_engine::player::Player>> {
        let rows = sqlx::query(
            r#"
            SELECT id, position_x, position_y, health, score, level, experience, last_move, last_trade_at
            FROM players
            ORDER BY id
            "#
        )
        .fetch_all(&self.pool)
        .await?;

        let mut players = Vec::new();
        for row in rows {
            let position_x: i32 = row.try_get("position_x")?;
            let position_y: i32 = row.try_get("position_y")?;
            let last_trade_at: Option<i64> = row.try_get("last_trade_at").ok();
            
            let player = crate::game_engine::player::Player {
                id: row.try_get("id")?,
                position: (position_x, position_y),
                health: row.try_get::<i32, _>("health")? as u32,
                score: row.try_get::<i32, _>("score")? as u32,
                level: row.try_get::<i32, _>("level")? as u8,
                experience: row.try_get::<i32, _>("experience")? as u32,
                last_move: row.try_get::<i64, _>("last_move")? as u64,
                last_trade_at: last_trade_at.map(|t| t as u64),
                inventory: Vec::new(), // TODO: Load inventory from separate table if needed
            };
            players.push(player);
        }

        Ok(players)
    }
} 