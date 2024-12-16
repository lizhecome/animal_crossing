/// Module: animal_crossing
module animal_crossing::wild_NFT;

use protocol::market::{Market};
use protocol::version::{Version};

use animal_crossing::wild_coin::{Self,WildVault};
use std::string::{String, utf8};
use sui::coin::{Self, Coin};
use sui::display;
use sui::event;
use sui::package;
use sui::transfer::Receiving;
use sui::table::{Self, Table};
use sui::clock::{Self,Clock};
use sui::sui::SUI;
use sui::linked_table::{Self,LinkedTable};


// Error code indicating that the NFT price must be exactly equal to the specified WILD_COIN amount.
const ERR_NFT_PRICE_IS_EXACTLY_NFT_PRICE_WILD_COIN: u64 = 5;

// Error code indicating that the specified key does not exist in the table.
const ERR_KEY_DOES_NOT_EXIST: u64 = 1;

// The price of the NFT in WILD_COIN, set to 1 billion (10^9) WILD_COIN.
const NFT_PRICE: u64 = 1_000_000_000;
//const NFT_PRICE: u64 = 10;

public struct WILD_NFT has drop {}
/// List of precious animals, containing AnimalInfo
public struct Animals has key, store {
    id: UID,
    animal_infos: Table<u64, AnimalInfo>,
}

/// Endangered animal basic information structure
public struct AnimalInfo has key, store {
    id: UID, // Unique identifier
    name: String,
    species: String, // Animal species
    habitat: String, // Habitat
    status: u64, // Endangered status
    image_url: String, // Image URL
}

/// Animal NFT structure
public struct AnimalNFT has key, store {
    id: UID, // Unique identifier for NFT
    name: String, // Animal name
    animal_id: u64,
    species: String, // Animal species
    habitat: String, // Habitat
    adopted_by: address, // Adopter's address
    image_url: String, // Image URL
    create_time: u64, // Timestamp of creation
}


// Define admin capability
public struct NFTAdminCap has key {
    id: UID,
}

/// Record structure for minting NFTs
/// Contains a UID as a unique identifier
/// And a LinkedTable to store the minting records
/// Where the key is of type u64 and the value is another LinkedTable, storing mappings of ID to u64
public struct MintRecord has key,store {
    id: UID, // Unique identifier
    record: LinkedTable<u64, LinkedTable<ID, u64>>, // Minting records
    count:u64 // Minting count
}

