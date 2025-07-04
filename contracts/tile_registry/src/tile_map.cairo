use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};

#[derive(Drop, Serde, starknet::Store, Copy)]
struct Tile {
    owner: ContractAddress,
    x: u32,
    y: u32,
    level: u8,
    claimed_at: u64,
    last_upgraded: u64,
}

#[starknet::interface]
trait ITileMap<TContractState> {
    fn claim_tile(ref self: TContractState, x: u32, y: u32) -> u256;
    fn transfer_tile(ref self: TContractState, tile_id: u256, to: ContractAddress);
    fn upgrade_tile(ref self: TContractState, tile_id: u256);
    fn get_tile(self: @TContractState, tile_id: u256) -> Tile;
    fn get_tile_by_coordinates(self: @TContractState, x: u32, y: u32) -> u256;
    fn get_player_tile_count(self: @TContractState, player: ContractAddress) -> u256;
    fn total_tiles(self: @TContractState) -> u256;
    fn owner(self: @TContractState) -> ContractAddress;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress);
}

#[starknet::contract]
mod TileMap {
    use super::{Tile, ITileMap};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use core::num::traits::Zero;

    #[storage]
    struct Storage {
        // Tile management
        tiles: Map<u256, Tile>,
        coordinates_to_tile: Map<(u32, u32), u256>,
        player_tile_count: Map<ContractAddress, u256>,
        
        // Game configuration
        max_tiles_per_player: u32,
        claim_cooldown: u64,
        upgrade_cooldown: u64,
        
        // Ownable
        owner: ContractAddress,
        
        // Counters
        total_tiles: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        TileClaimed: TileClaimed,
        TileTransferred: TileTransferred,
        TileUpgraded: TileUpgraded,
        OwnershipTransferred: OwnershipTransferred,
    }

    #[derive(Drop, starknet::Event)]
    struct TileClaimed {
        #[key]
        tile_id: u256,
        #[key]
        owner: ContractAddress,
        x: u32,
        y: u32,
        level: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct TileTransferred {
        #[key]
        tile_id: u256,
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct TileUpgraded {
        #[key]
        tile_id: u256,
        #[key]
        owner: ContractAddress,
        new_level: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct OwnershipTransferred {
        #[key]
        previous_owner: ContractAddress,
        #[key]
        new_owner: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        max_tiles_per_player: u32,
        claim_cooldown: u64,
        upgrade_cooldown: u64
    ) {
        self.owner.write(owner);
        self.max_tiles_per_player.write(max_tiles_per_player);
        self.claim_cooldown.write(claim_cooldown);
        self.upgrade_cooldown.write(upgrade_cooldown);
        self.total_tiles.write(0);
    }

    #[abi(embed_v0)]
    impl TileMapImpl of ITileMap<ContractState> {
        fn claim_tile(ref self: ContractState, x: u32, y: u32) -> u256 {
            let caller = get_caller_address();
            
            // Check if coordinates are already claimed
            let existing_tile_id = self.coordinates_to_tile.read((x, y));
            assert(existing_tile_id == 0, 'Tile already claimed');
            
            // Check player tile limit
            let player_count = self.player_tile_count.read(caller);
            assert(player_count < self.max_tiles_per_player.read().into(), 'Tile limit exceeded');
            
            // Generate tile ID
            let tile_id = self.total_tiles.read() + 1;
            
            // Create tile
            let tile = Tile {
                owner: caller,
                x,
                y,
                level: 1,
                claimed_at: get_block_timestamp(),
                last_upgraded: get_block_timestamp(),
            };
            
            // Store tile data
            self.tiles.write(tile_id, tile);
            self.coordinates_to_tile.write((x, y), tile_id);
            self.player_tile_count.write(caller, player_count + 1);
            self.total_tiles.write(tile_id);
            
            // Emit event
            self.emit(TileClaimed { tile_id, owner: caller, x, y, level: 1 });
            
            tile_id
        }

        fn transfer_tile(ref self: ContractState, tile_id: u256, to: ContractAddress) {
            let caller = get_caller_address();
            
            // Check if tile exists and caller owns it
            let tile = self.tiles.read(tile_id);
            assert(tile.owner == caller, 'Not tile owner');
            assert(!to.is_zero(), 'Invalid recipient');
            
            // Update tile owner
            let updated_tile = Tile {
                owner: to,
                x: tile.x,
                y: tile.y,
                level: tile.level,
                claimed_at: tile.claimed_at,
                last_upgraded: tile.last_upgraded,
            };
            self.tiles.write(tile_id, updated_tile);
            
            // Update tile counts
            let from_count = self.player_tile_count.read(caller);
            let to_count = self.player_tile_count.read(to);
            self.player_tile_count.write(caller, from_count - 1);
            self.player_tile_count.write(to, to_count + 1);
            
            // Emit event
            self.emit(TileTransferred { tile_id, from: caller, to });
        }

        fn upgrade_tile(ref self: ContractState, tile_id: u256) {
            let caller = get_caller_address();
            let current_time = get_block_timestamp();
            
            // Check if tile exists and caller owns it
            let tile = self.tiles.read(tile_id);
            assert(tile.owner == caller, 'Not tile owner');
            
            // Check upgrade cooldown
            let time_since_upgrade = current_time - tile.last_upgraded;
            assert(time_since_upgrade >= self.upgrade_cooldown.read(), 'Cooldown not met');
            
            // Check max level
            assert(tile.level < 10, 'Max level reached');
            
            // Update tile level
            let updated_tile = Tile {
                owner: tile.owner,
                x: tile.x,
                y: tile.y,
                level: tile.level + 1,
                claimed_at: tile.claimed_at,
                last_upgraded: current_time,
            };
            self.tiles.write(tile_id, updated_tile);
            
            // Emit event
            self.emit(TileUpgraded { tile_id, owner: caller, new_level: updated_tile.level });
        }

        fn get_tile(self: @ContractState, tile_id: u256) -> Tile {
            self.tiles.read(tile_id)
        }

        fn get_tile_by_coordinates(self: @ContractState, x: u32, y: u32) -> u256 {
            self.coordinates_to_tile.read((x, y))
        }

        fn get_player_tile_count(self: @ContractState, player: ContractAddress) -> u256 {
            self.player_tile_count.read(player)
        }

        fn total_tiles(self: @ContractState) -> u256 {
            self.total_tiles.read()
        }

        fn owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            self._assert_only_owner();
            assert(!new_owner.is_zero(), 'Invalid new owner');

            let previous_owner = self.owner.read();
            self.owner.write(new_owner);

            self.emit(OwnershipTransferred { previous_owner, new_owner });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _assert_only_owner(self: @ContractState) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(caller == owner, 'Caller not owner');
        }
    }
}