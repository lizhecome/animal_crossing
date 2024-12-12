import { OBJECT_IDS } from "@/config/constants";
import { SuiObjectData, SuiObjectResponse } from "@mysten/sui/client";
import { suiClient } from "@/config";
import { isValidSuiAddress } from "@mysten/sui/utils";

interface SuiObjectDataWithReward extends SuiObjectData {
  reward: string;
}
export interface CategorizedObjects {
  coins: {
    [coinType: string]: SuiObjectResponse[];
  };
  objects: {
    [objectType: string]: SuiObjectResponse[];
  };
}

export interface Balance {
  integer: bigint;
  decimal: string;
}

export const categorizeSuiObjects = (objects: SuiObjectResponse[]): CategorizedObjects => {
  return objects.reduce((acc: CategorizedObjects, obj) => {
    const content = obj.data?.content;
    if (content?.dataType !== "moveObject") {
      return acc;
    }

    const type = content.type;
    if (type.startsWith("0x2::coin::Coin<0x2::sui::SUI") || type.startsWith("0x2::coin::Coin<"+OBJECT_IDS.package_id)) {
      const coinType = type.match(/<(.+)>/)?.[1] || "Unknown";
      if (!acc.coins[coinType]) {
        acc.coins[coinType] = [];
      }
      acc.coins[coinType].push(obj);
    } else {
      if (!type.startsWith(OBJECT_IDS.package_id+"::wild_NFT::AnimalNFT")){
        return acc;
      }
      if (!acc.objects[type]) {
        acc.objects[type] = [];
      }
      console.log(obj)
      acc.objects[type].push(obj);
    }
    
    if (obj.data && obj.data.objectId) {
       getFormatBalance(obj.data.objectId).then((result)=>{
        (obj.data as SuiObjectDataWithReward).reward = result;
      });
    }
    return acc;
  }, { coins: {}, objects: {} });
};

export const getFormatBalance = async (address:string): Promise<string> => {
  return formatBalance(calculateTotalBalance(await getSuiAssert(address)));
};

export const calculateTotalBalance = (coins: SuiObjectResponse[]): Balance => {
  const total = coins.reduce((sum, coin) => {
    if (coin.data && 'content' in coin.data) {
      const content = coin.data.content;

      if (content && content.dataType === 'moveObject' && 'fields' in content) {
        const fields = content.fields as { balance?: string };
        if ('balance' in fields) {
          const balance = BigInt(fields.balance || '0');
          return sum + balance;
        }
      }
    }
    return sum;
  }, BigInt(0));

  const integer = total / BigInt(10 ** 9);
  const decimal = (total % BigInt(10 ** 9)).toString().padStart(9, '0');
  
  return { integer, decimal };
};

export const getCoinIDList = (coins: SuiObjectResponse[]): string[] => {
  return coins.reduce((list, coin) => {
    if (coin.data && 'content' in coin.data) {
      const content = coin.data.content;
      if (content && content.dataType === 'moveObject' && 'fields' in content) {
        const fields = content.fields as { id?: { id: string } };
        if ('id' in fields) {
          const id = fields.id?.id;
          if (id !== undefined) {
            list.push(id);
          }
        }
      }
    }
    return list;
  }, [] as string[]);
};

export const formatBalance = (balance: Balance, decimalPlaces: number = 9): string => {
  const integerPart = balance.integer.toString();
  const decimalPart = balance.decimal.slice(0, decimalPlaces);
  return `${integerPart}.${decimalPart}`;
};

export const getSuiAssert = async (address: string): Promise<SuiObjectResponse[]> => {
  if (!isValidSuiAddress(address)) {
    throw new Error("Invalid Sui address");
  }

  let hasNextPage = true;
  let nextCursor: string | null = null;
  let allObjects: SuiObjectResponse[] = [];

  while (hasNextPage) {
    const response = await suiClient.getOwnedObjects({
      owner: address,
      options: {
        showContent: true,
      },
      cursor: nextCursor,
    });

    allObjects = allObjects.concat(response.data);
    hasNextPage = response.hasNextPage;
    nextCursor = response.nextCursor ?? null;
  }

  const suiAssets = allObjects.filter(obj => {
    if (obj.data && 'content' in obj.data) {
      const content = obj.data.content;
      return content && content.dataType === 'moveObject' && 'fields' in content && content.type === '0x2::coin::Coin<0x2::sui::SUI>';
    }
    return false;
  });

  return suiAssets;
};
