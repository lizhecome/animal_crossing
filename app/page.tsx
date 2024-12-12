'use client'
import '../styles/background.css';
import { ConnectButton, useSignAndExecuteTransaction } from '@mysten/dapp-kit'
import Image from 'next/image'
import { getUserProfile } from '@/lib/contracts'
import { useCurrentAccount } from '@mysten/dapp-kit'
import { useEffect, useState } from 'react'
import { CategorizedObjects, calculateTotalBalance, formatBalance, getCoinIDList } from '@/utils/assetsHelpers'
import { buyWildCoin, getWildCoinCirculation, sellWildCoin } from '@/lib/wildCoin' // 导入获取WildCoinCirculation的函数
import { abandonNft, adoptNft, claimReward, getNftMintCount } from '@/lib/nft' // 导入获取NftMintCount的函数
import { getCurrentRewardAmount } from '@/lib/rewards' // 导入获取CurrentRewardAmount的函数
import { getNfts } from '@/lib/nft' // 导入获取NFT数据的函数
import { OBJECT_IDS } from '@/config/constants'

export interface Nft {
  id: string;
  imageUrl: string;
  name: string;
  reward?: string; // 可选属性，用于存储奖励信息
}

export default function Home() {
  const account = useCurrentAccount();
  const [userObjects, setUserObjects] = useState<CategorizedObjects | null>(null);
  const [wildCoinCirculation, setWildCoinCirculation] = useState<string | null>(null);
  const [nftMintCount, setNftMintCount] = useState<string | null>(null);
  const [currentRewardAmount, setCurrentRewardAmount] = useState<string | null>(null);
  const [nfts, setNfts] = useState<Nft[]>([]); 
  const [showBuyModal, setShowBuyModal] = useState(false);
  const [showSellModal, setShowSellModal] = useState(false);
  const [buyAmount, setBuyAmount] = useState('');
  const [sellAmount, setSellAmount] = useState('');
  const { mutate: signAndExecuteTransaction } = useSignAndExecuteTransaction();
  useEffect(() => {
    async function fetchUserProfile() {
      if (account?.address) {
        try {
          const profile = await getUserProfile(account.address);
          console.log(profile)
          setUserObjects(profile);
          setWildCoinCirculation(await getWildCoinCirculation()); // 使用获取WildCoinCirculation的函数
          setNftMintCount(await getNftMintCount()); // 使用获取NftMintCount的函数
          setCurrentRewardAmount(await getCurrentRewardAmount()); // 使用获取CurrentRewardAmount的函数
          setNfts(await getNfts()); // 使用获取NFT数据的函数
          //setSuiBalance(profile.coins['0x2::sui::SUI'].reduce((sum, coin) => sum + coin.balance, 0)); // 假设 SUI 余额是从 profile 中获取的
        } catch (error) {
          console.error('Error fetching user profile:', error);
        }
      }
    }

    fetchUserProfile();
  }, [account]);

  const handleBuyWild = () => {
    setShowBuyModal(true);
  };

  const handleSellWild = () => {
    setShowSellModal(true);
  };

  const handleSuiMax = () => {
    if (userObjects && userObjects.coins['0x2::sui::SUI']) {
      const totalBalance = calculateTotalBalance(userObjects.coins['0x2::sui::SUI']);
      setBuyAmount(formatBalance(totalBalance));
    }
  };

  const handleWildMax = () => {
    if (userObjects && userObjects.coins[OBJECT_IDS.package_id + '::wild_coin::WILD_COIN']) {
      const totalBalance = calculateTotalBalance(userObjects.coins[OBJECT_IDS.package_id + '::wild_coin::WILD_COIN']);
      setSellAmount(formatBalance(totalBalance));
    }
  };

  const handleConfirmBuy = async () => {
    if (account?.address) {
      try {
        await buyWildCoin(buyAmount,
          account.address,
          signAndExecuteTransaction,
          async () => {
            if (account?.address) {
              try {
                const profile = await getUserProfile(account.address);
                setUserObjects(profile);
                setWildCoinCirculation(await getWildCoinCirculation()); // 使用获取WildCoinCirculation的函数
                setNftMintCount(await getNftMintCount()); // 使用获取NftMintCount的函数
                setCurrentRewardAmount(await getCurrentRewardAmount()); // 使用获取CurrentRewardAmount的函数
                setNfts(await getNfts()); // 使用获取NFT数据的函数
                //setSuiBalance(profile.coins['0x2::sui::SUI'].reduce((sum, coin) => sum + coin.balance, 0)); // 假设 SUI 余额是从 profile 中获取的
              } catch (error) {
                console.error('Error fetching user profile:', error);
              }
            }
          });

        setShowBuyModal(false);
        setBuyAmount('');
      } catch (error) {
        console.error('Error confirming buy:', error);
      }
    }
  };

  const handleConfirmSell = async () => {
    if (userObjects && userObjects.coins[OBJECT_IDS.package_id + '::wild_coin::WILD_COIN']) {
      const coin_id_list = getCoinIDList(userObjects.coins[OBJECT_IDS.package_id + '::wild_coin::WILD_COIN']);
      if (account?.address) {
        try {

          await sellWildCoin(
            coin_id_list,
            sellAmount,
            account.address,
            signAndExecuteTransaction,
            async () => {
              if (account?.address) {
                try {
                  const profile = await getUserProfile(account.address);
                  setUserObjects(profile);
                  setWildCoinCirculation(await getWildCoinCirculation()); // 使用获取WildCoinCirculation的函数
                  setNftMintCount(await getNftMintCount()); // 使用获取NftMintCount的函数
                  setCurrentRewardAmount(await getCurrentRewardAmount()); // 使用获取CurrentRewardAmount的函数
                  setNfts(await getNfts()); // 使用获取NFT数据的函数
                  //setSuiBalance(profile.coins['0x2::sui::SUI'].reduce((sum, coin) => sum + coin.balance, 0)); // 假设 SUI 余额是从 profile 中获取的
                } catch (error) {
                  console.error('Error fetching user profile:', error);
                }
              }

            }
          );
        } catch (error) {
          console.error('Error confirming sell:', error);
        }
      }
      setShowSellModal(false);
      setSellAmount('');
    }
  };

  const handleAdoptNft = async (nftId: string) => {
    if (account?.address) {
      try {
        if (userObjects && userObjects.coins[OBJECT_IDS.package_id + '::wild_coin::WILD_COIN']) {
          const coin_id_list = getCoinIDList(userObjects.coins[OBJECT_IDS.package_id + '::wild_coin::WILD_COIN']);
          await adoptNft(
            coin_id_list,
            nftId,
            account.address,
            signAndExecuteTransaction,
            async () => {
              if (account?.address) {
                try {
                  const profile = await getUserProfile(account.address);
                  setUserObjects(profile);
                  setWildCoinCirculation(await getWildCoinCirculation()); // 使用获取WildCoinCirculation的函数
                  setNftMintCount(await getNftMintCount()); // 使用获取NftMintCount的函数
                  setCurrentRewardAmount(await getCurrentRewardAmount()); // 使用获取CurrentRewardAmount的函数
                  setNfts(await getNfts()); // 使用获取NFT数据的函数
                  //setSuiBalance(profile.coins['0x2::sui::SUI'].reduce((sum, coin) => sum + coin.balance, 0)); // 假设 SUI 余额是从 profile 中获取的
                } catch (error) {
                  console.error('Error fetching user profile:', error);
                }
              }
              console.log('NFT adopted successfully');
            }
          );
        }
      } catch (error) {
        console.error('Error adopting NFT:', error);
      }
    }
  };

  const handleClaimReward = async (nftId: {id:string}) => {
    if (account?.address) {
      await claimReward(
        nftId,
        account.address,
        signAndExecuteTransaction,
        async () => {
          if (account?.address) {
            try {
              const profile = await getUserProfile(account.address);
              setUserObjects(profile);
              setWildCoinCirculation(await getWildCoinCirculation()); // 使用获取WildCoinCirculation的函数
              setNftMintCount(await getNftMintCount()); // 使用获取NftMintCount的函数
              setCurrentRewardAmount(await getCurrentRewardAmount()); // 使用获取CurrentRewardAmount的函数
              setNfts(await getNfts()); // 使用获取NFT数据的函数
              //setSuiBalance(profile.coins['0x2::sui::SUI'].reduce((sum, coin) => sum + coin.balance, 0)); // 假设 SUI 余额是从 profile 中获取的
            } catch (error) {
              console.error('Error fetching user profile:', error);
            }
          }
          console.log('claim reward successfully');
        }
      );
    }
  }

  const handleAbandonNft = async (nftId: {id:string}) => {
    if (account?.address) {
      await abandonNft(
        nftId,
        account.address,
        signAndExecuteTransaction,
        async () => {
          if (account?.address) {
            try {
              const profile = await getUserProfile(account.address);
              setUserObjects(profile);
              setWildCoinCirculation(await getWildCoinCirculation()); // 使用获取WildCoinCirculation的函数
              setNftMintCount(await getNftMintCount()); // 使用获取NftMintCount的函数
              setCurrentRewardAmount(await getCurrentRewardAmount()); // 使用获取CurrentRewardAmount的函数
              setNfts(await getNfts()); // 使用获取NFT数据的函数
              //setSuiBalance(profile.coins['0x2::sui::SUI'].reduce((sum, coin) => sum + coin.balance, 0)); // 假设 SUI 余额是从 profile 中获取的
            } catch (error) {
              console.error('Error fetching user profile:', error);
            }
          }
          console.log('NFT abandon successfully');
        }
      );
    }
  }

  const handleCancelBuy = () => {
    setShowBuyModal(false);
    setBuyAmount('');
  };

  const handleCancelSell = () => {
    setShowSellModal(false);
    setSellAmount('');
  };

  return (
    <div className="min-h-screen flex flex-col animated-gradient-bg">
      <header className="flex justify-between items-center p-4 header-bg">
        <div className="flex items-center rounded-full overflow-hidden">
          <Image src="/logo/logo.jpg" alt="Sui Logo" width={80} height={40} />
        </div>
        <ConnectButton className="text-white" />
      </header>
      <main className="flex-grow flex flex-col items-center p-8">

        {userObjects != null ? (
          <div className="w-full max-w-6xl">
            <div className="w-full max-w-6xl mb-8">
              <h2 className="text-2xl font-bold mb-4 text-white">Dashboard</h2>
              <div className="grid grid-cols-3 gap-8">
                <div className="flex-1 p-4 card-bg">
                  <h3 className="text-xl font-semibold mb-2 text-gray-700">Wild Coin Circulation</h3>
                  <p className="text-lg text-gray-600">{wildCoinCirculation}</p>
                </div>
                <div className="flex-1 p-4 card-bg">
                  <h3 className="text-xl font-semibold mb-2 text-gray-700">NFT Mint Count</h3>
                  <p className="text-lg text-gray-600">{nftMintCount}</p>
                </div>
                <div className="flex-1 p-4 card-bg">
                  <h3 className="text-xl font-semibold mb-2 text-gray-700">Current Reward Amount</h3>
                  <p className="text-lg text-gray-600">{currentRewardAmount}</p>
                </div>
              </div>
            </div>
            <div className="w-full max-w-6xl mb-8">
              <h2 className="text-2xl font-bold mb-4 text-white">NFT Showcase</h2>
              <div className="grid grid-cols-3 gap-8">
                {nfts.map(nft => (
                  <div key={nft.id} className="flex flex-col items-center p-4 card-bg">
                    <img src={nft.imageUrl} alt={nft.name} className="w-full h-64 object-cover rounded-t-lg" />
                    <h3 className="text-xl font-semibold mt-4 text-gray-700">{nft.name}</h3>
                    <button className="mt-4 btn btn-primary" onClick={() => handleAdoptNft(nft.id)}>
                      Adopt
                    </button>
                  </div>
                ))}
              </div>
            </div>
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-2xl font-bold text-white">Your Assets</h2>
              <div className="flex space-x-4">
                <button className="btn btn-success" onClick={handleBuyWild}>Buy wild</button>
                <button className="btn btn-danger" onClick={handleSellWild}>Sell Wild</button>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-8">
              <div className="flex-1">
                <h3 className="text-xl font-semibold mb-2 text-gray-700">Coins</h3>
                {Object.entries(userObjects.coins).map(([coinType, coins]) => {
                  const totalBalance = calculateTotalBalance(coins);
                  return (
                    <div key={coinType} className="mb-4 p-4 card-bg">
                      <h4 className="font-medium text-lg text-gray-600">{coinType.split('::').pop()}</h4>
                      <p className="text-gray-500">Total Balance: {formatBalance(totalBalance)}</p>
                    </div>
                  );
                })}
              </div>
              <div className="flex-1">
                <h3 className="text-xl font-semibold mb-2 text-gray-700">Adopted</h3>
                <div className="h-[500px] overflow-y-auto pr-4">
                  {Object.entries(userObjects.objects).map(([objectType, objects]) => (
                    <div key={objectType} className="mb-4 p-4 card-bg">
                      <p className="text-gray-500">Count: {objects.length}</p>
                      <ul className="list-disc list-inside">
                        {objects.map((obj, index) => {
                          const content = obj.data?.content;
                          if (!content || !('fields' in content)) return null;
                          const fields = content.fields;
                          if (!fields || !('create_time' in fields)) return null;
                          const createTime = new Date(Number(fields.create_time)).toLocaleDateString(); return (
                            <li key={index} className="mb-2 flex items-center justify-between">
                              <div className="flex items-center">
                                <img
                                  src={typeof fields.image_url === 'string' ? fields.image_url : '/default-image.jpg'}
                                  alt={typeof fields.name === 'string' ? fields.name : 'Unknown'}
                                  className="w-24 h-24 object-cover rounded-lg mr-4"
                                />                            <div className="bg-gray-200 p-2 rounded-lg overflow-x-auto">
                                  <p className="text-sm text-gray-600"><strong>Create Time:</strong> {createTime}</p>
                                  <p className="text-sm text-gray-600"><strong>Name:</strong> {typeof fields.name === 'string' ? fields.name : 'Unknown'}</p>
                                  <p className="text-sm text-gray-600"><strong>Species:</strong> {typeof fields.species === 'string' ? fields.species : 'Unknown'}</p>
                                  {obj.data && 'reward' in obj.data && <p className="text-sm text-gray-600"><strong>Reward:</strong> {obj.data.reward as string}</p>}
                                  </div>
                              </div>
                              <div className="flex space-x-4">
                                <button className="btn btn-danger" onClick={() => handleClaimReward(fields.id as {id:string})}>
                                  Claim
                                </button>
                                <button className="btn btn-danger" onClick={() => handleAbandonNft(fields.id as {id:string})}>
                                  Abandon
                                </button>
                              </div>
                            </li>
                          );
                        })}
                      </ul>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        ) : (
          <div className="flex-grow flex flex-col items-center p-8">
            <h1 className="text-4xl font-bold text-white mb-8">Welcome to Animal Conservation</h1>
            <h3 className="text-2xl font-bold text-white mb-8">Please connect your wallet to view your assets</h3>
          </div>
        )}
      </main>

      {showBuyModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center">
          <div className="bg-white p-8 rounded-lg">
            <h3 className="text-xl font-semibold mb-4">买入wild</h3>
            <input
              type="text"
              className="w-full p-2 border border-gray-300 rounded-lg mb-4"
              placeholder="输入Sui金额"
              value={buyAmount}
              onChange={(e) => setBuyAmount(e.target.value)}
            />
            <button className="btn btn-primary mr-4" onClick={handleSuiMax}>Max</button>
            <button className="btn btn-success mr-4" onClick={handleConfirmBuy}>确认</button>
            <button className="btn btn-danger" onClick={handleCancelBuy}>取消</button>
          </div>
        </div>
      )}

      {showSellModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex justify-center items-center">
          <div className="bg-white p-8 rounded-lg">
            <h3 className="text-xl font-semibold mb-4">sell wild</h3>
            <input
              type="text"
              className="w-full p-2 border border-gray-300 rounded-lg mb-4"
              placeholder="输入Wild金额"
              value={sellAmount}
              onChange={(e) => setSellAmount(e.target.value)}
            />
            <button className="btn btn-primary mr-4" onClick={handleWildMax}>Max</button>
            <button className="btn btn-success mr-4" onClick={handleConfirmSell}>确认</button>
            <button className="btn btn-danger" onClick={handleCancelSell}>取消</button>
          </div>
        </div>
      )}
    </div>
  );
}