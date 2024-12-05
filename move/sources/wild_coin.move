module animal_crossing::wild_coin;

use lending_core::account::AccountCap;
use lending_core::incentive::Incentive as IncentiveV1;
use lending_core::incentive_v2::{IncentiveFundsPool,Incentive};
use lending_core::lending;
// use lending_core::logic;
use lending_core::pool::Pool;
use lending_core::storage::Storage;
// use lending_core::version;
use sui::balance::{Self, Balance};
use sui::coin::{Self, TreasuryCap, Coin};
use sui::sui::SUI;
use sui::transfer::share_object;
use sui::clock::{Clock};

use oracle::oracle::{PriceOracle};

public struct WILD_COIN has drop {}

const ERR_CANNOT_INCREASE_UNFROZEN_SUPPLY_BEYOND_TOTAL_SUPPLY: u64 = 1;
const ERR_CANNOT_DECREASE_UNFROZEN_SUPPLY_BELOW_ZERO: u64 = 2;
const ERR_CANNOT_UNFREEZE_BEYOND_TOTAL_SUPPLY: u64 = 3;
const ERR_PURCHASE_AMOUNT_EXCEEDS_UNFROZEN_SUPPLY: u64 = 4;
const ERR_CANNOT_BURN_MORE_THAN_CIRCULATING_SUPPLY: u64 = 5;
const ERR_INSUFFICIENT_BALANCE: u64 = 6;
const ERR_CANNOT_SWAP_MORE_THAN_CIRCULATING_SUPPLY: u64 = 7;


const TOTAL_SUPPLY: u64 = 1_000_000_000;

public struct Wild_Supply has key {
    id: UID,
    current_unfrozen_supply: u64,
    circulating_supply: u64,
}

public struct WildVault has key {
    id: UID,
    sui_balance: Balance<SUI>, // Use Balance type to store SUI
    wild_coin_balance: Balance<WILD_COIN>, // Use Balance type to store WILD_COIN
    account_cap: AccountCap,
    sui_index: u8,
    usdc_index: u8,
}

// Define admin capability identifier
public struct WILD_COIN_AdminCap has key {
    id: UID,
}

fun init(witness: WILD_COIN, ctx: &mut TxContext) {
    // TO add pic url on walrus
    let (treasury, metadata) = coin::create_currency(
        witness,
        9,
        b"WILD",
        b"wild coin",
        b"wild coin",
        option::none(),
        ctx,
    );
    let vault = WildVault {
        id: object::new(ctx),
        sui_balance: balance::zero<SUI>(),
        wild_coin_balance: balance::zero<WILD_COIN>(),
        account_cap: lending::create_account(ctx),
        sui_index: 0,
        usdc_index: 1,
    };
    let supply = Wild_Supply {
        id: object::new(ctx),
        current_unfrozen_supply: 0,
        circulating_supply: 0,
    };
    let admincap = WILD_COIN_AdminCap { id: object::new(ctx) };
    share_object(supply);
    share_object(vault);
    transfer::public_freeze_object(metadata);
    transfer::public_share_object(treasury);
    transfer::transfer(admincap, ctx.sender());
}

// Increase supply
public fun increase_unfrozen_supply(_: &WILD_COIN_AdminCap, supply: &mut Wild_Supply, amount: u64) {
    assert!(
        supply.current_unfrozen_supply + amount <= TOTAL_SUPPLY,
        ERR_CANNOT_INCREASE_UNFROZEN_SUPPLY_BEYOND_TOTAL_SUPPLY,
    );
    supply.current_unfrozen_supply = supply.current_unfrozen_supply + amount;
}

// Decrease supply
public fun decrease_unfrozen_supply(_: &WILD_COIN_AdminCap, supply: &mut Wild_Supply, amount: u64) {
    assert!(
        supply.current_unfrozen_supply >= amount,
        ERR_CANNOT_DECREASE_UNFROZEN_SUPPLY_BELOW_ZERO,
    );
    supply.current_unfrozen_supply = supply.current_unfrozen_supply - amount;
}

// buy wild_coin
entry fun mint_wild(
    treasury_cap: &mut TreasuryCap<WILD_COIN>,
    bank: &mut WildVault,
    supply: &mut Wild_Supply,
    inputcoin: Coin<SUI>,
    recipient: address,
    ctx: &mut TxContext,
) {
    assert!(
        supply.current_unfrozen_supply <= TOTAL_SUPPLY,
        ERR_CANNOT_UNFREEZE_BEYOND_TOTAL_SUPPLY,
    );
    let balance_dewrap = coin::into_balance(inputcoin);
    assert!(
        supply.circulating_supply + balance::value(&balance_dewrap) <= supply.current_unfrozen_supply,
        ERR_PURCHASE_AMOUNT_EXCEEDS_UNFROZEN_SUPPLY,
    );
    let coin = coin::mint(treasury_cap, balance::value(&balance_dewrap), ctx);
    supply.circulating_supply = supply.circulating_supply + balance::value(&balance_dewrap);
    bank.sui_balance.join(balance_dewrap);
    transfer::public_transfer(coin, recipient);
}

