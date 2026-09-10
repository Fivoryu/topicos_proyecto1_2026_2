import { BalancesApi, ExpensesApi, OutingsApi, SettlementApi } from "../../src/generated/api";
import {
  generatedBalanceClient,
} from "../../src/features/balances/api";
import { generatedExpenseClient } from "../../src/features/expenses/api";
import { generatedSettlementClient } from "../../src/features/settlement/api";
import { generatedOutingClient } from "../../src/features/outings/api";
import { workspaceQueryKeys } from "../../src/core/workspace-query-keys";
import { afterEach, describe, expect, it, vi } from "vitest";

const outing = {
  id: "outing-1",
  groupId: "group-1",
  name: "Samaipata",
  archived: false,
};

function csrfCookie(): void {
  document.cookie = "cc_csrf=test-csrf";
}

afterEach(() => {
  vi.restoreAllMocks();
  document.cookie = "cc_csrf=; Max-Age=0";
});

describe("scope-aware financial clients", () => {
  it("passes all, general, and exact-outing expense read scopes", async () => {
    const list = vi
      .spyOn(ExpensesApi.prototype, "listExpensesApiV1GroupsGroupIdExpensesGet")
      .mockResolvedValue([]);

    await generatedExpenseClient.listExpenses("group-1");
    await generatedExpenseClient.listExpenses("group-1", "all");
    await generatedExpenseClient.listExpenses("group-1", "general");
    await generatedExpenseClient.listExpenses("group-1", { outingId: "outing-1" });

    expect(list.mock.calls).toEqual([
      [{ groupId: "group-1" }],
      [{ groupId: "group-1", scope: "all" }],
      [{ groupId: "group-1", scope: "general" }],
      [{ groupId: "group-1", outingId: "outing-1" }],
    ]);
  });

  it("keeps mutation payloads backward-compatible and sends CSRF", async () => {
    csrfCookie();
    const create = vi
      .spyOn(ExpensesApi.prototype, "createExpenseApiV1GroupsGroupIdExpensesPost")
      .mockResolvedValue({} as never);
    const edit = vi
      .spyOn(ExpensesApi.prototype, "editExpenseApiV1GroupsGroupIdExpensesExpenseIdPatch")
      .mockResolvedValue({} as never);
    const remove = vi
      .spyOn(ExpensesApi.prototype, "deleteExpenseApiV1GroupsGroupIdExpensesExpenseIdDelete")
      .mockResolvedValue(undefined);
    const request = {
      amount: "100",
      description: "Cena",
      contributors: [],
      beneficiaryIds: [],
    };

    await generatedExpenseClient.createExpense("group-1", request);
    await generatedExpenseClient.editExpense("group-1", "expense-1", request);
    await generatedExpenseClient.deleteExpense("group-1", "expense-1");

    expect(create.mock.calls[0][0]).toMatchObject({
      groupId: "group-1",
      xCSRFToken: "test-csrf",
      expenseWriteRequest: request,
    });
    expect(edit.mock.calls[0][0]).toMatchObject({
      groupId: "group-1",
      expenseId: "expense-1",
      xCSRFToken: "test-csrf",
      expenseWriteRequest: request,
    });
    expect(remove.mock.calls[0][0]).toEqual({
      groupId: "group-1",
      expenseId: "expense-1",
      xCSRFToken: "test-csrf",
    });
  });

  it("keeps group and outing derived reads isolated", async () => {
    const balances = vi
      .spyOn(BalancesApi.prototype, "getBalancesApiV1GroupsGroupIdBalancesGet")
      .mockResolvedValue({} as never);
    const settlement = vi
      .spyOn(SettlementApi.prototype, "getSettlementApiV1GroupsGroupIdSettlementGet")
      .mockResolvedValue({} as never);

    await generatedBalanceClient.getBalances("group-1");
    await generatedBalanceClient.getBalances("group-1", "outing-1");
    await generatedSettlementClient.getSettlement("group-1");
    await generatedSettlementClient.getSettlement("group-1", "outing-1");

    expect(balances.mock.calls).toEqual([
      [{ groupId: "group-1" }],
      [{ groupId: "group-1", outingId: "outing-1" }],
    ]);
    expect(settlement.mock.calls).toEqual([
      [{ groupId: "group-1" }],
      [{ groupId: "group-1", outingId: "outing-1" }],
    ]);
  });

  it("covers outing reads and the complete lifecycle with CSRF on mutations", async () => {
    csrfCookie();
    const list = vi
      .spyOn(OutingsApi.prototype, "listOutingsApiV1GroupsGroupIdOutingsGet")
      .mockResolvedValue([outing]);
    const get = vi
      .spyOn(OutingsApi.prototype, "getOutingApiV1GroupsGroupIdOutingsOutingIdGet")
      .mockResolvedValue(outing);
    const create = vi
      .spyOn(OutingsApi.prototype, "createOutingApiV1GroupsGroupIdOutingsPost")
      .mockResolvedValue(outing);
    const edit = vi
      .spyOn(OutingsApi.prototype, "editOutingApiV1GroupsGroupIdOutingsOutingIdPatch")
      .mockResolvedValue(outing);
    const archive = vi
      .spyOn(OutingsApi.prototype, "archiveOutingApiV1GroupsGroupIdOutingsOutingIdArchivePost")
      .mockResolvedValue(outing);
    const unarchive = vi
      .spyOn(OutingsApi.prototype, "unarchiveOutingApiV1GroupsGroupIdOutingsOutingIdUnarchivePost")
      .mockResolvedValue(outing);
    const remove = vi
      .spyOn(OutingsApi.prototype, "deleteOutingApiV1GroupsGroupIdOutingsOutingIdDelete")
      .mockResolvedValue(undefined);

    await generatedOutingClient.listOutings("group-1");
    await generatedOutingClient.getOuting("group-1", "outing-1");
    await generatedOutingClient.createOuting("group-1", { name: "Samaipata" });
    await generatedOutingClient.editOuting("group-1", "outing-1", { name: "Samaipata" });
    await generatedOutingClient.archiveOuting("group-1", "outing-1");
    await generatedOutingClient.unarchiveOuting("group-1", "outing-1");
    await generatedOutingClient.deleteOuting("group-1", "outing-1");

    expect(list).toHaveBeenCalledWith({ groupId: "group-1" });
    expect(get).toHaveBeenCalledWith({ groupId: "group-1", outingId: "outing-1" });
    expect(create).toHaveBeenCalledWith({
      groupId: "group-1",
      xCSRFToken: "test-csrf",
      outingWriteRequest: { name: "Samaipata" },
    });
    expect(edit).toHaveBeenCalledWith({
      groupId: "group-1",
      outingId: "outing-1",
      xCSRFToken: "test-csrf",
      outingWriteRequest: { name: "Samaipata" },
    });
    expect(archive).toHaveBeenCalledWith({
      groupId: "group-1",
      outingId: "outing-1",
      xCSRFToken: "test-csrf",
    });
    expect(unarchive).toHaveBeenCalledWith({
      groupId: "group-1",
      outingId: "outing-1",
      xCSRFToken: "test-csrf",
    });
    expect(remove).toHaveBeenCalledWith({
      groupId: "group-1",
      outingId: "outing-1",
      xCSRFToken: "test-csrf",
    });
  });
});

describe("financial query identity", () => {
  it("separates group, general, and outing cache identities", () => {
    expect(workspaceQueryKeys.group.expenses("group-1", "all")).not.toEqual(
      workspaceQueryKeys.group.expenses("group-1", "general"),
    );
    expect(workspaceQueryKeys.group.expenses("group-1", "general")).not.toEqual(
      workspaceQueryKeys.group.expenses("group-1", "outing-1"),
    );
    expect(workspaceQueryKeys.group.expenses("group-1", "outing-1")).not.toEqual(
      workspaceQueryKeys.group.expenses("group-2", "outing-1"),
    );
    expect(workspaceQueryKeys.group.balances("group-1")).not.toEqual(
      workspaceQueryKeys.group.balances("group-1", "outing-1"),
    );
    expect(workspaceQueryKeys.group.settlement("group-1")).not.toEqual(
      workspaceQueryKeys.group.settlement("group-1", "outing-1"),
    );
  });
});
