import { QueryClient, useQuery } from "@tanstack/react-query";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import {
  AuthError,
  type AuthClient,
  SessionProvider,
  useSession,
} from "../../../src/app/auth/session-provider";
import { ProtectedRoute } from "../../../src/app/routes/protected-route";
import { createHttpClient } from "../../../src/core/http-client";

const session = {
  account: { id: "account-1", loginName: "demo.member" },
  activeGroupId: "group-demo",
  expiresAt: new Date("2026-08-29T12:00:00.000Z"),
  role: "member" as const,
};

function deferred<T>() {
  let resolve!: (value: T) => void;
  let reject!: (reason?: unknown) => void;
  const promise = new Promise<T>((resolvePromise, rejectPromise) => {
    resolve = resolvePromise;
    reject = rejectPromise;
  });
  return { promise, resolve, reject };
}

function makeClient(overrides: Partial<AuthClient> = {}): AuthClient {
  return {
    getSession: vi.fn().mockResolvedValue(session),
    login: vi.fn().mockResolvedValue(session),
    logout: vi.fn().mockResolvedValue(undefined),
    ...overrides,
  };
}

function renderProtected(
  client: AuthClient,
  children: React.ReactNode,
  options?: { queryClient?: QueryClient },
) {
  return render(
    <SessionProvider authClient={client} queryClient={options?.queryClient}>
      <ProtectedRoute>{children}</ProtectedRoute>
    </SessionProvider>,
  );
}

function SessionStatus() {
  const { status, session: currentSession } = useSession();
  return (
    <output data-testid="session-status">
      {status}:{currentSession?.role ?? "none"}
    </output>
  );
}

afterEach(() => {
  document.cookie = "cc_csrf=; Max-Age=0; Path=/";
  vi.restoreAllMocks();
});

describe("protected route and session bootstrap", () => {
  it("does not run group queries until the server authenticates the session", async () => {
    const bootstrap = deferred<typeof session>();
    const fetchGroup = vi.fn().mockResolvedValue({ name: "Demo group" });
    const client = makeClient({
      getSession: vi.fn().mockReturnValue(bootstrap.promise),
    });

    function ProtectedQuery() {
      const { isAuthenticated } = useSession();
      useQuery({
        queryKey: ["group", "group-demo"],
        queryFn: fetchGroup,
        enabled: isAuthenticated,
      });
      return <p>Protected group data</p>;
    }

    renderProtected(client, <ProtectedQuery />);

    expect(fetchGroup).not.toHaveBeenCalled();
    expect(
      screen.getByRole("heading", { name: /sign in/i }),
    ).toBeInTheDocument();
    expect(screen.queryByText("Protected group data")).not.toBeInTheDocument();

    bootstrap.resolve(session);
    await waitFor(() => expect(fetchGroup).toHaveBeenCalledTimes(1));
    expect(screen.getByText("Protected group data")).toBeInTheDocument();
  });

  it("shows no anonymous protected shell while the session probe is pending", () => {
    const bootstrap = deferred<typeof session>();
    const client = makeClient({
      getSession: vi.fn().mockReturnValue(bootstrap.promise),
    });

    renderProtected(client, <p>Protected group data</p>);

    expect(
      screen.getByRole("heading", { name: /sign in/i }),
    ).toBeInTheDocument();
    expect(screen.queryByText("Protected group data")).not.toBeInTheDocument();
    expect(
      screen.queryByText(/participants|balances|settlement/i),
    ).not.toBeInTheDocument();
  });

  it("renders the role returned by the server and has no client role override", async () => {
    const client = makeClient();
    renderProtected(client, <SessionStatus />);

    await waitFor(() =>
      expect(screen.getByTestId("session-status")).toHaveTextContent(
        "authenticated:member",
      ),
    );
    expect(screen.queryByLabelText(/role/i)).not.toBeInTheDocument();
  });

  it("routes an expired bootstrap session to login with an explicit message", async () => {
    const client = makeClient({
      getSession: vi
        .fn()
        .mockRejectedValue(
          new AuthError(
            401,
            "session_expired",
            "The authenticated session has expired.",
          ),
        ),
    });

    renderProtected(client, <p>Protected group data</p>);

    expect(await screen.findByText(/session expired/i)).toBeInTheDocument();
    expect(
      screen.getByRole("heading", { name: /sign in/i }),
    ).toBeInTheDocument();
    expect(screen.queryByText("Protected group data")).not.toBeInTheDocument();
  });

  it("routes a protected 401 received mid-session to login", async () => {
    const fetchApi = vi.fn().mockResolvedValue(
      new Response(
        JSON.stringify({ error_code: "session_expired", message: "Expired." }),
        {
          status: 401,
          headers: { "Content-Type": "application/json" },
        },
      ),
    );
    const client = makeClient();

    function ProtectedRequest() {
      const { handleProtectedState } = useSession();
      return (
        <button
          type="button"
          onClick={() =>
            void createHttpClient({
              fetchApi,
              onProtectedState: handleProtectedState,
            })
              .request("/api/v1/groups/group-demo")
              .catch(() => undefined)
          }
        >
          Load protected data
        </button>
      );
    }

    renderProtected(client, <ProtectedRequest />);
    fireEvent.click(
      await screen.findByRole("button", { name: /load protected data/i }),
    );

    expect(await screen.findByRole("status")).toHaveTextContent(
      /session expired/i,
    );
    expect(
      screen.getByRole("heading", { name: /sign in/i }),
    ).toBeInTheDocument();
  });
});

