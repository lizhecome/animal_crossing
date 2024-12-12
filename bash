export package_id=0xc199500bcbe51fb99480853d14009cbf603fe9ebff3851bd8976b95a535ba25b
export WILD_COIN_AdminCap=0x915996a8b6ad0fe93adec3ef2f8c3b06cd3c425a292a9eba5a344f613a6ab5be
export Wild_Supply=0xcabe65843c715a5fa03dc18083532ecfcfd0b998574f9ade3a1f70c9bc54617f
export Animals=0xf525630b4be045fae91915dd1b05b93b345dfc487dd81297db7204bd0987721f
export WildVault=0xc987f8b72887135f65622cd9442538f390f7c6a0f020369b63c639dbae74c2dd
export NFTAdminCap=0xb67c14f690ace58fe5e1ae3d1356ffe2c175e0940bb43f84fcaec59856353541
export MintRecord=0x7109c86e60355b8becdc8b0aa49b1dc306e34fcccc915a52214c32ddce62c90f
export TreasuryCap=0x5e30d379b7a15d5d648e29ed6c565c686f9e8ecfb5d621ef51fe279f9058a65e
export clock=0x6
export storage=0xbb4e2f4b6205c2e2a2db47aeb4f830796ec7c005f88537ee775986639bc442fe
export pool_sui=0x96df0fce3c471489f4debaaa762cf960b3d97820bd1f3f025ff8190730e958c5
export inc_v1=0xaaf735bf83ff564e1b219a0d644de894ef5bdc4b2250b126b2a46dd002331821
export inc_v2=0xf87a8acb8b81d14307894d12595541a73f19933f88e1326d5be349c7a6f7559c
export PriceOracle=0x1568865ed9a0b5ec414220e8f79b3d04c77acc82358f6e5ae4635687392ffbef


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


sui client call --package $package_id --module wild_NFT  --function abandon_adoption --args $nft_id $WildVault $MintRecord $storage $pool_sui $inc_v1 $inc_v2 $clock $PriceOracle $recipient --gas-budget=1000000000

sui client call --package $package_id --module wild_coin  --function deposit_sui_coin_to_reward --args $WILD_COIN_AdminCap $WildVault 0x0829f809c5e415a1b5a15a1891d296e4638179e9a55e3e027da030e6ab13f400 --gas-budget=1000000000

sui client call --package $package_id --module wild_NFT --function calculate_send_airdrop_distribution --args $NFTAdminCap $MintRecord $Animals $WildVault $clock --gas-budget=1000000000


