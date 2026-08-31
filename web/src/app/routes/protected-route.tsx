import { type ReactNode } from "react";

import { LoginScreen } from "../../features/auth/login-screen";
import { useSession } from "../auth/session-provider";

export interface ProtectedRouteProps {
  children: ReactNode;
}

/** Render protected children only after the server has authenticated the session. */
export function ProtectedRoute({ children }: ProtectedRouteProps) {
  const session = useSession();

  if (!session.isAuthenticated) {
    return <LoginScreen />;
  }

  return <>{children}</>;
}
