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
      await screen.findByRole("heading", { name: "Expenses" }),
    ).toBeInTheDocument();
    expect(screen.getByLabelText(/beneficiary Ana/i)).toBeChecked();
    expect(screen.getByLabelText(/beneficiary Carla/i)).toBeChecked();
    expect(
      screen.queryByLabelText(/beneficiary Beto/i),
    ).not.toBeInTheDocument();

    fireEvent.change(screen.getByLabelText(/expense description/i), {
      target: { value: "Lunch" },
    });
    fireEvent.change(screen.getByLabelText(/expense amount/i), {
      target: { value: "10.00" },
    });
    fireEvent.change(screen.getByLabelText(/contributor 1 participant/i), {
      target: { value: "p1" },
    });
    fireEvent.change(screen.getByLabelText(/contributor 1 amount/i), {
      target: { value: "6.00" },
    });
    fireEvent.click(screen.getByRole("button", { name: /add contributor/i }));
    fireEvent.change(screen.getByLabelText(/contributor 2 participant/i), {
      target: { value: "p3" },
    });
    fireEvent.change(screen.getByLabelText(/contributor 2 amount/i), {
      target: { value: "4" },
    });
    fireEvent.click(screen.getByRole("button", { name: /create expense/i }));

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

    const amount = await screen.findByLabelText(/expense amount/i);
    fireEvent.change(amount, { target: { value: "10.001" } });
    fireEvent.click(screen.getByRole("button", { name: /create expense/i }));

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
      await screen.findByText(/add participants first/i),
    ).toBeInTheDocument();
    expect(
      screen.queryByRole("button", { name: /create expense/i }),
    ).not.toBeInTheDocument();
    expect(client.createExpense).not.toHaveBeenCalled();
  });

  it("keeps referenced archived participants in an edit form", async () => {
    const client = baseClient();
    renderPanel(client);

    const row = await screen.findByTestId("expense-e1");
    fireEvent.click(within(row).getByRole("button", { name: /edit expense/i }));

    const archivedBeneficiary =
      await screen.findByLabelText(/beneficiary Beto/i);
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

    const description = await screen.findByLabelText(/expense description/i);
    fireEvent.change(description, { target: { value: "Dinner" } });
    fireEvent.change(screen.getByLabelText(/expense amount/i), {
      target: { value: "10.00" },
    });
    fireEvent.click(screen.getByRole("button", { name: /create expense/i }));

    expect(await screen.findByRole("alert")).toHaveTextContent(
      /contribution_mismatch/i,
    );
    expect(description).toHaveValue("Dinner");
    expect(screen.queryByTestId("expense-e1")).not.toBeInTheDocument();
  });
});
