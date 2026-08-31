import { BalancesApi, type BalancesResponse } from "../../generated/api";
import { apiConfiguration } from "../../app/api-client";

export interface BalanceFeatureClient {
  getBalances: (groupId: string) => Promise<BalancesResponse>;
}

const balancesApi = new BalancesApi(apiConfiguration);

export const generatedBalanceClient: BalanceFeatureClient = {
  getBalances: (groupId) =>
    balancesApi.getBalancesApiV1GroupsGroupIdBalancesGet({ groupId }),
};
