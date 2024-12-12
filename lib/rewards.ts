import { suiClient } from "@/config";
import { OBJECT_IDS } from "@/config/constants";

export async function getCurrentRewardAmount(): Promise<string> {
    const response = await suiClient.getObject({ id: OBJECT_IDS.WildVault, options: { showContent: true } });
    if (response.data && response.data.content && "fields" in response.data.content) {
        const fields = response.data.content.fields as { [key: string]: any };
        const reward_Fields: {
            reward_sui_blance?: number;
        } = {
            reward_sui_blance: fields.reward_sui_blance,
        };
        return reward_Fields.reward_sui_blance?.toString() ?? "0";
    }
    return "无数据";
  }