import { SettlementApi, type SettlementResponse } from "../../generated/api";
import { apiConfiguration } from "../../app/api-client";

export interface SettlementFeatureClient {
  getSettlement: (groupId: string) => Promise<SettlementResponse>;
}

const settlementApi = new SettlementApi(apiConfiguration);

export const generatedSettlementClient: SettlementFeatureClient = {
  getSettlement: (groupId) =>
    settlementApi.getSettlementApiV1GroupsGroupIdSettlementGet({ groupId }),
};
