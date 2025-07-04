#[starknet::contract]
mod TestContract {
    use starknet::get_caller_address;

    #[storage]
    struct Storage {
        balance: u256,
        owner: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Minted: Minted,
    }

    #[derive(Drop, starknet::Event)]
    struct Minted {
        amount: u256,
        caller: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
        self.balance.write(0_u256);
    }

    #[external(v0)]
    fn mint(ref self: ContractState, amount: u256) {
        let caller = get_caller_address();
        let current_balance = self.balance.read();
        self.balance.write(current_balance + amount);
        
        self.emit(Minted { amount, caller });
    }

    #[external(v0)]
    fn get_balance(self: @ContractState) -> u256 {
        self.balance.read()
    }

    #[external(v0)]
    fn get_owner(self: @ContractState) -> ContractAddress {
        self.owner.read()
    }
} 