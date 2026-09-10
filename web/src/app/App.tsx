import { useEffect, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { Icon } from "../components/icons";
import { Button, StatusBadge } from "../components/ui";
import { connectGroupWebSocket } from "../core/websocket";
import {
  BalancesPanel,
  ScopedBalancesPanel,
} from "../features/balances";
import {
  ExpensesPanel,
  ScopedExpensesPanel,
} from "../features/expenses";
import { GroupSettings } from "../features/group";
import { ParticipantDetailPanel, ParticipantsPanel } from "../features/participants";
import {
  ScopedSettlementPanel,
  SettlementPanel,
} from "../features/settlement";
import { OutingDetailPanel, OutingsPanel } from "../features/outings";
import { SummaryPanel } from "../features/workspace";
import {
  parseWorkspaceHash,
  type WorkspaceRoute,
} from "../core/workspace-navigation";
import { SessionProvider, useSession } from "./auth/session-provider";
import { ProtectedRoute } from "./routes/protected-route";
import { WorkspaceShell } from "./workspace-shell";

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
  const hash = window.location.hash;
  if (navItems.some((item) => item.href === hash)) return hash;
  const route = parseWorkspaceHash(hash);
  if (route.kind === "balances") return "#balances";
  if (route.kind === "settlement") return "#liquidacion";
  if (route.kind === "participant") return "#participantes";
  if (route.kind === "settings") return "#grupo";
  return navItems[0].href;
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

function SelectedGroupView({
  groupId,
  route,
}: {
  groupId: string;
  route: WorkspaceRoute;
}) {
  let panel: React.ReactNode;
  switch (route.kind) {
    case "summary":
    case "groups":
      panel = <SummaryPanel groupId={groupId} />;
      break;
    case "outings":
      panel = <OutingsPanel groupId={groupId} />;
      break;
    case "outing":
      panel = <OutingDetailPanel groupId={groupId} outingId={route.outingId} />;
      break;
    case "outing-expenses":
      panel = (
        <ScopedExpensesPanel
          groupId={groupId}
          scope={{ outingId: route.outingId }}
        />
      );
      break;
    case "expenses":
      panel = (
        <>
          <ScopedExpensesPanel groupId={groupId} scope="group" />
          <ScopedExpensesPanel groupId={groupId} scope="general" />
        </>
      );
      break;
    case "participant":
      panel = (
        <ParticipantDetailPanel
          groupId={groupId}
          participantId={route.participantId}
        />
      );
      break;
    case "balances":
      panel = <ScopedBalancesPanel groupId={groupId} />;
      break;
    case "settlement":
      panel = <ScopedSettlementPanel groupId={groupId} />;
      break;
    case "legacy":
      panel = {
        gastos: <ExpensesPanel groupId={groupId} />,
        balances: <BalancesPanel groupId={groupId} />,
        liquidacion: <SettlementPanel groupId={groupId} />,
        participantes: <ParticipantsPanel groupId={groupId} />,
        grupo: <GroupSettings groupId={groupId} />,
      }[route.anchor];
      break;
    case "settings":
      panel = <GroupSettings groupId={groupId} />;
      break;
    case "unknown":
      panel = <p role="alert">Esta ruta no está disponible.</p>;
      break;
  }
  return (
    <div data-testid="workspace-route-view" tabIndex={-1}>
      {panel}
    </div>
  );
}

function ProtectedShell() {
  const { session, logout } = useSession();
  const queryClient = useQueryClient();

  useEffect(() => {
    if (!session?.activeGroupId) return;
    const connection = connectGroupWebSocket({
      groupId: session.activeGroupId,
      queryClient,
    });
    return connection.close;
  }, [queryClient, session]);

  if (!session) return null;
  if (!session.activeGroupId) return <WorkspaceShell />;

  const activeGroupId = session.activeGroupId;
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
            <div
              className="dashboard-column dashboard-main-column dashboard-primary-column"
              role="region"
              aria-label="Flujo financiero principal"
            >
              <div
                id="gastos"
                className="dashboard-slot dashboard-slot-expenses"
              >
                <WorkspaceShell
                  embedded
                  renderSelected={(groupId, route) => (
                    <SelectedGroupView groupId={groupId} route={route} />
                  )}
                />
              </div>

              <div className="dashboard-summary-grid">
                <div
                  id="balances"
                  className="dashboard-slot dashboard-slot-balances"
                  tabIndex={-1}
                />
                <div
                  id="liquidacion"
                  className="dashboard-slot dashboard-slot-settlement"
                  tabIndex={-1}
                />
              </div>
            </div>

            <aside
              className="dashboard-column dashboard-side-column"
              aria-label="Administración del grupo"
            >
              <div
                id="participantes"
                className="dashboard-slot dashboard-slot-participants"
                tabIndex={-1}
              />
              <div
                id="grupo"
                className="dashboard-slot dashboard-slot-group"
                tabIndex={-1}
              />
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
