use starknet::contract_address::ContractAddress;

#[starknet::interface]
trait IPaymaster<TContractState> {
    fn validate_and_pay_fee(
        self: @TContractState,
        user: ContractAddress,
        selector: felt252,
        max_fee: u256,
    ) -> bool;
    fn post_process(
        self: @TContractState,
        user: ContractAddress,
        selector: felt252,
    );
}

#[starknet::contract]
mod Paymaster {
    use starknet::contract_address::ContractAddress;
    use starknet::get_caller_address;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        balance: u256,
        whitelisted_selector: felt252, // Only one whitelisted selector for v0
    }

    #[abi(embed_v0)]
    impl PaymasterImpl of super::IPaymaster<ContractState> {
        fn validate_and_pay_fee(
            self: @ContractState,
            user: ContractAddress,
            selector: felt252,
            max_fee: u256,
        ) -> bool {
            if selector != self.whitelisted_selector.read() {
                return false;
            }
            if self.balance.read() < max_fee {
                return false;
            }
            true
        }

        fn post_process(
            self: @ContractState,
            user: ContractAddress,
            selector: felt252,
        ) {
            // v0: no-op
        }
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, whitelisted_selector: felt252) {
        self.owner.write(owner);
        self.balance.write(0_u256);
        self.whitelisted_selector.write(whitelisted_selector);
    }

    #[abi(embed_v0)]
    impl PaymasterAdminImpl of super::IPaymasterAdmin<ContractState> {

        fn fund(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Only owner can fund');
            assert(amount > 0, 'Amount must be greater than 0');
            
            // In a real implementation, validate that ETH was actually sent
            let current_balance = self.balance.read();
            let new_balance = current_balance + amount;
            
            // Check for overflow
            assert(new_balance >= current_balance, 'Balance overflow');
            
            self.balance.write(new_balance);
        }

        fn get_balance(self: @ContractState) -> u256 {
            self.balance.read()
        }

        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn get_whitelisted_selector(self: @ContractState) -> felt252 {
            self.whitelisted_selector.read()
        }
    }
}

#[starknet::interface]
trait IPaymasterAdmin<TContractState> {
    fn fund(ref self: TContractState, amount: u256);
    fn get_balance(self: @TContractState) -> u256;
    fn get_owner(self: @TContractState) -> ContractAddress;
    fn get_whitelisted_selector(self: @TContractState) -> felt252;
}
