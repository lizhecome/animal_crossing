module animal_crossing::wild_coin;
use protocol::reserve::MarketCoin;
use protocol::market::{Market};
use protocol::version::{Version};
use protocol::redeem;

use sui::balance::{Self, Balance};
use sui::coin::{Self, TreasuryCap, Coin};
use sui::sui::SUI;
use sui::transfer::share_object;
use sui::clock::{Clock};
use sui::linked_table::{Self,LinkedTable};

public struct WILD_COIN has drop {}

const ERR_CANNOT_INCREASE_UNFROZEN_SUPPLY_BEYOND_TOTAL_SUPPLY: u64 = 1;
const ERR_CANNOT_DECREASE_UNFROZEN_SUPPLY_BELOW_ZERO: u64 = 2;
const ERR_CANNOT_UNFREEZE_BEYOND_TOTAL_SUPPLY: u64 = 3;
const ERR_PURCHASE_AMOUNT_EXCEEDS_UNFROZEN_SUPPLY: u64 = 4;
const ERR_CANNOT_BURN_MORE_THAN_CIRCULATING_SUPPLY: u64 = 5;
const ERR_INSUFFICIENT_BALANCE: u64 = 6;
const ERR_CANNOT_SWAP_MORE_THAN_CIRCULATING_SUPPLY: u64 = 7;
const ERR_INSUFFICIENT_REWARD_BALANCE: u64 = 8;
const ERR_INSUFFICIENT_DONATION_BALANCE: u64 = 9;
const ERR_INSUFFICIENT_SCOIN_BALANCE: u64 = 10;


const TOTAL_SUPPLY: u64 = 10_000_000_000_000_000_000;

public struct Wild_Supply has key {
    id: UID,
    current_unfrozen_supply: u64,
    circulating_supply: u64,
}