entry fun swap_wild_coin_for_sui(
    treasury_cap: &mut TreasuryCap<WILD_COIN>,
    supply: &mut Wild_Supply,
    vault: &mut WildVault,
    wild_coin: Coin<WILD_COIN>,
    recipient: address,
    ctx: &mut TxContext,
) {
    // Verify the amount of WILD_COIN to be swapped
    let amount = coin::value(&wild_coin);

    // Ensure the amount to be swapped does not exceed the circulating supply
    assert!(supply.circulating_supply >= amount, ERR_CANNOT_SWAP_MORE_THAN_CIRCULATING_SUPPLY);

    // Burn the WILD_COIN
    burn_wild_coin(treasury_cap, supply, wild_coin);

    // Withdraw the equivalent amount of SUI from the vault
    let sui_coin = withdraw_sui_from_vault(vault, amount, ctx);

    // Transfer the SUI to the recipient
    transfer::public_transfer(sui_coin, recipient);
}


/// Deposit wild coin
public(package) fun deposit_wild_coin(bank: &mut WildVault, wild_coin: Coin<WILD_COIN>) {
    let balance_dewrap = coin::into_balance(wild_coin);
    bank.wild_coin_balance.join(balance_dewrap);
}

public(package) fun withdraw_wild_coin_from_vault(
    vault: &mut WildVault,
    amount: u64,
    ctx: &mut TxContext
): Coin<WILD_COIN> {
    // Ensure the amount to be withdrawn does not exceed the available balance
    assert!(vault.wild_coin_balance.value() >= amount, ERR_INSUFFICIENT_BALANCE);

    // Split the balance to get the specified amount
    let withdrawn_coin = coin::take(&mut vault.wild_coin_balance, amount, ctx);

    // Return the withdrawn coin
    withdrawn_coin
}


/// Burn wild coin
public(package) fun burn_wild_coin(
    treasury_cap: &mut TreasuryCap<WILD_COIN>,
    supply: &mut Wild_Supply,
    wild_coin: Coin<WILD_COIN>,
) {
    let amount = wild_coin.value();

    // Ensure the amount to be burned does not exceed the circulating supply
    assert!(supply.circulating_supply >= amount, ERR_CANNOT_BURN_MORE_THAN_CIRCULATING_SUPPLY);

    // Burn the coins
    coin::burn(treasury_cap, wild_coin);

    // Update the circulating supply
    supply.circulating_supply = supply.circulating_supply - amount;
}

public(package) fun deposit_sui_to__lending_platform(
    clock: &Clock,
    storage: &mut Storage,
    pool_a: &mut Pool<SUI>,
    vault: & WildVault,
    deposit_coin: Coin<SUI>,
    inc_v1: &mut IncentiveV1,
    inc_v2: &mut Incentive,) {
        lending_core::incentive_v2::deposit_with_account_cap<SUI>(clock, storage, pool_a, vault.sui_index, deposit_coin, inc_v1, inc_v2, &vault.account_cap);
}

public(package) fun withdraw_sui_from_lending_platform(
    vault: & mut WildVault,
    sui_withdraw_amount: u64,
    storage: &mut Storage,
    pool_sui: &mut Pool<SUI>,
    inc_v1: &mut IncentiveV1,
    inc_v2: &mut Incentive,
    clock: &Clock,
    oracle: &PriceOracle,
    ctx: &mut TxContext
){
    let withdrawn_balance = lending_core::incentive_v2::withdraw_with_account_cap(
        clock, oracle, storage, pool_sui, vault.sui_index, sui_withdraw_amount, inc_v1, inc_v2, &vault.account_cap
    );
    let withdrawn_coin = coin::from_balance(withdrawn_balance, ctx);
    deposit_sui_to_vault(vault, withdrawn_coin);
}

public(package) fun deposit_sui_to_vault(
    vault: &mut WildVault,
    deposit_coin: Coin<SUI>,
) {
    // Merge the deposit coin into the vault's SUI balance
    balance::join(&mut vault.sui_balance, coin::into_balance(deposit_coin));
}

public(package) fun claim_reward_from_lending_platform(
    clock: &Clock,
    storage: &mut Storage,
    pool_sui: &mut IncentiveFundsPool<SUI>,
    vault: &mut WildVault,
    inc_v2: &mut Incentive,
    ctx: &mut TxContext
) {
    // Claim the reward from the lending platform
    let reward_balance = lending_core::incentive_v2::claim_reward_with_account_cap<SUI>(
        clock, 
        inc_v2, 
        pool_sui, 
        storage, 
        vault.sui_index, 
        0, 
        &vault.account_cap
    );

    // Convert the reward balance to a coin
    let reward_coin = coin::from_balance(reward_balance, ctx);

    // Deposit the reward coin into the vault
    deposit_sui_to_vault(vault, reward_coin);
}



public(package) fun withdraw_sui_from_vault(
    vault: &mut WildVault,
    amount: u64,
    ctx: &mut TxContext
): Coin<SUI> {
    // Ensure the amount to be withdrawn does not exceed the available balance
    assert!(vault.sui_balance.value() >= amount, ERR_INSUFFICIENT_BALANCE);

    // Split the balance to get the specified amount
    let withdrawn_coin = coin::take(&mut vault.sui_balance, amount, ctx);

    // Return the withdrawn coin
    withdrawn_coin
}
