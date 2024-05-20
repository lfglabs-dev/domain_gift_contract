use core::array::ArrayTrait;
use core::result::ResultTrait;
use core::option::OptionTrait;
use starknet::{ContractAddress, SyscallResultTrait};
use core::traits::TryInto;
use starknet::syscalls::deploy_syscall;
use openzeppelin::token::erc20::{
    interface::{IERC20Camel, IERC20CamelDispatcher, IERC20CamelDispatcherTrait}
};
use identity::{
    identity::main::Identity, interface::identity::{IIdentityDispatcher, IIdentityDispatcherTrait}
};
use naming::interface::naming::{INamingDispatcher, INamingDispatcherTrait};
use naming::interface::pricing::{IPricingDispatcher, IPricingDispatcherTrait};
use naming::naming::main::Naming;
use naming::pricing::Pricing;
use super::super::main::{
    IDomainGift, IDomainGiftDispatcher, IDomainGiftDispatcherTrait, DomainGift
};

fn deploy(contract_class_hash: felt252, calldata: Array<felt252>) -> ContractAddress {
    let (address, _) = deploy_syscall(
        contract_class_hash.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap_syscall();
    address
}

pub fn deploy_contracts() -> (IERC20CamelDispatcher, IDomainGiftDispatcher, IPricingDispatcher) {
    let admin = 0x123;
    //erc20
    let eth = deploy(ERC20::TEST_CLASS_HASH, array![]);
    // pricing
    let pricing = deploy(Pricing::TEST_CLASS_HASH, array![eth.into()]);
    // identity
    let identity = deploy(Identity::TEST_CLASS_HASH, array![admin, 0, 0, 0]);
    // naming
    let naming = deploy(Naming::TEST_CLASS_HASH, array![identity.into(), pricing.into(), 0, admin]);
    let domain_gift = deploy(
        DomainGift::TEST_CLASS_HASH, array![admin, naming.into(), eth.into(), pricing.into()]
    );

    (
        IERC20CamelDispatcher { contract_address: eth },
        IDomainGiftDispatcher { contract_address: domain_gift },
        IPricingDispatcher { contract_address: pricing },
    )
}

#[starknet::contract]
mod ERC20 {
    use openzeppelin::token::erc20::erc20::ERC20Component::InternalTrait as ERC20InternalTrait;
    use openzeppelin::{
        token::erc20::{ERC20Component, dual20::DualCaseERC20Impl, ERC20HooksEmptyImpl}
    };

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20CamelOnlyImpl = ERC20Component::ERC20CamelOnlyImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.erc20.initializer("ether", "ETH");
        let target = starknet::contract_address_const::<0x123>();
        self.erc20._mint(target, 0x100000000000000000000000000000000);
    }

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
    }
}
