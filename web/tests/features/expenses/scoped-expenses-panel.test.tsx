import { QueryClient } from "@tanstack/react-query";
import { fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { SessionProvider, type AuthClient } from "../../../src/app/auth/session-provider";
import type { ExpenseResponse, SessionIdentityResponse } from "../../../src/generated/api";
import {
  ScopedExpensesPanel,
  type ExpenseFeatureClient,
} from "../../../src/features/expenses";

const session: SessionIdentityResponse = {
  account: { id: "member-1", loginName: "demo.member" },
  activeGroupId: "group-demo",
  expiresAt: new Date("2026-08-29T12:00:00.000Z"),
  role: "member",
};
const expense: ExpenseResponse = {
  id: "expense-1",
  groupId: "group-demo",
  outingId: "outing-1",
  description: "Cabaña",
  amountCents: 12345,
  contributors: [
    { participantId: "p1", name: "Ana", archived: false, amountCents: 10000 },
  ],
  beneficiaries: [
    { participantId: "p1", name: "Ana", archived: false },
    { participantId: "p2", name: "Beto", archived: false },
  ],
};

function authClient(): AuthClient {
  return {
    getSession: vi.fn().mockResolvedValue(session),
    login: vi.fn().mockResolvedValue(session),
    logout: vi.fn().mockResolvedValue(undefined),
  };
}
function client(expenses: ExpenseResponse[]): ExpenseFeatureClient {
  return {
    listExpenses: vi.fn().mockResolvedValue(expenses),
    createExpense: vi.fn(), editExpense: vi.fn(), deleteExpense: vi.fn(),
  };
}
function renderPanel(panel: React.ReactNode, queryClient = new QueryClient({
  defaultOptions: { queries: { retry: false } },
})) {
  return render(
    <SessionProvider authClient={authClient()} queryClient={queryClient}>
      {panel}
    </SessionProvider>,
  );
}

describe("scoped expense views", () => {
  it("renders the group view with server amounts and people", async () => {
    const expenseClient = client([expense]);
    renderPanel(<ScopedExpensesPanel client={expenseClient} scope="group" />);

    expect(await screen.findByRole("heading", { name: "Gastos del grupo" })).toBeInTheDocument();
    expect(screen.getByText("Cabaña")).toBeInTheDocument();
    expect(screen.getByText("Bs. 123,45")).toBeInTheDocument();
    const row = screen.getByTestId("scoped-expense-expense-1");
    expect(row).toHaveTextContent(/Pagado por: Ana/);
    expect(row).toHaveTextContent(/Beneficiarios: Ana, Beto/);
    expect(expenseClient.listExpenses).toHaveBeenCalledWith("group-demo", "all");
  });

  it("uses the general and exact outing scopes as separate protected views", async () => {
    const generalClient = client([{ ...expense, outingId: undefined, description: "Taxi" }]);
    renderPanel(<ScopedExpensesPanel client={generalClient} scope="general" />);
    expect(await screen.findByRole("heading", { name: "Gastos generales" })).toBeInTheDocument();
    expect(generalClient.listExpenses).toHaveBeenCalledWith("group-demo", "general");

    const outingClient = client([expense]);
    renderPanel(
      <ScopedExpensesPanel
        client={outingClient}
        scope={{ outingId: "outing-1", outingName: "Samaipata", archived: true }}
      />,
    );
    expect(await screen.findByRole("heading", { name: "Gastos de Samaipata" })).toBeInTheDocument();
    expect(screen.getByRole("note")).toHaveTextContent(/solo lectura/i);
    expect(outingClient.listExpenses).toHaveBeenCalledWith("group-demo", { outingId: "outing-1" });
  });

  it("rejects a response from another group or outing instead of leaking it", async () => {
    const foreign = { ...expense, groupId: "group-other", description: "Dato ajeno" };
    renderPanel(<ScopedExpensesPanel client={client([foreign])} scope="group" />);
    expect(await screen.findByRole("alert")).toHaveTextContent(/no se pudieron cargar/i);
    expect(screen.queryByText("Dato ajeno")).not.toBeInTheDocument();

    const wrongOuting = { ...expense, description: "Otra salida", outingId: "outing-other" };
    renderPanel(
      <ScopedExpensesPanel client={client([wrongOuting])} scope={{ outingId: "outing-1" }} />,
    );
    await waitFor(() => expect(screen.getAllByRole("alert")).toHaveLength(2));
    expect(screen.queryByText("Otra salida")).not.toBeInTheDocument();
  });

  it("shows a Spanish loading state while the scoped request resolves", async () => {
    let resolve!: (value: ExpenseResponse[]) => void;
    const pending = new Promise<ExpenseResponse[]>((res) => { resolve = res; });
    const expenseClient = client([]);
    expenseClient.listExpenses = vi.fn().mockReturnValue(pending);
    renderPanel(<ScopedExpensesPanel client={expenseClient} scope="group" />);
    expect(await screen.findByRole("status")).toHaveTextContent("Cargando gastos…");
    resolve([]);
  });

  it("shows empty and recoverable error states with refresh", async () => {
    const requests = [vi.fn().mockRejectedValueOnce(new Error("offline")).mockResolvedValueOnce([])];
    const expenseClient = client([]);
    expenseClient.listExpenses = requests[0];
    renderPanel(<ScopedExpensesPanel client={expenseClient} scope="group" />);
    expect(await screen.findByRole("alert")).toHaveTextContent(/no se pudieron cargar/i);
    fireEvent.click(screen.getByRole("button", { name: "Actualizar gastos" }));
    expect(await screen.findByRole("heading", { name: "Gastos del grupo" })).toBeInTheDocument();
    expect(screen.getByRole("status")).toHaveTextContent(/no hay gastos/i);
    expect(within(screen.getByRole("region", { name: "Gastos del grupo" })).getByRole("button", { name: "Actualizar gastos" })).toBeInTheDocument();
  });
});
