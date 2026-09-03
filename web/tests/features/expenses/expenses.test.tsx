import { QueryClient } from "@tanstack/react-query";
import {
  fireEvent,
  render,
  screen,
  waitFor,
  within,
} from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import {
  ExpensesPanel,
  type ExpenseFeatureClient,
} from "../../../src/features/expenses";
import {
  type AuthClient,
  SessionProvider,
} from "../../../src/app/auth/session-provider";
import type {
  ExpenseResponse,
  ParticipantResponse,
  SessionIdentityResponse,
} from "../../../src/generated/api";

const session: SessionIdentityResponse = {
  account: { id: "member-1", loginName: "demo.member" },
  activeGroupId: "group-demo",
  expiresAt: new Date("2026-08-29T12:00:00.000Z"),
  role: "member",
};

const participants: ParticipantResponse[] = [
  { id: "p1", groupId: "group-demo", name: "Ana", archived: false },
  { id: "p2", groupId: "group-demo", name: "Beto", archived: true },
  { id: "p3", groupId: "group-demo", name: "Carla", archived: false },
];

const expense: ExpenseResponse = {
  id: "e1",
  groupId: "group-demo",
  description: "Dinner",
  amountCents: 10000,
  contributors: [
    { participantId: "p1", name: "Ana", archived: false, amountCents: 6000 },
    { participantId: "p2", name: "Beto", archived: true, amountCents: 4000 },
  ],
  beneficiaries: [
    { participantId: "p1", name: "Ana", archived: false },
    { participantId: "p2", name: "Beto", archived: true },
    { participantId: "p3", name: "Carla", archived: false },
  ],
};

function authClient(): AuthClient {
  return {
    getSession: vi.fn().mockResolvedValue(session),
    login: vi.fn().mockResolvedValue(session),
    logout: vi.fn().mockResolvedValue(undefined),
  };
}

function participantClient() {
  return { listParticipants: vi.fn().mockResolvedValue(participants) };
}

function baseClient(): ExpenseFeatureClient {
  return {
    listExpenses: vi.fn().mockResolvedValue([expense]),
    createExpense: vi.fn().mockResolvedValue(expense),
    editExpense: vi.fn().mockResolvedValue(expense),
    deleteExpense: vi.fn().mockResolvedValue(undefined),
  };
}

function renderPanel(
  client: ExpenseFeatureClient,
  participantsClient = participantClient(),
  queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  }),
) {
  return {
    queryClient,
    ...render(
      <SessionProvider authClient={authClient()} queryClient={queryClient}>
        <ExpensesPanel
          client={client}
          participantsClient={participantsClient}
        />
      </SessionProvider>,
    ),
  };
}

describe("expenses panel", () => {
  it("defaults new beneficiaries to active participants and sends decimal strings for contributors", async () => {
    const client = baseClient();
    client.listExpenses = vi.fn().mockResolvedValue([]);
    renderPanel(client);

    expect(
      await screen.findByRole("heading", { name: "Gastos" }),
    ).toBeInTheDocument();
    expect(screen.getByLabelText(/beneficiario Ana/i)).toBeChecked();
    expect(screen.getByLabelText(/beneficiario Carla/i)).toBeChecked();
    expect(
      screen.queryByLabelText(/beneficiario Beto/i),
    ).not.toBeInTheDocument();

    fireEvent.change(screen.getByLabelText(/descripción del gasto/i), {
      target: { value: "Lunch" },
    });
    fireEvent.change(screen.getByLabelText(/monto del gasto/i), {
      target: { value: "10.00" },
    });
    fireEvent.change(screen.getByLabelText(/^pagador 1$/i), {
      target: { value: "p1" },
    });
    fireEvent.change(screen.getByLabelText(/monto del pagador 1/i), {
      target: { value: "6.00" },
    });
    fireEvent.click(screen.getByRole("button", { name: /agregar pagador/i }));
    fireEvent.change(screen.getByLabelText(/^pagador 2$/i), {
      target: { value: "p3" },
    });
    fireEvent.change(screen.getByLabelText(/monto del pagador 2/i), {
      target: { value: "4" },
    });
    fireEvent.click(screen.getByRole("button", { name: /crear gasto/i }));

    await waitFor(() =>
      expect(client.createExpense).toHaveBeenCalledWith("group-demo", {
        description: "Lunch",
        amount: "10.00",
        contributors: [
          { participantId: "p1", amount: "6.00" },
          { participantId: "p3", amount: "4" },
        ],
        beneficiaryIds: ["p1", "p3"],
      }),
    );
  });

  it("keeps an over-precise amount editable and does not mutate", async () => {
    const client = baseClient();
    client.listExpenses = vi.fn().mockResolvedValue([]);
    renderPanel(client);

    const amount = await screen.findByLabelText(/monto del gasto/i);
    fireEvent.change(amount, { target: { value: "10.001" } });
    fireEvent.click(screen.getByRole("button", { name: /crear gasto/i }));

    expect(client.createExpense).not.toHaveBeenCalled();
    expect(amount).toHaveValue("10.001");
    expect(amount).toHaveAttribute("aria-invalid", "true");
    expect(screen.getByRole("alert")).toHaveTextContent(/invalid_amount/i);
  });

  it("guides an empty group to add participants before creating an expense", async () => {
    const client = baseClient();
    client.listExpenses = vi.fn().mockResolvedValue([]);
    const emptyParticipants = {
      listParticipants: vi.fn().mockResolvedValue([]),
    };
    renderPanel(client, emptyParticipants);

    expect(
      await screen.findByText(/agrega participantes/i),
    ).toBeInTheDocument();
    expect(
      screen.queryByRole("button", { name: /crear gasto/i }),
    ).not.toBeInTheDocument();
    expect(client.createExpense).not.toHaveBeenCalled();
  });

  it("keeps referenced archived participants in an edit form", async () => {
    const client = baseClient();
    renderPanel(client);

    const row = await screen.findByTestId("expense-e1");
    expect(within(row).getByText("Bs. 100,00")).toBeInTheDocument();
    expect(within(row).getByText(/pagado por Ana, Beto \(archivado\)/i)).toBeInTheDocument();
    fireEvent.click(within(row).getByRole("button", { name: /editar gasto/i }));

    const archivedBeneficiary =
      await screen.findByLabelText(/beneficiario Beto/i);
    expect(archivedBeneficiary).toBeChecked();
    expect(archivedBeneficiary).not.toBeDisabled();
    expect(screen.getByDisplayValue("Dinner")).toBeInTheDocument();
  });

  it("binds a server contribution mismatch to the editable form without changing the list", async () => {
    const client = baseClient();
    client.createExpense = vi.fn().mockRejectedValue(
      Object.assign(
        new Error("Contributions do not match the expense amount."),
        {
          errorCode: "contribution_mismatch",
        },
      ),
    );
    client.listExpenses = vi.fn().mockResolvedValue([]);
    renderPanel(client);

    const description = await screen.findByLabelText(/descripción del gasto/i);
    fireEvent.change(description, { target: { value: "Dinner" } });
    fireEvent.change(screen.getByLabelText(/monto del gasto/i), {
      target: { value: "10.00" },
    });
    fireEvent.click(screen.getByRole("button", { name: /crear gasto/i }));

    expect(await screen.findByRole("alert")).toHaveTextContent(
      /contribution_mismatch/i,
    );
    expect(description).toHaveValue("Dinner");
    expect(screen.queryByTestId("expense-e1")).not.toBeInTheDocument();
  });
});
