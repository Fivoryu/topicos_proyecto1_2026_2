import { BalancesApi, type BalancesResponse } from "../../generated/api";
import { apiConfiguration } from "../../app/api-client";

export interface BalanceFeatureClient {
  getBalances: (
    groupId: string,
    outingId?: string | null,
  ) => Promise<BalancesResponse>;
}

const balancesApi = new BalancesApi(apiConfiguration);

export const generatedBalanceClient: BalanceFeatureClient = {
  getBalances: (groupId, outingId) =>
    balancesApi.getBalancesApiV1GroupsGroupIdBalancesGet(
      outingId == null ? { groupId } : { groupId, outingId },
    ),
};