public struct WildVault has key {
    id: UID,
    sui_balance: Balance<SUI>, // Use Balance type to store SUI
    wild_coin_balance: Balance<WILD_COIN>, // Use Balance type to store WILD_COIN
    reward_sui_blance:Balance<SUI>,
    donation_balance: Balance<SUI>, // Use Balance type to store SUI donations
    scoin_balance:Balance<MarketCoin<SUI>>,
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
        reward_sui_blance: balance::zero<SUI>(),
        donation_balance: balance::zero<SUI>(),
        scoin_balance:balance::zero<MarketCoin<SUI>>()
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
public fun mint_wild(
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

public fun swap_wild_coin_for_sui(
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

public fun deposit_sui_coin_to_reward(
    _: &WILD_COIN_AdminCap,
    vault: &mut WildVault,
    sui_coin: Coin<SUI>,
    _: &mut TxContext
) {
    let balance_dewrap = coin::into_balance(sui_coin);
    vault.reward_sui_blance.join(balance_dewrap);

}

public fun withdraw_sui_from_reward(
    _: &WILD_COIN_AdminCap,
    vault: &mut WildVault,
    amount: u64,
    recipient: address,
    ctx: &mut TxContext
){
    // Ensure the amount to be withdrawn does not exceed the available balance in the reward
    assert!(vault.reward_sui_blance.value() >= amount, ERR_INSUFFICIENT_REWARD_BALANCE);

    // Split the balance to get the specified amount
    let withdrawn_coin = coin::take(&mut vault.reward_sui_blance, amount, ctx);

    // Transfer the withdrawn SUI coin to the recipient
    transfer::public_transfer(withdrawn_coin, recipient);
}

public fun withdraw_donation_balance(
    _: &WILD_COIN_AdminCap,
    vault: &mut WildVault,
    amount: u64,
    recipient: address,
    ctx: &mut TxContext
) {
    // Ensure the amount to be withdrawn does not exceed the available donation balance
    assert!(vault.donation_balance.value() >= amount, ERR_INSUFFICIENT_DONATION_BALANCE);

    // Split the balance to get the specified amount
    let withdrawn_coin = coin::take(&mut vault.donation_balance, amount, ctx);

    // Transfer the withdrawn SUI coin to the recipient
    transfer::public_transfer(withdrawn_coin, recipient);
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

// This function deposits SUI into the lending platform.
// It ensures that the specified amount of SUI is deposited from the vault to the lending platform.
// 
// @param clock The clock to get the current timestamp.
// @param storage The storage for the lending platform.
// @param pool_a The incentive funds pool for SUI.
// @param vault The vault containing the SUI balance.
// @param deposit_coin The SUI coin to be deposited.
// @param inc_v1 The incentive V1 for the lending platform.
// @param inc_v2 The incentive V2 for the lending platform.
public(package) fun deposit_sui_to_lending_platform(
    scallop_version: &Version,
    scallop_market: &mut Market,
    deposit_coin: Coin<SUI>,
    clock: &Clock,
    vault: &mut WildVault,
    ctx: &mut TxContext) {
    let minted_coin = protocol::mint::mint<SUI>(
        scallop_version,
        scallop_market,
        deposit_coin,
        clock,
        ctx,
    );
    deposit_scoin_to_vault(vault, minted_coin);
}
// This function ensures that the specified amount of SUI is withdrawn from the lending platform and deposited into the vault's SUI balance.
// 
// @param vault The vault containing the SUI balance.
// @param sui_withdraw_amount The amount of SUI to withdraw.
// @param storage The storage for the lending platform.
// @param pool_sui The incentive funds pool for SUI.
// @param inc_v1 The incentive V1 for the lending platform.
// @param inc_v2 The incentive V2 for the lending platform.
// @param clock The clock to get the current timestamp.
// @param oracle The price oracle for SUI.
// @param ctx The transaction context.
public(package) fun withdraw_sui_from_lending_platform(
    version: &Version,
    market: &mut Market,
    scoin: Coin<MarketCoin<SUI>>,
    clock: &Clock,
    vault: & mut WildVault,
    ctx: &mut TxContext
){
    let withdrawn_coin = protocol::redeem::redeem<SUI>(version, market, scoin, clock, ctx);
    deposit_sui_to_vault(vault, withdrawn_coin);
}

public(package) fun deposit_sui_to_vault(
    vault: &mut WildVault,
    deposit_coin: Coin<SUI>,
) {
    // Merge the deposit coin into the vault's SUI balance
    balance::join(&mut vault.sui_balance, coin::into_balance(deposit_coin));
}

public(package) fun deposit_scoin_to_vault(    vault: &mut WildVault,
    deposit_scoin: Coin<MarketCoin<SUI>>,){
    balance::join(&mut vault.scoin_balance, coin::into_balance(deposit_scoin));
}
public(package) fun withdraw_scoin_from_vault(
    vault: &mut WildVault,
    withdraw_amount: u64,
    ctx: &mut TxContext
): Coin<MarketCoin<SUI>> {
    // Ensure the withdrawal amount does not exceed the available balance
    assert!(balance::value(&vault.scoin_balance) >= withdraw_amount, ERR_INSUFFICIENT_BALANCE);

    // Split the scoin balance to get the specified amount
    let withdrawn_scoin_balance= balance::split(&mut vault.scoin_balance, withdraw_amount);

    // Convert the withdrawn balance to a coin
    let withdrawn_scoin = coin::from_balance(withdrawn_scoin_balance, ctx);

    withdrawn_scoin
}



/// Claims rewards from the lending platform and deposits them into the vault.
/// 
/// This function ensures that the rewards are claimed from the lending platform and deposited into the vault's reward balance.
public(package) fun claim_reward_from_lending_platform(
    version: &Version,
    market: &mut Market,
    nft_bind_sui_amount:u64,
    clock: &Clock,
    vault: &mut WildVault,
    ctx: &mut TxContext
) {
    let all_scion_amount = balance::value(&vault.scoin_balance);
    let nft_bind_scion = calc_coin_to_scoin(version, market, std::type_name::get<SUI>(), clock, nft_bind_sui_amount);
    assert!(all_scion_amount >= nft_bind_scion, ERR_INSUFFICIENT_SCOIN_BALANCE);
    if(all_scion_amount > nft_bind_scion){
        let scoin = withdraw_scoin_from_vault(vault,all_scion_amount - nft_bind_scion,ctx);
        let sui_coin = redeem::redeem(version, market, scoin, clock, ctx);
        // Comment: Deposit the amount into the reward account
        deposit_reward_sui_to_vault(vault, sui_coin); 
    }
    
}

/// Deposits a specified amount of SUI into the vault's reward balance.
/// 
/// This function merges the deposit coin into the vault's reward SUI balance.
/// 
/// @param vault The vault containing the SUI reward balance.
/// @param deposit_coin The SUI coin to be deposited.
public(package) fun deposit_reward_sui_to_vault(
    vault: &mut WildVault,
    deposit_coin: Coin<SUI>,
) {
    // Merge the deposit coin into the vault's reward SUI balance
    balance::join(&mut vault.reward_sui_blance, coin::into_balance(deposit_coin));
}

/// Withdraws a specified amount of SUI from the vault.
/// 
/// This function ensures that the amount to be withdrawn does not exceed the available balance.
/// It then splits the balance to get the specified amount and returns the withdrawn coin.
/// 
/// @param vault The vault containing the SUI balance.
/// @param amount The amount of SUI to be withdrawn.
/// @param ctx The transaction context.
/// @return The withdrawn SUI coin.
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

public(package) fun withdraw_sui_from_vault_reward(
    vault: &mut WildVault,
    amount: u64,
    ctx: &mut TxContext
): Coin<SUI> {
    // Ensure the amount to be withdrawn does not exceed the available balance
    assert!(vault.reward_sui_blance.value() >= amount, ERR_INSUFFICIENT_BALANCE);

    // Split the balance to get the specified amount
    let withdrawn_coin = coin::take(&mut vault.reward_sui_blance, amount, ctx);

    // Return the withdrawn coin
    withdrawn_coin
}

/// Distributes the airdrop rewards to the NFT holders based on the airdrop distribution table.
/// 
/// This function calculates the total amount of SUI to be distributed from the vault's reward balance.
/// It then iterates over the airdrop table, which contains the NFT IDs and their corresponding reward ratios.
/// For each NFT, it calculates the reward amount based on the ratio and ensures the amount is greater than zero.
/// If the reward amount is valid, it withdraws the SUI from the vault and transfers it to the NFT's address.
/// 
/// @param airdrop_table The table containing the NFT IDs and their reward ratios.
/// @param vault The vault containing the SUI reward balance.
/// @param ctx The transaction context.
public(package) fun distribute_airdrop(
    version: &Version,
    market: &mut Market,
    clock: &Clock,
    airdrop_table: &LinkedTable<ID, u64>,
    nft_count:u64,
    unit:u64,
    vault: &mut WildVault,
    ctx: &mut TxContext
) {
    let amount = nft_count * unit;

    claim_reward_from_lending_platform(version,market,amount,clock,vault,ctx);

    // Calculate the total amount of SUI to be distributed
    let total_reward = vault.reward_sui_blance.value();
    // Calculate the donation amount (20% of total reward)
    let donation_amount = total_reward * 20 / 100;

    // Calculate the remaining amount for distribution (80% of total reward)
    let distribution_amount = total_reward - donation_amount;

    // Withdraw the donation amount from the vault and add it to the donation balance
    let donation_coin = withdraw_sui_from_vault_reward(vault, donation_amount, ctx);
    balance::join(&mut vault.donation_balance, coin::into_balance(donation_coin));

    // Withdraw the remaining reward amount from the vault and add it to the sui_balance
    let remaining_reward_coin = withdraw_sui_from_vault_reward(vault, distribution_amount, ctx);
    balance::join(&mut vault.sui_balance, coin::into_balance(remaining_reward_coin));

    // Update the total reward to reflect the remaining amount for distribution
    let total_reward = distribution_amount;

    // Iterate over the airdrop table to distribute the SUI
    let mut front_item = linked_table::front(airdrop_table);
    while (option::is_some(front_item)) {
        let nft_id = option::borrow(front_item);
        let reward_ratio = linked_table::borrow(airdrop_table, *nft_id);
        let reward_amount = (total_reward * *reward_ratio) / 1_000_000_000;

        // Ensure the reward amount is greater than zero
        if (reward_amount > 0) {
            // Withdraw the reward amount from the vault
            let reward_coin = withdraw_sui_from_vault(vault, reward_amount, ctx);

            // Transfer the reward coin to the NFT's address
            let nft_address = nft_id.to_address();
            transfer::public_transfer(reward_coin, nft_address);
        };

        front_item = linked_table::next(airdrop_table, *nft_id);
    }
}


  public(package) fun calc_coin_to_scoin(
    version: &protocol::version::Version,
    market: &mut protocol::market::Market, 
    coin_type: std::type_name::TypeName, 
    clock: &sui::clock::Clock,
    coin_amount: u64
  ): u64 {
    let (cash, debt, revenue, market_coin_supply) = get_reserve_stats(version, market, coin_type, clock);

    let scoin_amount = if (market_coin_supply > 0) {
      math::u64::mul_div(
        coin_amount,
        market_coin_supply,
        cash + debt - revenue
      )
    } else {
      coin_amount
    };

    // if the coin is too less, just throw error
    assert!(scoin_amount > 0, 1);
    
    scoin_amount
  }


  fun calc_scoin_to_coin(
    version: &protocol::version::Version,
    market: &mut protocol::market::Market, 
    coin_type: std::type_name::TypeName, 
    clock: &sui::clock::Clock,
    scoin_amount: u64
  ): u64 {
    let (cash, debt, revenue, market_coin_supply) = get_reserve_stats(version, market, coin_type, clock);
    
    let coin_amount = math::u64::mul_div(
      scoin_amount,
      cash + debt - revenue,
      market_coin_supply
    );

    coin_amount
  }



  fun get_reserve_stats(
    version: &protocol::version::Version,
    market: &mut protocol::market::Market,
    coin_type: std::type_name::TypeName,
    clock: &sui::clock::Clock,
  ): (u64, u64, u64, u64) {
    // update to the latest reserve stats
    // NOTE: this function needs to be called to get an accurate data
    protocol::accrue_interest::accrue_interest_for_market(
      version,
      market,
      clock
    );

    let vault = protocol::market::vault(market);
    let balance_sheets = protocol::reserve::balance_sheets(vault);

    let balance_sheet = x::wit_table::borrow(balance_sheets, coin_type);
    let (cash, debt, revenue, market_coin_supply) = protocol::reserve::balance_sheet(balance_sheet);
    (cash, debt, revenue, market_coin_supply)
  }