describe("login and logout", () => {
  it("keeps invalid credentials on the login form and shows the inline error code", async () => {
    const client = makeClient({
      getSession: vi
        .fn()
        .mockRejectedValue(
          new AuthError(401, "unauthorized", "Sign in required."),
        ),
      login: vi
        .fn()
        .mockRejectedValue(
          new AuthError(
            401,
            "invalid_credentials",
            "Invalid login credentials.",
          ),
        ),
    });

    renderProtected(client, <p>Protected group data</p>);
    const loginName = await screen.findByLabelText(/login name/i);
    fireEvent.change(loginName, { target: { value: "demo.member" } });
    fireEvent.change(screen.getByLabelText(/^password$/i), {
      target: { value: "wrong-password" },
    });
    fireEvent.click(screen.getByRole("button", { name: /sign in/i }));

    expect(await screen.findByText(/invalid_credentials/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/login name/i)).toHaveValue("demo.member");
    expect(screen.queryByText("Protected group data")).not.toBeInTheDocument();
  });

  it("toggles password visibility and disables the submit while login is loading", async () => {
    const login = deferred<typeof session>();
    const client = makeClient({
      getSession: vi
        .fn()
        .mockRejectedValue(
          new AuthError(401, "unauthorized", "Sign in required."),
        ),
      login: vi.fn().mockReturnValue(login.promise),
    });

    renderProtected(client, <p>Protected group data</p>);
    await screen.findByLabelText(/login name/i);
    fireEvent.change(screen.getByLabelText(/login name/i), {
      target: { value: "demo.member" },
    });
    fireEvent.change(screen.getByLabelText(/^password$/i), {
      target: { value: "secret" },
    });
    fireEvent.click(screen.getByRole("button", { name: /show password/i }));
    expect(screen.getByLabelText(/^password$/i)).toHaveAttribute(
      "type",
      "text",
    );

    fireEvent.click(screen.getByRole("button", { name: /sign in/i }));
    expect(screen.getByRole("button", { name: /signing in/i })).toBeDisabled();
    expect(screen.getByLabelText(/^password$/i)).toBeDisabled();

    login.resolve(session);
    await waitFor(() =>
      expect(screen.getByText("Protected group data")).toBeInTheDocument(),
    );
  });

  it("clears the CSRF cookie and protected query state when logging out", async () => {
    document.cookie = "cc_csrf=csrf-token; Path=/";
    const queryClient = new QueryClient();
    const client = makeClient();

    function ProtectedContent() {
      const { logout } = useSession();
      return (
        <>
          <p>Protected group data</p>
          <button type="button" onClick={() => void logout()}>
            Log out
          </button>
        </>
      );
    }

    renderProtected(client, <ProtectedContent />, { queryClient });
    await screen.findByText("Protected group data");
    fireEvent.click(screen.getByRole("button", { name: /log out/i }));

    await waitFor(() =>
      expect(
        screen.getByRole("heading", { name: /sign in/i }),
      ).toBeInTheDocument(),
    );
    expect(client.logout).toHaveBeenCalledWith("csrf-token");
    expect(document.cookie).not.toContain("cc_csrf=csrf-token");
    expect(queryClient.getQueryCache().findAll()).toHaveLength(0);
  });
});
