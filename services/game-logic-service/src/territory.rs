use std::collections::HashMap;
use std::fs::{File, OpenOptions};
use std::io::{Read, Write};

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct Player {
    pub wallet: String,
    pub ink: i64,
    pub streak: u32,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct Tile {
    pub id: (u32, u32),
    pub owner: Option<String>,
    pub ink: i64,
    pub contested: bool,
}

#[derive(Debug, serde::Serialize, serde::Deserialize)]
pub struct GameMap {
    pub tiles: HashMap<(u32, u32), Tile>,
}

impl GameMap {
    pub fn new(width: u32, height: u32) -> Self {
        let mut tiles = HashMap::new();
        for x in 0..width {
            for y in 0..height {
                tiles.insert((x, y), Tile {
                    id: (x, y),
                    owner: None,
                    ink: 0,
                    contested: false,
                });
            }
        }
        GameMap { tiles }
    }

    pub fn tag_tile(&mut self, player: &Player, tile_id: (u32, u32), ink: i64) -> Option<&Tile> {
        if let Some(tile) = self.tiles.get_mut(&tile_id) {
            tile.ink += ink;
            tile.owner = Some(player.wallet.clone());
            // Add more conquest logic here (contested, streaks, etc.)
            Some(tile)
        } else {
            None
        }
    }

    pub fn get_tile(&self, tile_id: (u32, u32)) -> Option<&Tile> {
        self.tiles.get(&tile_id)
    }

    pub fn save_to_file(&self, path: &str) -> std::io::Result<()> {
        let serialized = serde_json::to_string(self).expect("Failed to serialize GameMap");
        let mut file = OpenOptions::new().write(true).create(true).truncate(true).open(path)?;
        file.write_all(serialized.as_bytes())?;
        Ok(())
    }

    pub fn load_from_file(path: &str) -> std::io::Result<Self> {
        let mut file = File::open(path)?;
        let mut contents = String::new();
        file.read_to_string(&mut contents)?;
        let game_map: GameMap = serde_json::from_str(&contents).expect("Failed to deserialize GameMap");
        Ok(game_map)
    }
}

impl Player {
    pub fn save_to_file(&self, path: &str) -> std::io::Result<()> {
        let serialized = serde_json::to_string(self).expect("Failed to serialize Player");
        let mut file = OpenOptions::new().write(true).create(true).truncate(true).open(path)?;
        file.write_all(serialized.as_bytes())?;
        Ok(())
    }

    pub fn load_from_file(path: &str) -> std::io::Result<Self> {
        let mut file = File::open(path)?;
        let mut contents = String::new();
        file.read_to_string(&mut contents)?;
        let player: Player = serde_json::from_str(&contents).expect("Failed to deserialize Player");
        Ok(player)
    }
} 