import { suiClient } from "@/config";
import { OBJECT_IDS } from "@/config/constants";
import { getSuiAssert } from "@/utils/assetsHelpers";
import { Transaction } from "@mysten/sui/transactions";

export async function getNftMintCount(): Promise<string> {
    const response = await suiClient.getObject({ id: OBJECT_IDS.MintRecord, options: { showContent: true } });
    if (response.data && response.data.content && "fields" in response.data.content) {
        const fields = response.data.content.fields as { [key: string]: any };
        const nft_Fields: {
            count?: number;
        } = {
            count: fields.count,
        };
        return nft_Fields.count?.toString() ?? "0";
    }
    return "无数据";
}

export async function getNfts(): Promise<any[]> {
    const animal_response = await suiClient.getObject({ id: OBJECT_IDS.Animals, options: { showContent: true } });
    let parentId = '';
    if (animal_response.data && animal_response.data.content && "fields" in animal_response.data.content) {
        const fields = animal_response.data.content.fields as { [key: string]: any };
        const nft_Fields: {
            id?: string;
        } = {
            id: fields.animal_infos.fields.id.id,
        };
        parentId = nft_Fields.id?.toString() ?? "0";
    } else {
        return [];
    }
    // 假设我们从某个API或合约中获取NFT数据
    const response = await suiClient.getDynamicFields({
        parentId: parentId
    });
    let nfts = response.data.map((item: any) => ({
        objectId: item.objectId,
    }));
    const nftDetails = await Promise.all(nfts.map(async (nft) => {
        const nftResponse = await suiClient.getObject({ id: nft.objectId, options: { showContent: true } });
        if (nftResponse.data && nftResponse.data.content && "fields" in nftResponse.data.content) {
            const fields = nftResponse.data.content.fields as { [key: string]: any };
            const animal_id = fields.name;
            const valueFields = fields.value.fields;
            return {
                id: animal_id,
                name: valueFields.name,
                imageUrl: valueFields.image_url,
                species: valueFields.species,
                status: valueFields.status,
                habitat: valueFields.habitat,
            };
        }
        return null;
    }));

    let animal = nftDetails.filter(nft => nft !== null);
    return animal;
}

export async function adoptNft(
    id_list: string[],
    key: string,
    accountAddress: string,
    signAndExecuteTransaction: any,
    onSuccess: () => void) {
    const tx = new Transaction();
    tx.setSender(accountAddress);
    try {
        if (id_list.length > 1) {
            tx.mergeCoins(tx.object(id_list[0]), id_list.slice(1).map(id => tx.object(id)));
        }
        
        const amountInToken = Math.floor(1 * 1_000_000_000);
        const splitCoin = tx.splitCoins(tx.object(id_list[0]), [amountInToken]);
        tx.moveCall({
            arguments: [
                tx.object(OBJECT_IDS.Animals),
                tx.pure.u64(key),
                tx.object(OBJECT_IDS.MintRecord),
                splitCoin,
                tx.pure.address(accountAddress),
                tx.object(OBJECT_IDS.clock),
                tx.object(OBJECT_IDS.storage),
                tx.object(OBJECT_IDS.pool_sui),
                tx.object(OBJECT_IDS.WildVault),
                tx.object(OBJECT_IDS.inc_v1),
                tx.object(OBJECT_IDS.inc_v2),
            ],
            target: `${OBJECT_IDS.package_id}::wild_NFT::fund_and_purchase_nft`,
        });
        await signAndExecuteTransaction({
            transaction: tx
        },
            {
                onSuccess: async ({ digest }: { digest: string }) => {
                    const { effects } = await suiClient.waitForTransaction({
                        digest: digest,
                        options: {
                            showEffects: true,
                        },
                    });
                    onSuccess();
                },
                // onError: (error: any) => { // 为 error 参数指定类型
                //     console.error("Transaction failed:", error);
                // },
            }
        );
    } catch (error) {
        console.error('Error adopt Nft:', error);
    }
}

export async function abandonNft(
    nftid:{id:string},
    accountAddress: string,
    signAndExecuteTransaction: any,
    onSuccess: () => void
){
    console.log(nftid);
    const tx = new Transaction();
    tx.setSender(accountAddress);
    try {
        tx.moveCall({
            arguments: [
                tx.object(nftid.id),
                tx.object(OBJECT_IDS.WildVault),
                tx.object(OBJECT_IDS.MintRecord),
                tx.object(OBJECT_IDS.storage),
                tx.object(OBJECT_IDS.pool_sui),
                tx.object(OBJECT_IDS.inc_v1),
                tx.object(OBJECT_IDS.inc_v2),
                tx.object(OBJECT_IDS.clock),
                tx.object(OBJECT_IDS.PriceOracle),
                tx.pure.address(accountAddress),
            ],
            target: `${OBJECT_IDS.package_id}::wild_NFT::abandon_adoption`,
        });
        await signAndExecuteTransaction({
            transaction: tx
        },
            {
                onSuccess: async ({ digest }: { digest: string }) => {
                    const { effects } = await suiClient.waitForTransaction({
                        digest: digest,
                        options: {
                            showEffects: true,
                        },
                    });
                    onSuccess();
                },
                onError: (error: any) => { // 为 error 参数指定类型
                    console.error("Transaction failed:", error);
                },
            }
        );
    } catch (error) {
        console.error('Error selling WildCoin:', error);
    }
}

export async function claimReward(
    nftid:{id:string},
    accountAddress: string,
    signAndExecuteTransaction: any,
    onSuccess: () => void
){
    const tx = new Transaction();
    tx.setSender(accountAddress);
    try {
        const suiCoin = await getSuiAssert(nftid.id)
        if (suiCoin.length === 0) {
            return;
        }

        for (const coin of suiCoin) {
            tx.moveCall({
                arguments: [
                    tx.object(nftid.id),
                    tx.object(coin.data?.objectId ?? ""),
                    tx.pure.address(accountAddress),
                ],
                target: `${OBJECT_IDS.package_id}::wild_NFT::get_airdrop`,
            });
        }

        await signAndExecuteTransaction({
            transaction: tx
        },
            {
                onSuccess: async ({ digest }: { digest: string }) => {
                    const { effects } = await suiClient.waitForTransaction({
                        digest: digest,
                        options: {
                            showEffects: true,
                        },
                    });
                    onSuccess();
                }
            }
        );
    } catch (error) {
        console.error('Error claim reward:', error);
    }
}