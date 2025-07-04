use starknet::{ContractAddress, get_caller_address};
use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
use core::num::traits::Zero;

#[starknet::interface]
trait IERC165<TContractState> {
    fn supports_interface(self: @TContractState, interface_id: felt252) -> bool;
}

#[starknet::interface]
trait IERC721<TContractState> {
    fn balance_of(self: @TContractState, owner: ContractAddress) -> u256;
    fn owner_of(self: @TContractState, token_id: u256) -> ContractAddress;
    fn safe_transfer_from(
        ref self: TContractState,
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        data: Span<felt252>
    );
    fn transfer_from(ref self: TContractState, from: ContractAddress, to: ContractAddress, token_id: u256);
    fn approve(ref self: TContractState, to: ContractAddress, token_id: u256);
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
    fn get_approved(self: @TContractState, token_id: u256) -> ContractAddress;
    fn is_approved_for_all(self: @TContractState, owner: ContractAddress, operator: ContractAddress) -> bool;
}

#[starknet::interface]
trait IERC721Metadata<TContractState> {
    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn token_uri(self: @TContractState, token_id: u256) -> ByteArray;
}

#[starknet::interface]
trait IDripNFT<TContractState> {
    fn mint(ref self: TContractState, to: ContractAddress, token_id: u256);
    fn burn(ref self: TContractState, token_id: u256);
    fn set_token_uri(ref self: TContractState, token_id: u256, uri: ByteArray);
    fn set_base_uri(ref self: TContractState, base_uri: ByteArray);
    fn total_supply(self: @TContractState) -> u256;
    fn max_supply(self: @TContractState) -> u256;
    fn set_max_supply(ref self: TContractState, new_max_supply: u256);
    fn owner(self: @TContractState) -> ContractAddress;
    fn transfer_ownership(ref self: TContractState, new_owner: ContractAddress);
}

#[starknet::contract]
mod DripNFT {
    use super::{IERC165, IERC721, IERC721Metadata, IDripNFT};
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use core::num::traits::Zero;

    #[storage]
    struct Storage {
        // ERC721 storage
        name: ByteArray,
        symbol: ByteArray,
        owners: Map<u256, ContractAddress>,
        balances: Map<ContractAddress, u256>,
        token_approvals: Map<u256, ContractAddress>,
        operator_approvals: Map<(ContractAddress, ContractAddress), bool>,
        
        // Metadata storage
        token_uris: Map<u256, ByteArray>,
        base_uri: ByteArray,
        
        // Ownable storage
        owner: ContractAddress,
        
        // Supply management
        total_supply: u256,
        max_supply: u256,
        
        // Security features
        minting_enabled: bool,
        burn_enabled: bool,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Transfer: Transfer,
        Approval: Approval,
        ApprovalForAll: ApprovalForAll,
        TokenMinted: TokenMinted,
        TokenBurned: TokenBurned,
        OwnershipTransferred: OwnershipTransferred,
    }

    #[derive(Drop, starknet::Event)]
    struct Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        #[key]
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct Approval {
        #[key]
        owner: ContractAddress,
        #[key]
        approved: ContractAddress,
        #[key]
        token_id: u256
    }

    #[derive(Drop, starknet::Event)]
    struct ApprovalForAll {
        #[key]
        owner: ContractAddress,
        #[key]
        operator: ContractAddress,
        approved: bool
    }

    #[derive(Drop, starknet::Event)]
    struct TokenMinted {
        #[key]
        token_id: u256,
        #[key]
        to: ContractAddress,
        #[key]
        minter: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct TokenBurned {
        #[key]
        token_id: u256,
        #[key]
        from: ContractAddress,
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
        name: ByteArray,
        symbol: ByteArray,
        max_supply: u256,
        base_uri: ByteArray,
        owner: ContractAddress
    ) {
        self.name.write(name);
        self.symbol.write(symbol);
        self.max_supply.write(max_supply);
        self.base_uri.write(base_uri);
        self.owner.write(owner);
        self.total_supply.write(0);
        self.minting_enabled.write(true);
        self.burn_enabled.write(true);
    }

