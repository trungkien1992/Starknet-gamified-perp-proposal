use serde::{Deserialize, Serialize};
use crate::game_engine::player::Player;
use anyhow::Result;
use crate::game_engine::game_engine::MoveData;
use async_trait::async_trait;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Tile {
    pub id: u32,
    pub position: (i32, i32),
    pub owner: Option<String>,
    pub level: u8,
    pub tile_type: TileType,
    pub resources: Vec<Resource>,
    pub last_updated: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TileType {
    Empty,
    Resource,
    Building,
    Obstacle,
    Portal,
    Battle,
}

impl std::fmt::Display for TileType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let s = match self {
            TileType::Empty => "Empty",
            TileType::Resource => "Resource",
            TileType::Building => "Building",
            TileType::Obstacle => "Obstacle",
            TileType::Portal => "Portal",
            TileType::Battle => "Battle",
        };
        write!(f, "{}", s)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Resource {
    pub resource_type: String,
    pub amount: u32,
    pub max_amount: u32,
    pub regeneration_rate: f32,
}

impl Tile {
    pub fn new(position: (i32, i32)) -> Self {
        Self {
            id: Self::position_to_id(position),
            position,
            owner: None,
            level: 1,
            tile_type: TileType::Empty,
            resources: Vec::new(),
            last_updated: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
        }
    }

    pub fn interact_with_player(&mut self, player: &mut Player) {
        match self.tile_type {
            TileType::Resource => self.handle_resource_interaction(player),
            TileType::Building => self.handle_building_interaction(player),
            TileType::Portal => self.handle_portal_interaction(player),
            TileType::Battle => self.handle_battle_interaction(player),
            _ => {}
        }

        self.last_updated = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs();
    }

    fn handle_resource_interaction(&mut self, player: &mut Player) {
        for resource in &mut self.resources {
            if resource.amount > 0 {
                let harvest_amount = std::cmp::min(resource.amount, 10);
                resource.amount -= harvest_amount;
                
                // Add resource to player inventory
                let item_name = format!("{}_resource", resource.resource_type);
                player.add_to_inventory(item_name);
                
                // Add experience for harvesting
                player.add_experience(harvest_amount as u32);
                player.add_score((harvest_amount as u32).into());
            }
        }
    }

    fn handle_building_interaction(&mut self, player: &mut Player) {
        // Check if player owns this tile
        if let Some(owner) = &self.owner {
            if owner == &player.id {
                // Player can upgrade their building
                if player.score >= self.level as u32 * 100 {
                    self.level += 1;
                    player.add_score((self.level.saturating_sub(1) * 100).into());
                    player.add_experience(50);
                }
            } else {
                // Player can attack enemy building
                if player.health > 20 {
                    player.take_damage(10);
                    self.level = self.level.saturating_sub(1);
                    player.add_experience(20);
                }
            }
        }
    }

    fn handle_portal_interaction(&mut self, player: &mut Player) {
        // Teleport player to a random location
        use rand::Rng;
        let mut rng = rand::thread_rng();
        let new_x = rng.gen_range(-100..100);
        let new_y = rng.gen_range(-100..100);
        player.position = (new_x, new_y);
        player.add_experience(30);
    }

    fn handle_battle_interaction(&mut self, player: &mut Player) {
        // Simulate a battle encounter
        use rand::Rng;
        let mut rng = rand::thread_rng();
        let enemy_strength = rng.gen_range(10..50);
        
        if player.health > enemy_strength {
            player.take_damage(enemy_strength);
            player.add_experience(enemy_strength as u32);
            player.add_score((enemy_strength as u32).into());
            
            // Convert battle tile to resource tile
            self.tile_type = TileType::Resource;
            self.resources.push(Resource {
                resource_type: "battle_reward".to_string(),
                amount: enemy_strength,
                max_amount: enemy_strength,
                regeneration_rate: 0.0,
            });
        } else {
            player.take_damage(player.health);
        }
    }

    pub fn claim(&mut self, player_id: String) -> bool {
        if self.owner.is_none() {
            self.owner = Some(player_id);
            true
        } else {
            false
        }
    }

    pub fn upgrade(&mut self) -> bool {
        if self.level < 10 {
            self.level += 1;
            true
        } else {
            false
        }
    }

    pub fn add_resource(&mut self, resource_type: String, amount: u32, max_amount: u32) {
        self.resources.push(Resource {
            resource_type,
            amount,
            max_amount,
            regeneration_rate: 1.0,
        });
    }

    pub fn regenerate_resources(&mut self) {
        let current_time = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs();
        
        let time_diff = current_time - self.last_updated;
        
        for resource in &mut self.resources {
            let regeneration = (resource.regeneration_rate * time_diff as f32) as u32;
            resource.amount = std::cmp::min(
                resource.amount + regeneration,
                resource.max_amount
            );
        }
    }

    fn position_to_id(position: (i32, i32)) -> u32 {
        ((position.0 as u32) << 16) | (position.1 as u32 & 0xFFFF)
    }

    pub fn is_owned_by(&self, player_id: &str) -> bool {
        self.owner.as_ref().map_or(false, |owner| owner == player_id)
    }

    pub fn get_total_resources(&self) -> u32 {
        self.resources.iter().map(|r| r.amount).sum()
    }
}

#[async_trait]
pub trait TileServiceTrait: Send + Sync {
    async fn validate_tile_move(&self, player_id: &str, move_data: &MoveData) -> Result<bool>;
    async fn update_player_position(&self, player_id: &str, move_data: &MoveData) -> Result<()>;
}

#[derive(Clone)]
pub struct TileService;

impl TileService {
    pub fn new() -> Self {
        Self
    }
}

#[async_trait]
impl TileServiceTrait for TileService {
    async fn validate_tile_move(&self, player_id: &str, move_data: &MoveData) -> Result<bool> {
        if player_id.is_empty() {
            return Ok(false);
        }
        
        let x = move_data.target_x;
        let y = move_data.target_y;
        
        // Basic boundary validation
        if x < 0 || y < 0 || x > 1000 || y > 1000 {
            return Ok(false);
        }
        
        // TODO: Add more validation like checking if player owns adjacent tiles
        // or if the move is within allowed distance
        Ok(true)
    }
    async fn update_player_position(&self, _player_id: &str, _move_data: &MoveData) -> Result<()> {
        Ok(())
    }
} 