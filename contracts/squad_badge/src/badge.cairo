use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};

#[derive(Drop, Serde, starknet::Store, Copy)]
struct Badge {
    owner: ContractAddress,
    badge_type: u8, // 1=Conquest, 2=Streak, 3=PvP, 4=Territory, 5=Special
    level: u8,
    minted_at: u64,
}

#[starknet::interface]
trait ISquadBadge<TContractState> {
    fn mint_badge(ref self: TContractState, to: ContractAddress, badge_type: u8, level: u8) -> u256;
    fn upgrade_badge(ref self: TContractState, badge_id: u256);
    fn burn_badge(ref self: TContractState, badge_id: u256);
    fn get_badge(self: @TContractState, badge_id: u256) -> Badge;
    fn get_player_badge_count(self: @TContractState, player: ContractAddress) -> u256;
    fn total_supply(self: @TContractState) -> u256;
    fn owner(self: @TContractState) -> ContractAddress;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress);
}

#[starknet::contract]
mod SquadBadge {
    use super::{Badge, ISquadBadge};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use core::num::traits::Zero;

    #[storage]
    struct Storage {
        // Badge management
        badges: Map<u256, Badge>,
        owner_badge_count: Map<ContractAddress, u256>,
        
        // Ownable
        owner: ContractAddress,
        
        // Supply management
        total_supply: u256,
        max_badges_per_player: u32,
        upgrade_cooldown: u64,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BadgeMinted: BadgeMinted,
        BadgeBurned: BadgeBurned,
        BadgeUpgraded: BadgeUpgraded,
        OwnershipTransferred: OwnershipTransferred,
    }

    #[derive(Drop, starknet::Event)]
    struct BadgeMinted {
        #[key]
        badge_id: u256,
        #[key]
        to: ContractAddress,
        #[key]
        badge_type: u8,
        level: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct BadgeBurned {
        #[key]
        badge_id: u256,
        #[key]
        from: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct BadgeUpgraded {
        #[key]
        badge_id: u256,
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
        max_badges_per_player: u32,
        upgrade_cooldown: u64
    ) {
        self.owner.write(owner);
        self.max_badges_per_player.write(max_badges_per_player);
        self.upgrade_cooldown.write(upgrade_cooldown);
        self.total_supply.write(0);
    }

    #[abi(embed_v0)]
    impl SquadBadgeImpl of ISquadBadge<ContractState> {
        fn mint_badge(ref self: ContractState, to: ContractAddress, badge_type: u8, level: u8) -> u256 {
            self._assert_only_owner();
            self._assert_valid_badge_type(badge_type);
            self._assert_valid_level(level);
            assert(!to.is_zero(), 'Invalid recipient');

            // Check player badge limit
            let player_count = self.owner_badge_count.read(to);
            assert(player_count < self.max_badges_per_player.read().into(), 'Badge limit exceeded');

            // Generate badge ID
            let badge_id = self.total_supply.read() + 1;

            // Create badge
            let badge = Badge {
                owner: to,
                badge_type,
                level,
                minted_at: get_block_timestamp(),
            };

            // Store badge
            self.badges.write(badge_id, badge);
            self.owner_badge_count.write(to, player_count + 1);
            self.total_supply.write(badge_id);

            // Emit event
            self.emit(BadgeMinted { badge_id, to, badge_type, level });

            badge_id
        }

        fn upgrade_badge(ref self: ContractState, badge_id: u256) {
            let caller = get_caller_address();
            let current_time = get_block_timestamp();

            // Check if badge exists and caller owns it
            let badge = self.badges.read(badge_id);
            assert(badge.owner == caller, 'Not badge owner');

            // Check upgrade cooldown
            let time_since_mint = current_time - badge.minted_at;
            assert(time_since_mint >= self.upgrade_cooldown.read(), 'Cooldown not met');

            // Check max level
            assert(badge.level < 10, 'Max level reached');

            // Update badge level
            let updated_badge = Badge {
                owner: badge.owner,
                badge_type: badge.badge_type,
                level: badge.level + 1,
                minted_at: badge.minted_at,
            };
            self.badges.write(badge_id, updated_badge);

            // Emit event
            self.emit(BadgeUpgraded { badge_id, owner: caller, new_level: updated_badge.level });
        }

        fn burn_badge(ref self: ContractState, badge_id: u256) {
            let caller = get_caller_address();

            // Check if badge exists and caller owns it
            let badge = self.badges.read(badge_id);
            assert(badge.owner == caller, 'Not badge owner');

            // Clear badge data
            let empty_badge = Badge {
                owner: Zero::zero(),
                badge_type: 0,
                level: 0,
                minted_at: 0,
            };
            self.badges.write(badge_id, empty_badge);

            // Update owner badge count
            let current_count = self.owner_badge_count.read(caller);
            self.owner_badge_count.write(caller, current_count - 1);

            // Emit event
            self.emit(BadgeBurned { badge_id, from: caller });
        }

        fn get_badge(self: @ContractState, badge_id: u256) -> Badge {
            self.badges.read(badge_id)
        }

        fn get_player_badge_count(self: @ContractState, player: ContractAddress) -> u256 {
            self.owner_badge_count.read(player)
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
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

        fn _assert_valid_badge_type(self: @ContractState, badge_type: u8) {
            assert(badge_type >= 1 && badge_type <= 5, 'Invalid badge type');
        }

        fn _assert_valid_level(self: @ContractState, level: u8) {
            assert(level >= 1 && level <= 10, 'Invalid level');
        }
    }
}