    #[abi(embed_v0)]
    impl ERC165Impl of IERC165<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            // ERC165 interface id
            if interface_id == 0x01ffc9a7 {
                return true;
            }
            // ERC721 interface id
            if interface_id == 0x80ac58cd {
                return true;
            }
            // ERC721Metadata interface id
            if interface_id == 0x5b5e139f {
                return true;
            }
            false
        }
    }

    #[abi(embed_v0)]
    impl ERC721Impl of IERC721<ContractState> {
        fn balance_of(self: @ContractState, owner: ContractAddress) -> u256 {
            assert(!owner.is_zero(), 'ERC721: invalid owner');
            self.balances.read(owner)
        }

        fn owner_of(self: @ContractState, token_id: u256) -> ContractAddress {
            let owner = self.owners.read(token_id);
            assert(!owner.is_zero(), 'ERC721: invalid token ID');
            owner
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: ContractAddress,
            to: ContractAddress,
            token_id: u256,
            data: Span<felt252>
        ) {
            self.transfer_from(from, to, token_id);
        }

        fn transfer_from(ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256) {
            assert(self._is_approved_or_owner(get_caller_address(), token_id), 'ERC721: unauthorized');
            self._transfer(from, to, token_id);
        }

        fn approve(ref self: ContractState, to: ContractAddress, token_id: u256) {
            let owner = self.owner_of(token_id);
            let caller = get_caller_address();
            assert(caller == owner || self.is_approved_for_all(owner, caller), 'ERC721: unauthorized');
            
            self.token_approvals.write(token_id, to);
            self.emit(Approval { owner, approved: to, token_id });
        }

        fn set_approval_for_all(ref self: ContractState, operator: ContractAddress, approved: bool) {
            let caller = get_caller_address();
            assert(caller != operator, 'ERC721: approve to caller');
            
            self.operator_approvals.write((caller, operator), approved);
            self.emit(ApprovalForAll { owner: caller, operator, approved });
        }

        fn get_approved(self: @ContractState, token_id: u256) -> ContractAddress {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self.token_approvals.read(token_id)
        }

        fn is_approved_for_all(self: @ContractState, owner: ContractAddress, operator: ContractAddress) -> bool {
            self.operator_approvals.read((owner, operator))
        }
    }

    #[abi(embed_v0)]
    impl ERC721MetadataImpl of IERC721Metadata<ContractState> {
        fn name(self: @ContractState) -> ByteArray {
            self.name.read()
        }

        fn symbol(self: @ContractState) -> ByteArray {
            self.symbol.read()
        }

        fn token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            
            let token_uri = self.token_uris.read(token_id);
            if token_uri.len() > 0 {
                return token_uri;
            }
            
            self.base_uri.read()
        }
    }

    #[abi(embed_v0)]
    impl DripNFTImpl of IDripNFT<ContractState> {
        fn mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            self._assert_only_owner();
            self._assert_minting_enabled();
            self._assert_max_supply_not_exceeded();
            assert(!self._exists(token_id), 'ERC721: token already minted');
            assert(!to.is_zero(), 'ERC721: mint to zero address');

            let caller = get_caller_address();
            
            // Update storage
            self.owners.write(token_id, to);
            let balance = self.balances.read(to);
            self.balances.write(to, balance + 1);
            let total = self.total_supply.read();
            self.total_supply.write(total + 1);

            // Emit events
            self.emit(Transfer { from: Zero::zero(), to, token_id });
            self.emit(TokenMinted { token_id, to, minter: caller });
        }

        fn burn(ref self: ContractState, token_id: u256) {
            self._assert_burn_enabled();
            let owner = self.owner_of(token_id);
            let caller = get_caller_address();
            assert(caller == owner, 'ERC721: unauthorized');

            // Clear approvals
            self.token_approvals.write(token_id, Zero::zero());
            
            // Update storage
            self.owners.write(token_id, Zero::zero());
            let balance = self.balances.read(owner);
            self.balances.write(owner, balance - 1);
            let total = self.total_supply.read();
            self.total_supply.write(total - 1);
            
            // Clear token URI
            self.token_uris.write(token_id, "");

            // Emit events
            self.emit(Transfer { from: owner, to: Zero::zero(), token_id });
            self.emit(TokenBurned { token_id, from: owner });
        }

        fn set_token_uri(ref self: ContractState, token_id: u256, uri: ByteArray) {
            self._assert_only_owner();
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            self.token_uris.write(token_id, uri);
        }

        fn set_base_uri(ref self: ContractState, base_uri: ByteArray) {
            self._assert_only_owner();
            self.base_uri.write(base_uri);
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn max_supply(self: @ContractState) -> u256 {
            self.max_supply.read()
        }

        fn set_max_supply(ref self: ContractState, new_max_supply: u256) {
            self._assert_only_owner();
            let current_supply = self.total_supply.read();
            assert(new_max_supply >= current_supply, 'Max supply too low');
            self.max_supply.write(new_max_supply);
        }

        fn owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            self._assert_only_owner();
            assert(!new_owner.is_zero(), 'New owner is zero address');
            
            let previous_owner = self.owner.read();
            self.owner.write(new_owner);
            
            self.emit(OwnershipTransferred { previous_owner, new_owner });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn _exists(self: @ContractState, token_id: u256) -> bool {
            !self.owners.read(token_id).is_zero()
        }

        fn _is_approved_or_owner(self: @ContractState, spender: ContractAddress, token_id: u256) -> bool {
            assert(self._exists(token_id), 'ERC721: invalid token ID');
            let owner = self.owners.read(token_id);
            spender == owner || self.get_approved(token_id) == spender || self.is_approved_for_all(owner, spender)
        }

        fn _transfer(ref self: ContractState, from: ContractAddress, to: ContractAddress, token_id: u256) {
            assert(from == self.owner_of(token_id), 'ERC721: invalid from');
            assert(!to.is_zero(), 'ERC721: invalid to');

            // Clear approvals
            self.token_approvals.write(token_id, Zero::zero());

            // Update balances
            let from_balance = self.balances.read(from);
            self.balances.write(from, from_balance - 1);
            let to_balance = self.balances.read(to);
            self.balances.write(to, to_balance + 1);

            // Update ownership
            self.owners.write(token_id, to);

            self.emit(Transfer { from, to, token_id });
        }

        fn _assert_only_owner(self: @ContractState) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(caller == owner, 'Ownable: caller is not owner');
        }

        fn _assert_minting_enabled(self: @ContractState) {
            assert(self.minting_enabled.read(), 'Minting is disabled');
        }

        fn _assert_burn_enabled(self: @ContractState) {
            assert(self.burn_enabled.read(), 'Burning is disabled');
        }

        fn _assert_max_supply_not_exceeded(self: @ContractState) {
            let current_supply = self.total_supply.read();
            let max_supply = self.max_supply.read();
            assert(current_supply < max_supply, 'Max supply exceeded');
        }
    }
}