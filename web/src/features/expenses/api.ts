import {
  ExpensesApi,
  type ExpenseResponse,
  type ExpenseWriteRequest,
} from "../../generated/api";
import { getCsrfToken } from "../../core/http-client";
import { apiConfiguration } from "../../app/api-client";

export type ExpenseReadScope =
  | "all"
  | "general"
  | { outingId: string; scope?: never }
  | { scope: "all" | "general"; outingId?: never }
  | { scope: "outing"; outingId: string };

export interface ExpenseFeatureClient {
  listExpenses: (
    groupId: string,
    scope?: ExpenseReadScope,
  ) => Promise<ExpenseResponse[]>;
  createExpense: (
    groupId: string,
    request: ExpenseWriteRequest,
  ) => Promise<ExpenseResponse>;
  editExpense: (
    groupId: string,
    expenseId: string,
    request: ExpenseWriteRequest,
  ) => Promise<ExpenseResponse>;
  deleteExpense: (groupId: string, expenseId: string) => Promise<void>;
}

const expensesApi = new ExpensesApi(apiConfiguration);

function expenseReadRequest(
  groupId: string,
  scope?: ExpenseReadScope,
): Parameters<ExpensesApi["listExpensesApiV1GroupsGroupIdExpensesGet"]>[0] {
  if (scope === undefined) return { groupId };
  if (typeof scope === "string") return { groupId, scope };
  if ("scope" in scope) {
    if (scope.scope === "outing") {
      return { groupId, outingId: scope.outingId };
    }
    return { groupId, scope: scope.scope };
  }
  return { groupId, outingId: scope.outingId };
}

export const generatedExpenseClient: ExpenseFeatureClient = {
  listExpenses: (groupId, scope) =>
    expensesApi.listExpensesApiV1GroupsGroupIdExpensesGet(
      expenseReadRequest(groupId, scope),
    ),
  createExpense: (groupId, request) =>
    expensesApi.createExpenseApiV1GroupsGroupIdExpensesPost({
      groupId,
      xCSRFToken: getCsrfToken() ?? "",
      expenseWriteRequest: request,
    }),
  editExpense: (groupId, expenseId, request) =>
    expensesApi.editExpenseApiV1GroupsGroupIdExpensesExpenseIdPatch({
      groupId,
      expenseId,
      xCSRFToken: getCsrfToken() ?? "",
      expenseWriteRequest: request,
    }),
  deleteExpense: (groupId, expenseId) =>
    expensesApi.deleteExpenseApiV1GroupsGroupIdExpensesExpenseIdDelete({
      groupId,
      expenseId,
      xCSRFToken: getCsrfToken() ?? "",
    }),
};
