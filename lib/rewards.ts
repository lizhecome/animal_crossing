import { suiClient } from "@/config";
import { OBJECT_IDS } from "@/config/constants";

export async function getCurrentRewardAmount(): Promise<string> {
    const response = await suiClient.getObject({ id: OBJECT_IDS.WildVault, options: { showContent: true } });
    if (response.data && response.data.content && "fields" in response.data.content) {
        const fields = response.data.content.fields as { [key: string]: any };
        const reward_Fields: {
            scoin_balance?: number;
        } = {
            scoin_balance: fields.scoin_balance,
        };
        return reward_Fields.scoin_balance?.toString() ?? "0";
    }
    return "无数据";
  }