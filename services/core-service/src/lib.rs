// Re-export modules for testing
pub mod config;
pub mod health;
pub mod game_engine;
pub mod infra;
pub mod events;

// Re-export main types for testing
pub use game_engine::game_engine::{GameEngine, MoveData};
pub use game_engine::tile::TileService;
pub use game_engine::streak::StreakService;
pub use game_engine::pvp::PvPService;
pub use game_engine::rewards::RewardService;
pub use infra::starknet::StarknetClient;
pub use infra::kafka::KafkaEventDispatcher;
pub use infra::db::Database;
pub use config::Config;

// Proto definitions
pub mod core {
    tonic::include_proto!("streetcred.core.v1");
}

pub use core::{MovePlayerRequest, MovePlayerResponse};
pub use core::core_service_server::{CoreService as GrpcCoreService, CoreServiceServer};

// Service struct for testing
pub struct MyCoreService {
    pub game: std::sync::Arc<GameEngine>,
}

// Add logging to check SQLx configuration
fn check_sqlx_config() {
    // Check if sqlx-data.json exists
    let sqlx_data_path = std::path::Path::new("sqlx-data.json");
    println!("Checking for sqlx-data.json at: {:?}", sqlx_data_path);
    
    // Check current working directory
    if let Ok(current_dir) = std::env::current_dir() {
        println!("Current working directory: {:?}", current_dir);
    }
    
    // List files in current directory
    if let Ok(entries) = std::fs::read_dir(".") {
        for entry in entries {
            if let Ok(entry) = entry {
                if entry.file_name().to_string_lossy().contains("sqlx") {
                }
            }
        }
    }
    
    // Check for remaining sqlx::query! macros in source files
    let source_dirs = ["src", "tests"];
    for dir in &source_dirs {
        if let Ok(entries) = std::fs::read_dir(dir) {
            for entry in entries {
                if let Ok(entry) = entry {
                    let path = entry.path();
                    if path.extension().map_or(false, |ext| ext == "rs") {
                        if let Ok(content) = std::fs::read_to_string(&path) {
                            let macro_count = content.matches("sqlx::query!").count();
                            if macro_count > 0 {
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Check Player struct field types
    tracing::info!("=== Player struct type analysis ===");
    tracing::info!("Player struct fields:");
    tracing::info!("  - health: u32 (needs conversion to i32 for PostgreSQL)");
    tracing::info!("  - score: u32 (needs conversion to i32 for PostgreSQL)");
    tracing::info!("  - level: u8 (needs conversion to i16 for PostgreSQL)");
    tracing::info!("  - experience: u32 (needs conversion to i32 for PostgreSQL)");
    tracing::info!("  - last_move: u64 (needs conversion to i64 for PostgreSQL)");
}

// Call the check function when the library is loaded
#[ctor::ctor]
fn init() {
    check_sqlx_config();
} 