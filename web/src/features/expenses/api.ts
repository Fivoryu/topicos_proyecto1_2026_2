import {
  ExpensesApi,
  type ExpenseResponse,
  type ExpenseWriteRequest,
} from "../../generated/api";
import { getCsrfToken } from "../../core/http-client";
import { apiConfiguration } from "../../app/api-client";

export interface ExpenseFeatureClient {
  listExpenses: (groupId: string) => Promise<ExpenseResponse[]>;
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

export const generatedExpenseClient: ExpenseFeatureClient = {
  listExpenses: (groupId) =>
    expensesApi.listExpensesApiV1GroupsGroupIdExpensesGet({ groupId }),
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
