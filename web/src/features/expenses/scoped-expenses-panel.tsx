import { useQuery } from "@tanstack/react-query";

import { useSession } from "../../app/auth/session-provider";
import { Button, ErrorCard, LoadingCard, Panel, PanelHeading, StatusBadge } from "../../components/ui";
import { formatCents } from "../../core/cents-formatter";
import { workspaceQueryKeys } from "../../core/workspace-query-keys";
import type { ExpenseResponse } from "../../generated/api";
import { generatedExpenseClient, type ExpenseFeatureClient, type ExpenseReadScope } from "./api";

export type ScopedExpenseScope =
  | "group"
  | "all"
  | "general"
  | {
      outingId: string;
      outingName?: string;
      archived?: boolean;
      scope?: "outing";
    };

export interface ScopedExpensesPanelProps {
  client?: ExpenseFeatureClient;
  groupId?: string;
  scope: ScopedExpenseScope;
}

type ScopeDetails = {
  request: ExpenseReadScope;
  queryScope: string;
  title: string;
  eyebrow: string;
  archived: boolean;
  includes: (expense: ExpenseResponse) => boolean;
};

function groupIdFor(configured: string | undefined, server: unknown): string {
  return configured ?? (typeof server === "string" ? server : "");
}

function scopeDetails(scope: ScopedExpenseScope): ScopeDetails {
  if (scope === "general") {
    return {
      request: "general",
      queryScope: "general",
      title: "Gastos generales",
      eyebrow: "Gastos sin salida",
      archived: false,
      includes: (expense) => expense.outingId == null,
    };
  }
  if (typeof scope === "object") {
    return {
      request: { outingId: scope.outingId },
      queryScope: scope.outingId,
      title: scope.outingName
        ? `Gastos de ${scope.outingName}`
        : "Gastos de la salida",
      eyebrow: "Gastos de una salida",
      archived: scope.archived === true,
      includes: (expense) => expense.outingId === scope.outingId,
    };
  }
  return {
    request: "all",
    queryScope: "all",
    title: "Gastos del grupo",
    eyebrow: "Todos los gastos del grupo",
    archived: false,
    includes: () => true,
  };
}

function assertScope(
  expenses: ExpenseResponse[],
  groupId: string,
  details: ScopeDetails,
): ExpenseResponse[] {
  if (expenses.some((expense) => expense.groupId !== groupId || !details.includes(expense))) {
    throw new Error("La respuesta no coincide con el alcance solicitado.");
  }
  return expenses;
}

function participantName(name: string, archived: boolean): string {
  return archived ? `${name} (archivado)` : name;
}

function RefreshButton({
  pending,
  onClick,
}: {
  pending: boolean;
  onClick: () => void;
}) {
  return (
    <Button
      type="button"
      variant="secondary"
      onClick={onClick}
      disabled={pending}
      aria-busy={pending}
    >
      {pending ? "Actualizando…" : "Actualizar gastos"}
    </Button>
  );
}

function ExpenseRow({ expense }: { expense: ExpenseResponse }) {
  return (
    <li className="expense-row" data-testid={`scoped-expense-${expense.id}`}>
      <div className="expense-row-heading">
        <h3>{expense.description}</h3>
        <strong className="tabular-figures">{formatCents(expense.amountCents)}</strong>
      </div>
      <p>
        <strong>Pagado por:</strong>{" "}
        {expense.contributors.map((contributor, index) => (
          <span key={contributor.participantId}>
            {index ? ", " : ""}
            {participantName(contributor.name, contributor.archived)} ({formatCents(contributor.amountCents)})
          </span>
        ))}
      </p>
      <p>
        <strong>Beneficiarios:</strong>{" "}
        {expense.beneficiaries.map((beneficiary, index) => (
          <span key={beneficiary.participantId}>
            {index ? ", " : ""}
            {participantName(beneficiary.name, beneficiary.archived)}
          </span>
        ))}
      </p>
    </li>
  );
}

export function ScopedExpensesPanel({
  client = generatedExpenseClient,
  groupId: configuredGroupId,
  scope,
}: ScopedExpensesPanelProps) {
  const session = useSession();
  const groupId = groupIdFor(configuredGroupId, session.session?.activeGroupId);
  const details = scopeDetails(scope);
  const titleId = `scoped-expenses-title-${groupId}-${details.queryScope}`;
  const expensesQuery = useQuery({
    queryKey: workspaceQueryKeys.group.expenses(groupId, details.queryScope),
    queryFn: async () => assertScope(
      await client.listExpenses(groupId, details.request),
      groupId,
      details,
    ),
    enabled: session.isAuthenticated && Boolean(groupId),
  });

  if (expensesQuery.isPending) return <LoadingCard>Cargando gastos…</LoadingCard>;
  if (expensesQuery.isError || !expensesQuery.data) {
    return (
      <ErrorCard>
        <span>No se pudieron cargar los gastos. Intenta nuevamente.</span>{" "}
        <RefreshButton
          pending={expensesQuery.isFetching}
          onClick={() => void expensesQuery.refetch()}
        />
      </ErrorCard>
    );
  }

  return (
    <Panel className="scoped-expenses-card" labelledBy={titleId}>
      <PanelHeading
        eyebrow={details.eyebrow}
        title={details.title}
        titleId={titleId}
        action={
          <RefreshButton
            pending={expensesQuery.isFetching}
            onClick={() => void expensesQuery.refetch()}
          />
        }
      />
      {details.archived ? (
        <p className="feature-state-card" role="note">
          <StatusBadge tone="warning">Archivada</StatusBadge>{" "}
          Esta salida es de solo lectura; el historial se conserva.
        </p>
      ) : null}
      {!expensesQuery.data.length ? (
        <p className="feature-empty" role="status">
          No hay gastos en este alcance.
        </p>
      ) : (
        <ul className="expense-list" aria-label={details.title}>
          {expensesQuery.data.map((expense) => <ExpenseRow key={expense.id} expense={expense} />)}
        </ul>
      )}
    </Panel>
  );
}
