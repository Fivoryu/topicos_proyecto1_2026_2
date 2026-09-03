import { QueryClient } from "@tanstack/react-query";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import {
  GroupSettings,
  type GroupFeatureClient,
} from "../../../src/features/group";
import {
  type AuthClient,
  AuthError,
  SessionProvider,
} from "../../../src/app/auth/session-provider";
import type {
  GroupResponse,
  SessionIdentityResponse,
} from "../../../src/generated/api";

const ownerSession: SessionIdentityResponse = {
  account: { id: "owner-1", loginName: "demo.owner" },
  activeGroupId: "group-demo",
  expiresAt: new Date("2026-08-29T12:00:00.000Z"),
  role: "owner" as const,
};

const memberSession: SessionIdentityResponse = {
  ...ownerSession,
  account: { id: "member-1", loginName: "demo.member" },
  role: "member",
};

const group: GroupResponse = {
  id: "group-demo",
  name: "Samaipata",
  ownerAccountId: "owner-1",
  settlementPolicy: "owner_only",
};

const anyMemberGroup: GroupResponse = {
  ...group,
  settlementPolicy: "any_member",
};

function authClient(
  session: SessionIdentityResponse = ownerSession,
): AuthClient {
  return {
    getSession: vi.fn().mockResolvedValue(session),
    login: vi.fn().mockResolvedValue(session),
    logout: vi.fn().mockResolvedValue(undefined),
  };
}

function renderSettings(
  client: GroupFeatureClient,
  session: SessionIdentityResponse = ownerSession,
) {
  return render(
    <SessionProvider
      authClient={authClient(session)}
      queryClient={
        new QueryClient({ defaultOptions: { queries: { retry: false } } })
      }
    >
      <GroupSettings client={client} />
    </SessionProvider>,
  );
}

afterEach(() => {
  vi.restoreAllMocks();
});

describe("group settings", () => {
  it("renders the server-owned group details and lets an owner update policy", async () => {
    const client: GroupFeatureClient = {
      getGroup: vi.fn().mockResolvedValue(group),
      updatePolicy: vi.fn().mockResolvedValue({
        ...group,
        settlementPolicy: "any_member",
      }),
    };

    renderSettings(client);

    expect(
      await screen.findByRole("heading", { name: "Samaipata" }),
    ).toBeInTheDocument();
    expect(screen.getByText(/cuenta propietaria/i)).toBeInTheDocument();
    expect(screen.getByText("owner-1")).toBeInTheDocument();
    expect(screen.getAllByText(/política de liquidación/i)).not.toHaveLength(0);
    expect(screen.getAllByText(/solo propietario/i)).not.toHaveLength(0);

    fireEvent.change(screen.getByLabelText(/política de liquidación/i), {
      target: { value: "any_member" },
    });
    fireEvent.click(screen.getByRole("button", { name: /guardar política/i }));

    await waitFor(() =>
      expect(client.updatePolicy).toHaveBeenCalledWith(
        "group-demo",
        "any_member",
      ),
    );
  });

  it("does not show a policy mutation affordance to a member under owner_only", async () => {
    const client: GroupFeatureClient = {
      getGroup: vi.fn().mockResolvedValue(group),
      updatePolicy: vi.fn(),
    };

    renderSettings(client, memberSession);

    await screen.findByRole("heading", { name: "Samaipata" });
    expect(
      screen.queryByLabelText(/política de liquidación/i),
    ).not.toBeInTheDocument();
    expect(
      screen.queryByRole("button", { name: /guardar política/i }),
    ).not.toBeInTheDocument();
  });

  it("shows a member the policy affordance when the server policy allows it", async () => {
    const client: GroupFeatureClient = {
      getGroup: vi.fn().mockResolvedValue(anyMemberGroup),
      updatePolicy: vi.fn().mockResolvedValue(group),
    };

    renderSettings(client, memberSession);

    await screen.findByRole("heading", { name: "Samaipata" });
    expect(screen.getByLabelText(/política de liquidación/i)).toBeInTheDocument();
    fireEvent.change(screen.getByLabelText(/política de liquidación/i), {
      target: { value: "owner_only" },
    });
    fireEvent.click(screen.getByRole("button", { name: /guardar política/i }));

    await waitFor(() =>
      expect(client.updatePolicy).toHaveBeenCalledWith(
        "group-demo",
        "owner_only",
      ),
    );
  });

  it("keeps a forbidden policy update in the protected shell with an inline error", async () => {
    const client: GroupFeatureClient = {
      getGroup: vi.fn().mockResolvedValue(group),
      updatePolicy: vi
        .fn()
        .mockRejectedValue(
          new AuthError(
            403,
            "forbidden",
            "Only the owner can change this policy.",
          ),
        ),
    };

    renderSettings(client);

    await screen.findByRole("heading", { name: "Samaipata" });
    fireEvent.change(screen.getByLabelText(/política de liquidación/i), {
      target: { value: "any_member" },
    });
    fireEvent.click(screen.getByRole("button", { name: /guardar política/i }));

    expect(await screen.findByRole("alert")).toHaveTextContent(
      /forbidden: no tienes permisos para realizar esta acción/i,
    );
    expect(
      screen.getByRole("heading", { name: "Samaipata" }),
    ).toBeInTheDocument();
  });
});
