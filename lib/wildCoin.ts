import { suiClient } from "@/config";
import { OBJECT_IDS } from "@/config/constants";
import { Transaction } from "@mysten/sui/transactions";


export async function getWildCoinCirculation(): Promise<string> {
  const response = await suiClient.getObject({ id: OBJECT_IDS.Wild_Supply, options: { showContent: true } });
  if (response.data && response.data.content && "fields" in response.data.content) {
    const fields = response.data.content.fields as { [key: string]: any };
    const wild_coin_Fields: {
      circulating_supply?: number;
      current_unfrozen_supply: number;
    } = {
      circulating_supply: fields.circulating_supply,
      current_unfrozen_supply: fields.current_unfrozen_supply,
    };
    return wild_coin_Fields.circulating_supply?.toString() ?? "0";;
  }
  const wildCoinCirculation = "无数据";
  return wildCoinCirculation;
}

export async function buyWildCoin(
  amount: string,
  accountAddress: string,
  signAndExecuteTransaction: any,
  onSuccess: () => void): Promise<void> {
  console.log(`Buying ${amount} WildCoin for account ${accountAddress}`);
  const tx = new Transaction();
  tx.setSender(accountAddress);
  try {
    const amountInToken = Math.floor(parseFloat(amount) * 1_000_000_000);
    const splitCoin = tx.splitCoins(tx.gas, [amountInToken]);
    tx.moveCall({
      arguments: [
        tx.object(OBJECT_IDS.TreasuryCap),
        tx.object(OBJECT_IDS.WildVault),
        tx.object(OBJECT_IDS.Wild_Supply),
        splitCoin,
        tx.pure.address(accountAddress),
      ],
      target: `${OBJECT_IDS.package_id}::wild_coin::mint_wild`,
    });
    await signAndExecuteTransaction({
      transaction: tx
    },
      {
        onSuccess: async ({ digest }: { digest: string }) => {
          await suiClient.waitForTransaction({
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
    console.error('Error buying WildCoin:', error);
  }
}

export async function sellWildCoin(
  id_list: string[],
  amount: string,
  accountAddress: string,
  signAndExecuteTransaction: any,
  onSuccess: () => void
): Promise<void> {
  console.log(`Selling ${amount} WildCoin for account ${accountAddress}`);
  const tx = new Transaction();
  tx.setSender(accountAddress);
  try {
    tx.mergeCoins(tx.object(id_list[0]), id_list.slice(1).map(id => tx.object(id)));
    const amountInToken = Math.floor(parseFloat(amount) * 1_000_000_000);
    const splitCoin = tx.splitCoins(tx.object(id_list[0]), [amountInToken]);
    tx.moveCall({
      arguments: [
        tx.object(OBJECT_IDS.TreasuryCap),
        tx.object(OBJECT_IDS.Wild_Supply),
        tx.object(OBJECT_IDS.WildVault),
        splitCoin,
        tx.pure.address(accountAddress),
      ],
      target: `${OBJECT_IDS.package_id}::wild_coin::swap_wild_coin_for_sui`,
    });
    await signAndExecuteTransaction({
      transaction: tx
    },
      {
        onSuccess: async ({ digest }: { digest: string }) => {
          await suiClient.waitForTransaction({
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
    console.error('Error selling WildCoin:', error);
  }
}