/// Record of minted NFTs
/// Contains the following fields:
/// - object_id: ID of the NFT object
/// - creator: Address of the NFT creator
/// - name: Name of the NFT
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
        record: linked_table::new(ctx),
        count:0
    };

    let keys = vector[
        utf8(b"name"),
        utf8(b"species"),
        utf8(b"habitat"),
        utf8(b"status"),
        utf8(b"adopted_by"),
        utf8(b"image_url"),
    ];
    let values = vector[
        utf8(b"{name}"),
        utf8(b"{species}"),
        utf8(b"{habitat}"),
        utf8(b"{status}"),
        utf8(b"{adopted_by}"),
        utf8(b"{image_url}"),
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

/// Get all animal information from the list of precious animals, returning a Table<u64, AnimalInfo>
public fun get_all_animal_infos(animals: &Animals): &Table<u64, AnimalInfo> {
    &animals.animal_infos
}

/// Create new animal information (admin-only) and push to Animals
public fun create_animal_info(
    _: &NFTAdminCap,
    animals: &mut Animals,
    name: String,
    species: String,
    habitat: String,
    status: u64,
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

/// Update animal information (admin-only) in Animals
public fun update_animal_info(
    _: &NFTAdminCap,
    animals: &mut Animals,
    key: u64, // key of animal_infos
    name: String,
    species: String,
    habitat: String,
    status: u64,
    image_url: String,
    _: &mut TxContext,
) {
    // Ensure the key exists in the table
    assert!(table::contains(&animals.animal_infos, key), ERR_KEY_DOES_NOT_EXIST);

    // Get the existing animal info
    let animal_info = table::borrow_mut(&mut animals.animal_infos, key);

    // Update the fields
    animal_info.name = name;
    animal_info.species = species;
    animal_info.habitat = habitat;
    animal_info.status = status;
    animal_info.image_url = image_url;
}


/// This method is used to purchase an NFT using the input WILD_COIN.
/// The input WILD_COIN must be equal to NFT_PRICE.
/// This method will withdraw an equivalent amount of SUI from the vault and deposit it into the lending platform.
/// At the same time, the input WILD_COIN will be deposited into the vault.
/// https://github.com/naviprotocol/navi-sdk/blob/692a001f174a758544accfa05459f1edc8366c89/src/address.ts#L58
/// Fund function to purchase NFT using inputcoin: Coin<WILD_COIN>, priced at NFT_PRICE
public fun fund_and_purchase_nft(
    scallop_version: &Version,
    scallop_market: &mut Market,
    animals: &Animals,
    key: u64, // key of animal_infos
    record: & mut MintRecord,
    inputcoin: Coin<wild_coin::WILD_COIN>,
    recipient: address,
    clock: &Clock,
    vault: &mut WildVault,
    ctx: &mut TxContext,
) {
    // Verify payment amount
    assert!(coin::value(&inputcoin) == NFT_PRICE, ERR_NFT_PRICE_IS_EXACTLY_NFT_PRICE_WILD_COIN);

    // Get the specified AnimalInfo
    let animal_info = &animals.animal_infos[key];

    // Create NFT
    let nft = AnimalNFT {
        id: object::new(ctx),
        name: animal_info.name, // Animal name can be customized by the user
        animal_id:key,
        species: animal_info.species,
        habitat: animal_info.habitat,
        adopted_by: tx_context::sender(ctx),
        image_url: animal_info.image_url,
        create_time: clock::timestamp_ms(clock),
    };
    let coin_sui = wild_coin::withdraw_sui_from_vault(vault,NFT_PRICE,ctx);
    wild_coin::deposit_sui_to_lending_platform(scallop_version,scallop_market,coin_sui,clock,vault,ctx);
    
    // 将inputcoin存入vault
    wild_coin::deposit_wild_coin(vault, inputcoin);

    let nft_id = object::id(&nft);
    let nft_create_time = nft.create_time;
    if (!linked_table::contains(&record.record, key)) {
        let mut nfts =  linked_table::new<ID,u64>(ctx);
        linked_table::push_back(&mut nfts, nft_id, nft_create_time);

        linked_table::push_back(&mut record.record, key, nfts);
    } else {
        let record_value = linked_table::borrow_mut(&mut record.record, key);
        linked_table::push_back(record_value, nft_id,clock::timestamp_ms(clock));
    };
    record.count = record.count + 1;
    event::emit(NFTMinted {
        object_id: object::id(&nft),
        creator: ctx.sender(),
        name: animal_info.name,
    });

    transfer::public_transfer(nft, recipient);
}


// This function allows the user to abandon the adoption of an NFT.
// It emits an event to notify that the NFT has been abandoned.
// The NFT is removed from the minting record.
// The function also withdraws the equivalent amount of SUI from the lending platform.
// Finally, the NFT is destroyed.
public fun abandon_adoption(
    version: &Version,
    market: &mut Market,
    nft: AnimalNFT,
    vault: &mut WildVault,
    record: & mut MintRecord,
    clock: &Clock,
    recipient: address,
    ctx: &mut TxContext
) {
    // Emit an event to notify that the NFT has been abandoned
    event::emit(NFTAbandoned {
            name: nft.name,
            species: nft.species,
            habitat: nft.habitat,
            image_url: nft.image_url,
            abandoned_by: ctx.sender(),
        });
    
    // Get the ID of the NFT
    let nft_id = object::id(&nft);
    
    // Assuming species is the key used in the record
    let key = nft.animal_id;
    
    // Check if the key exists in the record
    if (linked_table::contains(&record.record, key)) {
        // Borrow the mutable reference to the record value
        let record_value = linked_table::borrow_mut(&mut record.record, key);
        
        // Remove the NFT from the record value
        linked_table::remove(record_value, nft_id);
        
        // If the record value is empty after removal, drop it
        if (linked_table::is_empty(record_value)) {
            let nft = linked_table::remove(&mut record.record, key);
            nft.drop();
        }
    };
    record.count = record.count - 1;
    let scoin_amount = wild_coin::calc_coin_to_scoin(version,market,std::type_name::get<SUI>(),clock,NFT_PRICE);
    let scoin = wild_coin::withdraw_scoin_from_vault(vault, scoin_amount, ctx);
    wild_coin::withdraw_sui_from_lending_platform(version,market,scoin,clock,vault,ctx);
    
    // Destroy the NFT
    let AnimalNFT {
        id,
        name: _,
        animal_id:_,
        species: _,
        habitat: _,
        adopted_by: _,
        image_url: _,
        create_time: _
    } = nft;
    object::delete(id);

    // Mint and deposit NFT_PRICE WILD_COIN back to the vault
    let wild_coin = wild_coin::withdraw_wild_coin_from_vault(vault,NFT_PRICE,ctx);
    
    // Transfer the minted WILD_COIN back to the sender
    transfer::public_transfer(wild_coin, recipient);
}

public struct Nft_weight has store,drop{
    status_weight:u64,
    time_weight:u64
}


/// Calculates the airdrop distribution based on the status and time weights of NFTs.
/// 
/// This function iterates through the minting records to collect all NFT data, 
/// calculates the total weights based on the endangered status and the time held, 
/// and then determines the airdrop distribution proportionally.
///
/// @param _admin_cap The admin capability for the NFT system.
/// @param record The minting record containing NFT data.
/// @param animals The collection of animal information.
/// @param vault The vault containing the WILD_COIN balance.
/// @param clock The clock to get the current timestamp.
/// @param ctx The transaction context.
public fun calculate_send_airdrop_distribution(
    _: &NFTAdminCap,
    version: &Version,
    market: &mut Market,
    record: &MintRecord,
    animals: &Animals,
    vault: &mut WildVault,
    clock: &Clock,
    ctx: &mut TxContext
){
    let mut total_status_weight = 0u64;
    let mut total_time_weight = 0u64;
    let mut airdrop_table = linked_table::new<ID, u64> (ctx);

    // Step 1: Collect all NFT data and calculate total weights
    let current_time = clock::timestamp_ms(clock);
    let mut front_item = linked_table::front(&record.record);
    let mut nft_weights = linked_table::new<ID, Nft_weight>(ctx); // (nft_id, status_weight, time_weight)
    while (option::is_some(front_item)) {
        let key = option::borrow(front_item);
        let nfts = linked_table::borrow(&record.record, *key);
        let animal_info = table::borrow(&animals.animal_infos, *key);
        let status_weight = animal_info.status;

        let mut front_nft = linked_table::front(nfts);

        while (option::is_some(front_nft)) {
            let nft_key = option::borrow<ID>(front_nft);
            let create_time = linked_table::borrow(nfts, *nft_key);

            let time_held = current_time - *create_time;
            let time_weight = time_held / 86400000 + 1; // Convert milliseconds to days

            total_status_weight = total_status_weight + status_weight;
            total_time_weight = total_time_weight + time_weight;

             linked_table::push_back(&mut nft_weights, *nft_key, Nft_weight {
                status_weight,
                time_weight
            });
            front_nft = linked_table::next(nfts, *nft_key);
        };

        front_item = linked_table::next(&record.record, *key);
    };

    assert!(total_status_weight > 0, 1);
    assert!(total_time_weight > 0, 2);

    // Step 2: Calculate the airdrop distribution based on status and time weights
    let mut front_item = linked_table::front(&nft_weights);
    while (option::is_some(front_item)) {
        let nft_id = option::borrow(front_item);
        let Nft_weight { status_weight, time_weight } = linked_table::borrow(&nft_weights, *nft_id);
        let status_ratio = *status_weight * 1_000_000_000 / total_status_weight;
        let time_ratio = *time_weight * 1_000_000_000 / total_time_weight;

        let reward = status_ratio * 8 / 10 + time_ratio * 2 / 10; // Customize the formula as needed
        linked_table::push_back(&mut airdrop_table, *nft_id, reward);

        front_item = linked_table::next(&nft_weights, *nft_id);
    };

    wild_coin::distribute_airdrop(version,market,clock,&airdrop_table, record.count, NFT_PRICE,vault, ctx);
    linked_table::drop(airdrop_table);
    linked_table::drop(nft_weights);
}

/// Function to get an airdrop for an NFT.
/// This function transfers the airdropped SUI coin to the specified recipient.
/// 
/// @param nft: The NFT for which the airdrop is being claimed.
/// @param to_recive: The receiving object for the airdropped SUI coin.
/// @param recipient: The address of the recipient who will receive the airdropped SUI coin.
/// @param _: The transaction context.
public fun get_airdrop(
    nft:& mut AnimalNFT,
    to_recive: Receiving<Coin<SUI>>,
    recipient:address,
    _: & TxContext
){
    let coin = transfer::public_receive<Coin<SUI>>(&mut nft.id, to_recive);
    transfer::public_transfer(coin, recipient)
}





