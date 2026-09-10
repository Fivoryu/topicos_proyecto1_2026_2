import { SettlementApi, type SettlementResponse } from "../../generated/api";
import { apiConfiguration } from "../../app/api-client";

export interface SettlementFeatureClient {
  getSettlement: (
    groupId: string,
    outingId?: string | null,
  ) => Promise<SettlementResponse>;
}

const settlementApi = new SettlementApi(apiConfiguration);

export const generatedSettlementClient: SettlementFeatureClient = {
  getSettlement: (groupId, outingId) =>
    settlementApi.getSettlementApiV1GroupsGroupIdSettlementGet(
      outingId == null ? { groupId } : { groupId, outingId },
    ),
};
