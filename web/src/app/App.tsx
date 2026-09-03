import { useEffect } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { connectGroupWebSocket } from "../core/websocket";
import { BalancesPanel } from "../features/balances";
import { ExpensesPanel } from "../features/expenses";
import { GroupSettings } from "../features/group";
import { ParticipantsPanel } from "../features/participants";
import { SettlementPanel } from "../features/settlement";
import { SessionProvider, useSession } from "./auth/session-provider";
import { ProtectedRoute } from "./routes/protected-route";

function ProtectedShell() {
  const { session, logout } = useSession();
  const queryClient = useQueryClient();

  useEffect(() => {
    if (!session) return;
    const connection = connectGroupWebSocket({
      groupId: session.activeGroupId,
      queryClient,
    });
    return connection.close;
  }, [queryClient, session]);

  if (!session) {
    return null;
  }

  return (
    <main className="shell-page">
      <section
        className="shell-card"
        aria-labelledby="shell-title"
        data-testid="protected-shell"
      >
        <p className="shell-eyebrow">Cuentas Claras</p>
        <h1 id="shell-title">Tu grupo está protegido</h1>
        <p>Sesión iniciada como {session.account.loginName}</p>
        <p>Rol: {session.role === "owner" ? "Propietario" : "Miembro"}</p>
        <button
          type="button"
          className="auth-submit"
          onClick={() => void logout()}
        >
          Cerrar sesión
        </button>
      </section>
      <div className="feature-grid">
        <GroupSettings groupId={session.activeGroupId} />
        <ParticipantsPanel groupId={session.activeGroupId} />
        <ExpensesPanel groupId={session.activeGroupId} />
        <BalancesPanel groupId={session.activeGroupId} />
        <SettlementPanel groupId={session.activeGroupId} />
      </div>
    </main>
  );
}

export function App() {
  return (
    <SessionProvider>
      <ProtectedRoute>
        <ProtectedShell />
      </ProtectedRoute>
    </SessionProvider>
  );
}
