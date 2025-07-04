#[starknet::contract]
mod SimpleTest {
    use starknet::get_caller_address;

    #[storage]
    struct Storage {
        value: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ValueSet: ValueSet,
    }

    #[derive(Drop, starknet::Event)]
    struct ValueSet {
        value: u256,
        caller: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.value.write(0_u256);
    }

    #[external(v0)]
    fn set_value(ref self: ContractState, new_value: u256) {
        let caller = get_caller_address();
        self.value.write(new_value);
        self.emit(ValueSet { value: new_value, caller });
    }

    #[external(v0)]
    fn get_value(self: @ContractState) -> u256 {
        self.value.read()
    }
} 