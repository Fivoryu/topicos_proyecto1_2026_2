import { QueryClientProvider, type QueryClient } from "@tanstack/react-query";
import {
  createContext,
  type ReactNode,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

import {
  AuthApi,
  ResponseError,
  type SessionIdentityResponse,
} from "../../generated/api";
import { apiConfiguration } from "../api-client";
import {
  type ProtectedState,
  clearAuthCookies,
  getCsrfToken,
  registerProtectedStateHandler,
} from "../../core/http-client";
import { queryClient as defaultQueryClient } from "../../core/query-client";

export type SessionStatus =
  | "unknown"
  | "authenticating"
  | "authenticated"
  | "signedOut"
  | "sessionExpired";

export interface LoginCredentials {
  loginName: string;
  password: string;
  csrfToken: string;
}

export interface AuthClient {
  getSession: () => Promise<SessionIdentityResponse>;
  login: (credentials: LoginCredentials) => Promise<SessionIdentityResponse>;
  logout: (csrfToken: string) => Promise<void>;
}

export class AuthError extends Error {
  readonly status: number;
  readonly errorCode: string;

  constructor(status: number, errorCode: string, message: string) {
    super(message);
    this.name = "AuthError";
    this.status = status;
    this.errorCode = errorCode;
  }
}

export interface SessionContextValue {
  status: SessionStatus;
  session: SessionIdentityResponse | null;
  isAuthenticated: boolean;
  errorCode: string | null;
  errorMessage: string | null;
  notice: string | null;
  login: (credentials: Omit<LoginCredentials, "csrfToken">) => Promise<void>;
  logout: () => Promise<void>;
  handleProtectedState: (state: ProtectedState) => void;
}

const SessionContext = createContext<SessionContextValue | null>(null);
const generatedAuthApi = new AuthApi(apiConfiguration);

async function readResponseError(error: ResponseError): Promise<AuthError> {
  let payload: { error_code?: string; message?: string } = {};
  try {
    payload = (await error.response.clone().json()) as typeof payload;
  } catch {
    // Keep the generated error status when the server did not return JSON.
  }

  return new AuthError(
    error.response.status,
    payload.error_code ??
      (error.response.status === 401 ? "unauthorized" : "http_error"),
    payload.message ?? error.message,
  );
}

async function normalizeAuthError(error: unknown): Promise<AuthError | Error> {
  if (error instanceof AuthError) {
    return error;
  }
  if (error instanceof ResponseError) {
    return readResponseError(error);
  }
  if (error instanceof Error && "status" in error && "errorCode" in error) {
    const candidate = error as Error & { status: number; errorCode: string };
    return new AuthError(
      candidate.status,
      candidate.errorCode,
      candidate.message,
    );
  }
  return error instanceof Error
    ? error
    : new Error("Authentication request failed.");
}

async function callAuth<T>(operation: () => Promise<T>): Promise<T> {
  try {
    return await operation();
  } catch (error) {
    throw await normalizeAuthError(error);
  }
}

export const generatedAuthClient: AuthClient = {
  getSession: () =>
    callAuth(() => generatedAuthApi.sessionApiV1AuthSessionGet()),
  login: ({ loginName, password, csrfToken }) =>
    callAuth(() =>
      generatedAuthApi.loginApiV1AuthLoginPost({
        xCSRFToken: csrfToken,
        loginRequest: { loginName, password },
      }),
    ),
  logout: (csrfToken) =>
    callAuth(() =>
      generatedAuthApi.logoutApiV1AuthLogoutPost({ xCSRFToken: csrfToken }),
    ),
};

function protectedMessage(state: ProtectedState): string {
  return state === "sessionExpired"
    ? "Your session expired. Please sign in again."
    : "You have been signed out. Please sign in again.";
}

export interface SessionProviderProps {
  children: ReactNode;
  authClient?: AuthClient;
  queryClient?: QueryClient;
}

export function SessionProvider({
  children,
  authClient = generatedAuthClient,
  queryClient = defaultQueryClient,
}: SessionProviderProps) {
  const [snapshot, setSnapshot] = useState<{
    status: SessionStatus;
    session: SessionIdentityResponse | null;
    errorCode: string | null;
    errorMessage: string | null;
    notice: string | null;
  }>({
    status: "unknown",
    session: null,
    errorCode: null,
    errorMessage: null,
    notice: null,
  });

  const handleProtectedState = useCallback(
    (state: ProtectedState) => {
      queryClient.clear();
      setSnapshot({
        status: state,
        session: null,
        errorCode:
          state === "sessionExpired" ? "session_expired" : "unauthorized",
        errorMessage: protectedMessage(state),
        notice: protectedMessage(state),
      });
    },
    [queryClient],
  );

  useEffect(
    () => registerProtectedStateHandler(handleProtectedState),
    [handleProtectedState],
  );

  useEffect(() => {
    let active = true;
    void authClient
      .getSession()
      .then((currentSession) => {
        if (!active) return;
        setSnapshot({
          status: "authenticated",
          session: currentSession,
          errorCode: null,
          errorMessage: null,
          notice: null,
        });
      })
      .catch((error: unknown) => {
        if (!active) return;
        void normalizeAuthError(error).then((authError) => {
          if (!active) return;
          const state: ProtectedState =
            authError instanceof AuthError &&
            authError.errorCode === "session_expired"
              ? "sessionExpired"
              : "signedOut";
          handleProtectedState(state);
          setSnapshot((current) => ({
            ...current,
            errorCode:
              authError instanceof AuthError
                ? authError.errorCode
                : "unauthorized",
            errorMessage: authError.message,
            notice: state === "sessionExpired" ? protectedMessage(state) : null,
          }));
        });
      });

    return () => {
      active = false;
    };
  }, [authClient, handleProtectedState]);

  const login = useCallback(
    async ({ loginName, password }: Omit<LoginCredentials, "csrfToken">) => {
      setSnapshot((current) => ({
        ...current,
        status: "authenticating",
        errorCode: null,
        errorMessage: null,
        notice: null,
      }));
      try {
        const currentSession = await authClient.login({
          loginName,
          password,
          csrfToken: getCsrfToken() ?? "",
        });
        setSnapshot({
          status: "authenticated",
          session: currentSession,
          errorCode: null,
          errorMessage: null,
          notice: null,
        });
      } catch (error) {
        const authError = await normalizeAuthError(error);
        queryClient.clear();
        setSnapshot({
          status: "signedOut",
          session: null,
          errorCode:
            authError instanceof AuthError ? authError.errorCode : "http_error",
          errorMessage: authError.message,
          notice: null,
        });
      }
    },
    [authClient, queryClient],
  );

  const logout = useCallback(async () => {
    try {
      await authClient.logout(getCsrfToken() ?? "");
    } finally {
      clearAuthCookies();
      queryClient.clear();
      setSnapshot({
        status: "signedOut",
        session: null,
        errorCode: null,
        errorMessage: null,
        notice: "You have been logged out. Please sign in again.",
      });
    }
  }, [authClient, queryClient]);

  const value = useMemo<SessionContextValue>(
    () => ({
      ...snapshot,
      isAuthenticated:
        snapshot.status === "authenticated" && snapshot.session !== null,
      login,
      logout,
      handleProtectedState,
    }),
    [snapshot, login, logout, handleProtectedState],
  );

  return (
    <QueryClientProvider client={queryClient}>
      <SessionContext.Provider value={value}>
        {children}
      </SessionContext.Provider>
    </QueryClientProvider>
  );
}

export function useSession(): SessionContextValue {
  const context = useContext(SessionContext);
  if (!context) {
    throw new Error("useSession must be used inside SessionProvider.");
  }
  return context;
}
