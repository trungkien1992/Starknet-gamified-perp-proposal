use serde::{Serialize, Deserialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PluginManifest {
    pub id: String,
    pub name: String,
    pub version: String,
    pub author: String,
    pub description: String,
    pub plugin_type: PluginType,
    pub entrypoint: String,
    pub permissions: Vec<PluginPermission>,
    pub assets: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum PluginType {
    CityMap,
    NFTPack,
    UIMod,
    PvPRule,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum PluginPermission {
    ReadTiles,
    WriteTiles,
    MintNFT,
    ModifyUI,
    CustomRule,
} 