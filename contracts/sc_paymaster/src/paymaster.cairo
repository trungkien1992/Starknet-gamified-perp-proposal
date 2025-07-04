use starknet::contract_address::ContractAddress;

#[starknet::interface]
trait IPaymaster<TContractState> {
    fn validate_and_pay_fee(
        ref self: TContractState,
        selector: felt252,
        max_fee: u256,
    ) -> bool;
    fn get_balance(self: @TContractState) -> u256;
}

#[starknet::interface]
trait IPaymasterAdmin<TContractState> {
    fn fund(ref self: TContractState);
    fn withdraw_fees(ref self: TContractState, amount: u256, recipient: ContractAddress);
    fn update_whitelisted_selector(ref self: TContractState, new_selector: felt252);
}

#[starknet::contract]
mod Paymaster {
    use starknet::contract_address::ContractAddress;
    use starknet::get_caller_address;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        balance: u256,
        whitelisted_selector: felt252,
        total_fees_paid: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        FeePaid: FeePaid,
        Funded: Funded,
    }

    #[derive(Drop, starknet::Event)]
    struct FeePaid {
        selector: felt252,
        fee: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Funded {
        amount: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, 
        owner: ContractAddress, 
        whitelisted_selector: felt252
    ) {
        self.owner.write(owner);
        self.balance.write(0_u256);
        self.whitelisted_selector.write(whitelisted_selector);
        self.total_fees_paid.write(0_u256);
    }

    #[abi(embed_v0)]
    impl PaymasterImpl of super::IPaymaster<ContractState> {
        fn validate_and_pay_fee(
            ref self: ContractState,
            selector: felt252,
            max_fee: u256,
        ) -> bool {
            // Check if selector is whitelisted
            if selector != self.whitelisted_selector.read() {
                return false;
            }
            
            // Check if paymaster has sufficient balance
            if self.balance.read() < max_fee {
                return false;
            }
            
            // Update balance and total fees paid
            let current_balance = self.balance.read();
            let new_balance = current_balance - max_fee;
            self.balance.write(new_balance);
            
            let current_total = self.total_fees_paid.read();
            let new_total = current_total + max_fee;
            self.total_fees_paid.write(new_total);
            
            // Emit event
            self.emit(FeePaid { 
                selector, 
                fee: max_fee
            });
            
            true
        }

        fn get_balance(self: @ContractState) -> u256 {
            self.balance.read()
        }
    }

    #[abi(embed_v0)]
    impl PaymasterAdminImpl of super::IPaymasterAdmin<ContractState> {
        fn fund(ref self: ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Only owner can fund');
            
            // In a production implementation, this would validate actual ETH received
            // For now, we emit event to indicate funding occurred
            let funded_amount = 1000000_u256; // Placeholder amount
            
            let current_balance = self.balance.read();
            let new_balance = current_balance + funded_amount;
            
            // Check for overflow
            assert(new_balance >= current_balance, 'Balance overflow');
            
            self.balance.write(new_balance);
            self.emit(Funded { amount: funded_amount });
        }

        fn withdraw_fees(ref self: ContractState, amount: u256, recipient: ContractAddress) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Only owner');
            
            // Validate recipient is not zero address
            let zero_address: ContractAddress = 0.try_into().unwrap();
            assert(recipient != zero_address, 'Invalid recipient');
            
            let current_balance = self.balance.read();
            assert(amount <= current_balance, 'Insufficient balance');
            assert(amount > 0, 'Amount must be greater than 0');
            
            // Update balance (checks-effects-interactions pattern)
            let new_balance = current_balance - amount;
            self.balance.write(new_balance);
            
            // In production, would implement actual ETH transfer here
            // For now, balance update simulates the withdrawal
        }

        fn update_whitelisted_selector(ref self: ContractState, new_selector: felt252) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Only owner');
            
            self.whitelisted_selector.write(new_selector);
        }
    }
}
 