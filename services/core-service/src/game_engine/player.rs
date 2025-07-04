use serde::{Deserialize, Serialize};
use anyhow::Result;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Player {
    pub id: String,
    pub position: (i32, i32),
    pub health: u32,
    pub score: u32,
    pub level: u8,
    pub experience: u32,
    pub last_move: u64,
    pub last_trade_at: Option<u64>,
    pub inventory: Vec<String>,
}

impl Player {
    pub fn new(id: String) -> Self {
        Self {
            id,
            position: (0, 0),
            health: 100,
            score: 0,
            level: 1,
            experience: 0,
            last_move: 0,
            last_trade_at: None,
            inventory: Vec::new(),
        }
    }

    pub fn move_in_direction(&mut self, direction: &str) -> Result<(i32, i32)> {
        let new_position = match direction {
            "up" => (self.position.0, self.position.1 + 1),
            "down" => (self.position.0, self.position.1 - 1),
            "left" => (self.position.0 - 1, self.position.1),
            "right" => (self.position.0 + 1, self.position.1),
            _ => return Err(anyhow::anyhow!("Invalid direction: {}", direction)),
        };

        self.position = new_position;
        self.last_move = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs();

        Ok(new_position)
    }

    pub fn add_experience(&mut self, amount: u32) {
        self.experience += amount;
        
        // Check for level up
        let required_exp = self.level as u32 * 100;
        if self.experience >= required_exp {
            self.level_up();
        }
    }

    pub fn level_up(&mut self) {
        self.level += 1;
        self.health = 100 + (self.level as u32 * 10);
        self.experience = 0;
    }

    pub fn take_damage(&mut self, damage: u32) {
        if damage >= self.health {
            self.health = 0;
        } else {
            self.health -= damage;
        }
    }

    pub fn heal(&mut self, amount: u32) {
        let max_health = 100 + (self.level as u32 * 10);
        self.health = std::cmp::min(self.health + amount, max_health);
    }

    pub fn add_score(&mut self, points: u32) {
        self.score += points;
    }

    pub fn add_to_inventory(&mut self, item: String) {
        self.inventory.push(item);
    }

    pub fn remove_from_inventory(&mut self, item: &str) -> bool {
        if let Some(index) = self.inventory.iter().position(|i| i == item) {
            self.inventory.remove(index);
            true
        } else {
            false
        }
    }

    pub fn is_alive(&self) -> bool {
        self.health > 0
    }

    pub fn get_distance_to(&self, other_position: (i32, i32)) -> f64 {
        let dx = (self.position.0 - other_position.0) as f64;
        let dy = (self.position.1 - other_position.1) as f64;
        (dx * dx + dy * dy).sqrt()
    }

    pub fn record_trade(&mut self) {
        let current_time = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs();
        self.last_trade_at = Some(current_time);
    }

    pub fn has_traded_within(&self, duration_seconds: u64) -> bool {
        match self.last_trade_at {
            Some(last_trade) => {
                let current_time = std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap()
                    .as_secs();
                current_time - last_trade <= duration_seconds
            },
            None => false,
        }
    }
}

#[derive(Clone)]
pub struct PlayerService;

impl PlayerService {
    pub fn new() -> Self {
        Self
    }
} 