export package_id=0xc2b402278770049435fc0550a6f2204eaaa34b460524b6bd54a395585dfadb35
export WILD_COIN_AdminCap=0xf594dc7661712338e360ad0b112d1e53b2cca0bb4dfe4c23da4374179e600d2a
export Wild_Supply=0xd32b6a0586e0d26579020738b971524e62691cbec643843731dc07d671203de9
export Animals=0x123cfc9dc3aac02fffa8a0ce5cf056b457ceb43f022be0b5d9fddcf2b4e4cedc
export WildVault=0xce8ed9db4b647ab75bc353c3200a955e4c65b0208d74cebfd5d78f43d7c48f5a
export NFTAdminCap=0x7b138a50a23e3189225c0c448df5f25dbae57cf10c6a712523ec848a45fe13ab
export MintRecord=0xa638520e77988440d117dedfe279d2c2df56f3a69a7fe228f89907529f88343c
export TreasuryCap=0xc3e444257d891da4f3ecfacbb184142d59b3b8321c44f672710b7763206581be
export clock=0x6
export scallop_Version=0x07871c4b3c847a0f674510d4978d5cf6f960452795e8ff6f189fd2088a3f6ac7
export scallop_Market=0xa757975255146dc9686aa823b7838b507f315d704f428cbadad2f4ea061939d9

export sui_coin=0x397716b3cf71c4bf0b0a30071c713a1392b9c9375a2d2a77c0866e585af6b080
export wild_coin=0x26abb2faeafc4e1a942c47d8ff2c22f282e3c948470df3ea9be31c893288b5e7
export nft_id=0x52b0543dfa7ea1053c82da1031c3b1f727851a686218e61a10ee494342038db9
export recipient=0x43d945f82670c017d1989a6613612092e07560dcf88580f6649c4c0b7aa54e44

sui client call --package $package_id --module wild_coin  --function increase_unfrozen_supply --args $WILD_COIN_AdminCap $Wild_Supply 100000000000 --gas-budget=10000000

sui client call --package $package_id --module wild_coin  --function mint_wild --args $TreasuryCap $WildVault $Wild_Supply $sui_coin $recipient --gas-budget=10000000



sui client call --package $package_id --module wild_coin  --function swap_wild_coin_for_sui --args $TreasuryCap $Wild_Supply $WildVault $wild_coin $recipient --gas-budget=10000000

sui client call --package $package_id --module wild_NFT  --function create_animal_info --args $NFTAdminCap $Animals "Panda" "Ailuropoda melanoleuca" "Pandas live mainly in temperate forests high in the mountains of southwest China, where they subsist almost entirely on bamboo. They must eat around 26 to 84 pounds of it every day, depending on what part of the bamboo they are eating." 75 "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Giant_Panda_Eating.jpg/220px-Giant_Panda_Eating.jpg" --gas-budget=10000000

sui client call --package $package_id --module wild_NFT  --function create_animal_info --args $NFTAdminCap $Animals "Chimpanzee" "Pan troglodytes" "Chimpanzees, inhabitants of Central and Western African forests, are highly social and intelligent. They live in troops structured around dominant individuals, forming strong bonds through grooming. Renowned for tool use, they fashion sticks to fish termites and leaves as sponges. Omnivorous, their diet varies seasonally. Communication includes pant-hoots for social bonding and various vocalizations for emotions and warnings. Conflicts are managed through social dynamics, though physical altercations can occur. Their study offers insights into human behavior and primate societies." 70 "https://upload.wikimedia.org/wikipedia/commons/d/de/Chimpanzees_in_Uganda_%285984913059%29.jpg" --gas-budget=10000000

sui client call --package $package_id --module wild_NFT  --function create_animal_info --args $NFTAdminCap $Animals "Elephant" "Loxodonta africana" "Elephants are commonly known as elephants. They are the common name for animals of the family Elephantidae (scientific name: Elephantidae). They are the largest terrestrial animals in existence and belong to the order Proboscidea. There are only two genera and three species left, namely the African elephant genus and the Asian elephant genus. There are two types of African elephants: African savanna elephants and African forest elephants. There is only one species of Asian elephants in the Asian elephant genus. They are widely distributed in tropical and subtropical areas south of the Sahara Desert in Africa, South Asia, Southeast Asia and even the southwest border of China." 60 "https://upload.wikimedia.org/wikipedia/commons/thumb/b/bf/African_Elephant_%28Loxodonta_africana%29_male_%2817289351322%29.jpg/800px-African_Elephant_%28Loxodonta_africana%29_male_%2817289351322%29.jpg" --gas-budget=10000000


sui client call --package $package_id --module wild_NFT  --function update_animal_info --args $NFTAdminCap $Animals 1 "Chimpanzee" "Pan troglodytes" "Chimpanzees, inhabitants of Central and Western African forests, are highly social and intelligent. They live in troops structured around dominant individuals, forming strong bonds through grooming. Renowned for tool use, they fashion sticks to fish termites and leaves as sponges. Omnivorous, their diet varies seasonally. Communication includes pant-hoots for social bonding and various vocalizations for emotions and warnings. Conflicts are managed through social dynamics, though physical altercations can occur. Their study offers insights into human behavior and primate societies." 70 "https://upload.wikimedia.org/wikipedia/commons/d/de/Chimpanzees_in_Uganda_%285984913059%29.jpg" --gas-budget=10000000


sui client call --package $package_id --module wild_NFT  --function fund_and_purchase_nft --args $Animals 0 $MintRecord $wild_coin $recipient $clock $storage $pool_sui $WildVault $inc_v1 $inc_v2  --gas-budget=1000000000


sui client call --package $package_id --module wild_NFT  --function abandon_adoption --args $scallop_Version $scallop_Market 0x10878d30b6be0fe49be6e6ef33c49ef57846104e718f40a4fff7b522a841a996 $WildVault $MintRecord $clock $recipient --gas-budget=1000000000

sui client call --package $package_id --module wild_coin  --function deposit_sui_coin_to_reward --args $WILD_COIN_AdminCap $WildVault 0x20a5be5cfca95476b56987266a695712771fedd683e405010b9bdf52eee02e97 --gas-budget=1000000000

sui client call --package $package_id --module wild_NFT --function calculate_send_airdrop_distribution --args $NFTAdminCap $scallop_Version $scallop_Market $MintRecord $Animals $WildVault $clock --gas-budget=1000000000

sui client call --package $package_id --module wild_coin --function claim_reward_from_lending_platform --args $WILD_COIN_AdminCap $clock $storage $incentiveFundsPool_sui $WildVault $inc_v2 --gas-budget=1000000000


