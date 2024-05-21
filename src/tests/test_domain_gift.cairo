use core::array::ArrayTrait;
use core::array::SpanTrait;
use core::option::OptionTrait;
use core::traits::Into;
use starknet::testing;
use starknet::ContractAddress;
use starknet::contract_address_const;
use starknet::testing::set_contract_address;
use super::utils::deploy_contracts;
use openzeppelin::token::erc20::{
    interface::{IERC20Camel, IERC20CamelDispatcher, IERC20CamelDispatcherTrait}
};
use domain_gift_contract::main::{IDomainGift, IDomainGiftDispatcher, IDomainGiftDispatcherTrait};
use naming::interface::pricing::{IPricingDispatcher, IPricingDispatcherTrait};

#[test]
#[available_gas(2000000000)]
fn test_domain_gift() {
    let (erc20, domain_gift, pricing) = deploy_contracts();
    let admin = contract_address_const::<0x123>();
    set_contract_address(admin);

    // send ETH to domain gift contract
    let (_, price) = pricing.compute_buy_price(7, 90);
    erc20.transfer(domain_gift.contract_address, price);

    // enable contract
    domain_gift.enable();

    // claim domain
    let sig = (
        1656235970515422137623518348033034423290400412873214899648105454205007418873,
        2792440294804924771913913656093129334725425963703426390447354149337645008208
    );
    let coupon_code = 123;
    domain_gift.get_free_domain(1, 404683926, sig, coupon_code, 0);

    // ensure domain contract balance is 0
    let balance = erc20.balanceOf(domain_gift.contract_address);
    assert(balance == 0, 'Balance should be 0');
}

#[test]
#[available_gas(2000000000)]
#[should_panic(expected: ('Coupon already claimed', 'ENTRYPOINT_FAILED'))]
fn test_domain_gift_claim_twice() {
    let (erc20, domain_gift, pricing) = deploy_contracts();
    let admin = contract_address_const::<0x123>();
    set_contract_address(admin);

    // send ETH to domain gift contract
    let (_, price) = pricing.compute_buy_price(7, 90);
    erc20.transfer(domain_gift.contract_address, price * 2);

    // enable contract
    domain_gift.enable();

    // claim domain
    let sig = (
        1656235970515422137623518348033034423290400412873214899648105454205007418873,
        2792440294804924771913913656093129334725425963703426390447354149337645008208
    );
    let coupon_code = 123;
    domain_gift.get_free_domain(1, 404683926, sig, coupon_code, 0);

    // claim a second time
    domain_gift.get_free_domain(1, 404683926, sig, coupon_code, 0);
}

#[test]
#[available_gas(2000000000)]
#[should_panic(expected: ('Invalid signature', 'ENTRYPOINT_FAILED'))]
fn test_try_another_domain() {
    let (erc20, domain_gift, pricing) = deploy_contracts();
    let admin = contract_address_const::<0x123>();
    set_contract_address(admin);

    // send ETH to domain gift contract
    let (_, price) = pricing.compute_buy_price(7, 90);
    erc20.transfer(domain_gift.contract_address, price);

    // enable contract
    domain_gift.enable();

    // claim domain
    let sig = (
        1656235970515422137623518348033034423290400412873214899648105454205007418873,
        2792440294804924771913913656093129334725425963703426390447354149337645008208
    );
    let coupon_code = 123;
    domain_gift.get_free_domain(1, 27, sig, coupon_code, 0);
}

#[test]
#[available_gas(2000000000)]
#[should_panic(
    expected: (
        'ERC20: insufficient balance', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'
    )
)]
fn test_insufficient_balance() {
    let (_, domain_gift, _) = deploy_contracts();
    let admin = contract_address_const::<0x123>();
    set_contract_address(admin);

    // enable contract
    domain_gift.enable();

    // claim domain but domain gift contract has no balance
    let sig = (
        1656235970515422137623518348033034423290400412873214899648105454205007418873,
        2792440294804924771913913656093129334725425963703426390447354149337645008208
    );
    let coupon_code = 123;
    domain_gift.get_free_domain(1, 404683926, sig, coupon_code, 0);
}

#[test]
#[available_gas(2000000000)]
#[should_panic(expected: ('Contract is disabled', 'ENTRYPOINT_FAILED'))]
fn test_domain_gift_disabled() {
    let (erc20, domain_gift, pricing) = deploy_contracts();
    let admin = contract_address_const::<0x123>();
    set_contract_address(admin);

    // send ETH to domain gift contract
    let (_, price) = pricing.compute_buy_price(7, 90);
    erc20.transfer(domain_gift.contract_address, price);

    // enable contract
    domain_gift.enable();

    // enable contract
    domain_gift.disable();

    // claim domain but domain gift contract has no balance
    let sig = (
        1656235970515422137623518348033034423290400412873214899648105454205007418873,
        2792440294804924771913913656093129334725425963703426390447354149337645008208
    );
    let coupon_code = 123;
    domain_gift.get_free_domain(1, 404683926, sig, coupon_code, 0);
}

#[test]
#[available_gas(2000000000)]
#[should_panic(expected: ('Caller is not the owner', 'ENTRYPOINT_FAILED'))]
fn test_enable_not_admin() {
    let (_, domain_gift, _) = deploy_contracts();
    let user = contract_address_const::<0x456>();
    set_contract_address(user);

    // enable contract fail because user is not admin
    domain_gift.enable();
}

#[test]
#[available_gas(2000000000)]
fn test_withdraw() {
    let (erc20, domain_gift, _) = deploy_contracts();
    let admin = contract_address_const::<0x123>();
    set_contract_address(admin);

    let initial_balance = erc20.balanceOf(admin);

    // send ETH to domain gift contract
    erc20.transfer(domain_gift.contract_address, 1000);

    // withdraw all funds
    domain_gift.withdraw(erc20.contract_address, admin);

    assert(erc20.balanceOf(domain_gift.contract_address) == 0, 'Contract balance should be 0');
    assert(erc20.balanceOf(admin) == initial_balance, 'Contract balance should be 0');
}

#[test]
#[available_gas(2000000000)]
#[should_panic(expected: ('Caller is not the owner', 'ENTRYPOINT_FAILED'))]
fn test_withdraw_not_admin() {
    let (erc20, domain_gift, _) = deploy_contracts();
    let admin = contract_address_const::<0x123>();
    let user = contract_address_const::<0x456>();

    // send ETH to domain gift contract
    set_contract_address(admin);
    erc20.transfer(domain_gift.contract_address, 1000);

    // try withdrawing all funds
    set_contract_address(user);
    domain_gift.withdraw(erc20.contract_address, user);
}
