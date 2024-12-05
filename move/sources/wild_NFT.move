/// Module: animal_crossing
module animal_crossing::wild_NFT;

use animal_crossing::wild_coin::{Self,WildVault};
use std::string::{String, utf8};
use sui::coin::{Self, Coin};
use sui::display;
use sui::event;
use sui::package;
use sui::table::{Self, Table};
use sui::clock::{Clock};
use sui::sui::SUI;
use lending_core::incentive::{Incentive as IncentiveV1};
use lending_core::incentive_v2::Incentive;
use lending_core::pool::{Pool};
use lending_core::storage::{Storage};

const ERR_NFT_PRICE_IS_EXACTLY_10_WILD_COIN: u64 = 5;

public struct WILD_NFT has drop {}
/// List of precious animals, containing AnimalInfo
public struct Animals has key {
    id: UID,
    animal_infos: Table<u64, AnimalInfo>,
}

/// Get all animal information from the list of precious animals, returning a Table<u64, AnimalInfo>
public fun get_all_animal_infos(animals: &Animals): &Table<u64, AnimalInfo> {
    &animals.animal_infos
}

/// Endangered animal basic information structure
public struct AnimalInfo has key, store {
    id: UID, // Unique identifier
    name: String,
    species: String, // Animal species
    habitat: String, // Habitat
    status: String, // Endangered status
    image_url: String, // Image URL
}

/// Animal NFT structure
public struct AnimalNFT has key, store {
    id: UID, // Unique identifier for NFT
    name: String, // Animal name
    species: String, // Animal species
    habitat: String, // Habitat
    status: String, // Endangered status
    adopted_by: address, // Adopter's address
    image_url: String, // Image URL
}



// Define admin capability
public struct NFTAdminCap has key {
    id: UID,
}

public struct MintRecord has key {
    id: UID,
    record: vector<address>,
}

public struct NFTMinted has copy, drop {
    object_id: ID,
    creator: address,
    name: String,
}

/// NFT Abandoned structure
public struct NFTAbandoned has drop, copy {
    name: String, // Animal name
    species: String, // Animal species
    habitat: String, // Habitat
    status: String, // Endangered status
    abandoned_by: address, // Abandoner's address
    image_url: String, // Image URL
}


/// Initialize the contract function
fun init(otw: WILD_NFT, ctx: &mut TxContext) {
    let admin_cap = NFTAdminCap { id: object::new(ctx) };
    let animals = Animals {
        id: object::new(ctx),
        animal_infos: table::new(ctx),
    };
    let mint_record = MintRecord {
        id: object::new(ctx),
        record: vector::empty(),
    };

    let keys = vector[
        utf8(b"name"),
        utf8(b"species"),
        utf8(b"habitat"),
        utf8(b"status"),
        utf8(b"adopted_by"),
        utf8(b"image_url"),
        utf8(b"creator"),
    ];
    let values = vector[
        utf8(b"{nft.name}"),
        utf8(b"{nft.species}"),
        utf8(b"{nft.habitat}"),
        utf8(b"{nft.status}"),
        utf8(b"{nft.adopted_by}"),
        utf8(b"{nft.image_url}"),
        utf8(b"{ctx.sender()}"),
    ];
    let publisher = package::claim(otw, ctx);
    let mut display = display::new_with_fields<AnimalNFT>(&publisher, keys, values, ctx);
    display::update_version(&mut display);

    transfer::public_transfer(display, ctx.sender());
    transfer::share_object(mint_record);
    transfer::share_object(animals);
    transfer::transfer(admin_cap, tx_context::sender(ctx));
    transfer::public_transfer(publisher, tx_context::sender(ctx));
}

/// Create new animal information (admin-only) and push to Animals
entry fun create_animal_info(
    _: &NFTAdminCap,
    animals: &mut Animals,
    name: String,
    species: String,
    habitat: String,
    status: String,
    image_url: String,
    ctx: &mut TxContext,
) {
    let animal_info = AnimalInfo {
        id: object::new(ctx),
        name,
        species,
        habitat,
        status,
        image_url,
    };

    let key = table::length(&animals.animal_infos);
    table::add(&mut animals.animal_infos, key, animal_info);
}

/// Fund function to purchase NFT using inputcoin: Coin<WILD_COIN>, priced at 10
entry fun fund_and_purchase_nft(
    animals: &Animals,
    key: u64, // key of animal_infos
    inputcoin: Coin<wild_coin::WILD_COIN>,
    recipient: address,
    clock: &Clock,
    storage: &mut Storage,
    pool_sui: &mut Pool<SUI>,
    vault: &mut WildVault,
    inc_v1: &mut IncentiveV1,
    inc_v2: &mut Incentive,
    ctx: &mut TxContext,
) {
    // Verify payment amount
    assert!(coin::value(&inputcoin) == 10, ERR_NFT_PRICE_IS_EXACTLY_10_WILD_COIN);

    // Get the specified AnimalInfo
    let animal_info = &animals.animal_infos[key];

    // Create NFT
    let nft = AnimalNFT {
        id: object::new(ctx),
        name: animal_info.name, // Animal name can be customized by the user
        species: animal_info.species,
        habitat: animal_info.habitat,
        status: animal_info.status,
        adopted_by: tx_context::sender(ctx),
        image_url: animal_info.image_url,
    };
    let coin_sui = wild_coin::withdraw_sui_from_vault(vault,10,ctx);
    wild_coin::deposit_sui_to__lending_platform(clock,storage,pool_sui,vault,coin_sui,inc_v1,inc_v2);
    
    // 将inputcoin存入vault
    wild_coin::deposit_wild_coin(vault, inputcoin);

    event::emit(NFTMinted {
        object_id: object::id(&nft),
        creator: ctx.sender(),
        name: nft.name,
    });

    transfer::public_transfer(nft, recipient);
}



public entry fun abandon_adoption(
    nft: AnimalNFT,
    vault: &mut WildVault,
    ctx: &mut TxContext
) {
    event::emit(NFTAbandoned {
            name: nft.name,
            species: nft.species,
            habitat: nft.habitat,
            status: nft.status,
            image_url: nft.image_url,
            abandoned_by: ctx.sender(),
        });
    // Destroy the NFT
    let AnimalNFT {
        id,
        name: _,
        species: _,
        habitat: _,
        status: _,
        adopted_by: _,
        image_url: _
    } = nft;
    object::delete(id);

    // Mint and deposit 10 WILD_COIN back to the vault
    let wild_coin = wild_coin::withdraw_wild_coin_from_vault(vault,10,ctx);
    transfer::public_transfer(wild_coin, ctx.sender());
}
