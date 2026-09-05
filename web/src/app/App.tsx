import { useEffect, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { Icon } from "../components/icons";
import { Button, StatusBadge } from "../components/ui";
import { connectGroupWebSocket } from "../core/websocket";
import { BalancesPanel } from "../features/balances";
import { ExpensesPanel } from "../features/expenses";
import { GroupSettings } from "../features/group";
import { ParticipantsPanel } from "../features/participants";
import { SettlementPanel } from "../features/settlement";
import { SessionProvider, useSession } from "./auth/session-provider";
import { ProtectedRoute } from "./routes/protected-route";

const navItems = [
  { href: "#gastos", label: "Gastos", icon: "receipt" as const },
  { href: "#balances", label: "Balances", icon: "chart" as const },
  { href: "#liquidacion", label: "Liquidación", icon: "settlement" as const },
  { href: "#participantes", label: "Participantes", icon: "users" as const },
  { href: "#grupo", label: "Grupo", icon: "home" as const },
];

function Brand() {
  return (
    <a
      className="brand"
      href="#gastos"
      aria-label="Ir a gastos de Cuentas Claras"
    >
      <span className="brand-mark" aria-hidden="true">
        <Icon name="wallet" />
      </span>
      <span>
        <strong>Cuentas Claras</strong>
        <small>Gastos compartidos</small>
      </span>
    </a>
  );
}

function getCurrentNavHash() {
  if (typeof window === "undefined") return navItems[0].href;
  return navItems.some((item) => item.href === window.location.hash)
    ? window.location.hash
    : navItems[0].href;
}

function Navigation() {
  const [currentHash, setCurrentHash] = useState(getCurrentNavHash);

  useEffect(() => {
    const updateCurrentHash = () => setCurrentHash(getCurrentNavHash());
    window.addEventListener("hashchange", updateCurrentHash);
    return () => window.removeEventListener("hashchange", updateCurrentHash);
  }, []);

  return (
    <nav className="app-nav" aria-label="Secciones del grupo">
      {navItems.map((item) => (
        <a
          key={item.href}
          href={item.href}
          className="nav-link"
          aria-current={currentHash === item.href ? "page" : undefined}
          onClick={() => setCurrentHash(item.href)}
        >
          <Icon name={item.icon} />
          <span>{item.label}</span>
        </a>
      ))}
    </nav>
  );
}

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

  if (!session) return null;

  const roleLabel = session.role === "owner" ? "Propietario" : "Miembro";

  return (
    <>
      <a className="skip-link" href="#main-content">
        Saltar al contenido principal
      </a>
      <main
        id="main-content"
        className="app-shell"
        data-testid="protected-shell"
        tabIndex={-1}
      >
        <aside className="app-sidebar">
          <Brand />
          <Navigation />
          <div className="sidebar-account">
            <div className="account-avatar" aria-hidden="true">
              {session.account.loginName.slice(0, 1).toUpperCase()}
            </div>
            <div className="account-copy">
              <strong>{session.account.loginName}</strong>
              <StatusBadge tone={session.role === "owner" ? "info" : "neutral"}>
                {roleLabel}
              </StatusBadge>
            </div>
          </div>
        </aside>

        <div className="app-workspace">
          <header className="workspace-header">
            <div className="mobile-brand-row">
              <Brand />
            </div>
            <div className="workspace-heading">
              <div className="workspace-title-block">
                <p className="workspace-eyebrow">
                  <Icon name="shield" /> Sesión segura
                </p>
                <h1 id="shell-title">Tu grupo está protegido</h1>
                <p className="workspace-subtitle">
                  Toda la cuenta del grupo, ordenada para decidir y cerrar sin
                  sorpresas.
                </p>
                <div
                  className="workspace-session"
                  aria-label="Datos de la sesión"
                >
                  <span>Sesión iniciada como {session.account.loginName}</span>
                  <span>Rol: {roleLabel}</span>
                </div>
              </div>
              <div className="workspace-actions">
                <Button
                  type="button"
                  variant="ghost"
                  className="workspace-logout"
                  onClick={() => void logout()}
                >
                  <Icon name="logout" />
                  <span>Cerrar sesión</span>
                </Button>
              </div>
            </div>
            <div className="mobile-nav-scroll">
              <Navigation />
            </div>
          </header>

          <div className="dashboard-layout" aria-labelledby="shell-title">
            <div className="dashboard-main-column">
              <div
                id="gastos"
                className="dashboard-slot dashboard-slot-expenses"
              >
                <ExpensesPanel groupId={session.activeGroupId} />
              </div>

              <div className="dashboard-summary-grid">
                <div
                  id="balances"
                  className="dashboard-slot dashboard-slot-balances"
                >
                  <BalancesPanel groupId={session.activeGroupId} />
                </div>
                <div
                  id="liquidacion"
                  className="dashboard-slot dashboard-slot-settlement"
                >
                  <SettlementPanel groupId={session.activeGroupId} />
                </div>
              </div>
            </div>

            <aside
              className="dashboard-side-column"
              aria-label="Administración del grupo"
            >
              <div
                id="participantes"
                className="dashboard-slot dashboard-slot-participants"
              >
                <ParticipantsPanel groupId={session.activeGroupId} />
              </div>
              <div id="grupo" className="dashboard-slot dashboard-slot-group">
                <GroupSettings groupId={session.activeGroupId} />
              </div>
            </aside>
          </div>
        </div>
      </main>
    </>
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
