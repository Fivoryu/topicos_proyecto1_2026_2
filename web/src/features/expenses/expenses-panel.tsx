import { useEffect, useMemo, useRef, useState, type FormEvent } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { useSession } from "../../app/auth/session-provider";
import { formatCents } from "../../core/cents-formatter";
import { groupQueryKey, groupQueryKeys } from "../../core/query-client";
import type {
  ExpenseResponse,
  ExpenseWriteRequest,
  ParticipantResponse,
} from "../../generated/api";
import { formatFeatureError, readFeatureError } from "../api-error";
import {
  generatedParticipantClient,
  type ParticipantFeatureClient,
} from "../participants/api";
import { generatedExpenseClient, type ExpenseFeatureClient } from "./api";

type ContributorForm = { participantId: string; amount: string };
type ExpenseForm = {
  description: string;
  amount: string;
  contributors: ContributorForm[];
  beneficiaryIds: string[];
};
type MutationAction =
  | { kind: "create"; request: ExpenseWriteRequest }
  | { kind: "edit"; expenseId: string; request: ExpenseWriteRequest }
  | { kind: "delete"; expenseId: string };
type FeatureErrors = Record<string, string>;

export interface ExpensesPanelProps {
  client?: ExpenseFeatureClient;
  participantsClient?: Pick<ParticipantFeatureClient, "listParticipants">;
  groupId?: string;
}

const emptyForm: ExpenseForm = {
  description: "",
  amount: "",
  contributors: [],
  beneficiaryIds: [],
};

function centsToInput(cents: number): string {
  const text = String(cents);
  const negative = text.startsWith("-");
  const digits = negative ? text.slice(1) : text;
  const padded = digits.length < 3 ? digits.padStart(3, "0") : digits;
  const result = `${padded.slice(0, -2)}.${padded.slice(-2)}`;
  return negative ? `-${result}` : result;
}

function newForm(participants: ParticipantResponse[]): ExpenseForm {
  const active = participants.filter((participant) => !participant.archived);
  return {
    ...emptyForm,
    contributors: active[0]
      ? [{ participantId: active[0].id, amount: "" }]
      : [],
    beneficiaryIds: active.map((participant) => participant.id),
  };
}

function editForm(expense: ExpenseResponse): ExpenseForm {
  return {
    description: expense.description,
    amount: centsToInput(expense.amountCents),
    contributors: expense.contributors.map((contributor) => ({
      participantId: contributor.participantId,
      amount: centsToInput(contributor.amountCents),
    })),
    beneficiaryIds: expense.beneficiaries.map(
      (beneficiary) => beneficiary.participantId,
    ),
  };
}

function invalidAmountText(value: string): string | null {
  if (!value.trim() || /\.\d{3,}/.test(value)) {
    return "invalid_amount: Enter a positive amount with no more than two decimals.";
  }
  return null;
}

function fieldErrorId(field: string): string {
  return `expense-${field.replaceAll(".", "-")}-error`;
}

function errorText(errors: FeatureErrors, field: string): string | undefined {
  return errors[field];
}

function groupIdFor(configured: string | undefined, server: unknown): string {
  return configured ?? (typeof server === "string" ? server : "");
}

function displayParticipant(participant: {
  name: string;
  archived: boolean;
}): string {
  return participant.archived
    ? `${participant.name} (archived)`
    : participant.name;
}

export function ExpensesPanel({
  client = generatedExpenseClient,
  participantsClient = generatedParticipantClient,
  groupId: configuredGroupId,
}: ExpensesPanelProps) {
  const session = useSession();
  const queryClient = useQueryClient();
  const groupId = groupIdFor(configuredGroupId, session.session?.activeGroupId);
  const [form, setForm] = useState<ExpenseForm>(emptyForm);
  const [errors, setErrors] = useState<FeatureErrors>({});
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editingExpense, setEditingExpense] = useState<ExpenseResponse | null>(
    null,
  );
  const [initialized, setInitialized] = useState(false);
  const amountInputRef = useRef<HTMLInputElement>(null);

  const participantsQuery = useQuery({
    queryKey: groupQueryKey("participants", groupId),
    queryFn: () => participantsClient.listParticipants(groupId),
    enabled: session.isAuthenticated && Boolean(groupId),
  });
  const expensesQuery = useQuery({
    queryKey: groupQueryKey("expenses", groupId),
    queryFn: () => client.listExpenses(groupId),
    enabled: session.isAuthenticated && Boolean(groupId),
  });

  useEffect(() => {
    if (!initialized && participantsQuery.data) {
      setForm(newForm(participantsQuery.data));
      setInitialized(true);
    }
  }, [initialized, participantsQuery.data]);

  const formParticipants = useMemo(() => {
    const available = participantsQuery.data ?? [];
    if (!editingExpense)
      return available.filter((participant) => !participant.archived);

    const referencedIds = new Set([
      ...editingExpense.contributors.map(
        (contributor) => contributor.participantId,
      ),
      ...editingExpense.beneficiaries.map(
        (beneficiary) => beneficiary.participantId,
      ),
    ]);
    const knownIds = new Set(available.map((participant) => participant.id));
    const missingReferences: ParticipantResponse[] = [
      ...editingExpense.contributors.map((contributor) => ({
        id: contributor.participantId,
        groupId,
        name: contributor.name,
        archived: contributor.archived,
      })),
      ...editingExpense.beneficiaries.map((beneficiary) => ({
        id: beneficiary.participantId,
        groupId,
        name: beneficiary.name,
        archived: beneficiary.archived,
      })),
    ].filter(
      (participant, index, all) =>
        !knownIds.has(participant.id) &&
        all.findIndex((candidate) => candidate.id === participant.id) === index,
    );
    return [
      ...available.filter(
        (participant) =>
          !participant.archived || referencedIds.has(participant.id),
      ),
      ...missingReferences,
    ];
  }, [editingExpense, groupId, participantsQuery.data]);

  const invalidateGroup = async () => {
    await Promise.all(
      Object.values(groupQueryKeys(groupId)).map((queryKey) =>
        queryClient.invalidateQueries({ queryKey }),
      ),
    );
  };

  const mutation = useMutation<ExpenseResponse | void, unknown, MutationAction>(
    {
      mutationFn: (action) => {
        if (action.kind === "create")
          return client.createExpense(groupId, action.request);
        if (action.kind === "edit")
          return client.editExpense(groupId, action.expenseId, action.request);
        return client.deleteExpense(groupId, action.expenseId);
      },
      onSuccess: async () => {
        setErrors({});
        setEditingId(null);
        setEditingExpense(null);
        setForm(newForm(participantsQuery.data ?? []));
        await invalidateGroup();
      },
      onError: async (error) => {
        const problem = await readFeatureError(error);
        const next: FeatureErrors = { form: formatFeatureError(problem) };
        problem.fieldErrors.forEach(({ field, message }) => {
          next[field] = `${problem.code}: ${message}`;
        });
        if (!problem.fieldErrors.length) {
          if (problem.code === "invalid_amount") next.amount = next.form;
          if (problem.code === "no_beneficiaries")
            next.beneficiaries = next.form;
          if (problem.code === "contribution_mismatch")
            next.contributors = next.form;
          if (problem.code === "invalid_participant_reference") {
            next.contributors = next.form;
            next.beneficiaries = next.form;
          }
        }
        setErrors(next);
        if (problem.code === "invalid_amount") amountInputRef.current?.focus();
      },
    },
  );

  function setFieldError(field: string, value: string | null) {
    setErrors((current) => {
      const next = { ...current };
      if (value === null) {
        delete next[field];
        if (field !== "form") delete next.form;
      } else {
        next[field] = value;
      }
      return next;
    });
  }

  function updateForm(changes: Partial<ExpenseForm>) {
    setForm((current) => ({ ...current, ...changes }));
  }

  function updateContributor(index: number, changes: Partial<ContributorForm>) {
    setForm((current) => ({
      ...current,
      contributors: current.contributors.map((contributor, contributorIndex) =>
        contributorIndex === index
          ? { ...contributor, ...changes }
          : contributor,
      ),
    }));
    setFieldError(`contributors.${index}.amount`, null);
    setFieldError(`contributors.${index}.participantId`, null);
    setFieldError("contributors", null);
    setFieldError("form", null);
  }

  function startEdit(expenseToEdit: ExpenseResponse) {
    setEditingId(expenseToEdit.id);
    setEditingExpense(expenseToEdit);
    setForm(editForm(expenseToEdit));
    setErrors({});
  }

  function cancelEdit() {
    setEditingId(null);
    setEditingExpense(null);
    setForm(newForm(participantsQuery.data ?? []));
    setErrors({});
  }

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (mutation.isPending) return;
    const amountError = invalidAmountText(form.amount);
    if (amountError) {
      setFieldError("amount", amountError);
      amountInputRef.current?.focus();
      return;
    }
    const request: ExpenseWriteRequest = {
      description: form.description,
      amount: form.amount,
      contributors: form.contributors,
      beneficiaryIds: form.beneficiaryIds,
    };
    setErrors({});
    mutation.mutate(
      editingId
        ? { kind: "edit", expenseId: editingId, request }
        : { kind: "create", request },
    );
  }

  function deleteExpense(expenseToDelete: ExpenseResponse) {
    setErrors({});
    mutation.mutate({ kind: "delete", expenseId: expenseToDelete.id });
  }

  if (participantsQuery.isPending || expensesQuery.isPending) {
    return <section className="feature-card">Loading expenses…</section>;
  }
  if (participantsQuery.isError || expensesQuery.isError) {
    return (
      <section className="feature-card" role="alert">
        Unable to load expenses. Please try again.
      </section>
    );
  }

  const hasParticipants = (participantsQuery.data ?? []).length > 0;
  return (
    <section
      className="feature-card expenses-card"
      aria-labelledby="expenses-title"
    >
      <div className="feature-heading">
        <div>
          <p className="feature-eyebrow">Group spending</p>
          <h2 id="expenses-title">Expenses</h2>
        </div>
        <span>{expensesQuery.data?.length ?? 0} recorded</span>
      </div>

      <ul className="expense-list" aria-label="Expense list">
        {expensesQuery.data?.map((expenseToShow) => (
          <li
            className="expense-row"
            data-testid={`expense-${expenseToShow.id}`}
            key={expenseToShow.id}
          >
            <div className="expense-heading">
              <strong>{expenseToShow.description}</strong>
              <span className="tabular-figures">
                {formatCents(expenseToShow.amountCents)}
              </span>
            </div>
            <p className="feature-help">
              Paid by{" "}
              {expenseToShow.contributors
                .map((contributor) => displayParticipant(contributor))
                .join(", ")}
            </p>
            <div className="participant-actions">
              <button
                type="button"
                className="feature-button feature-button-secondary"
                onClick={() => startEdit(expenseToShow)}
                disabled={mutation.isPending}
              >
                Edit expense
              </button>
              <button
                type="button"
                className="feature-button feature-button-danger"
                onClick={() => deleteExpense(expenseToShow)}
                disabled={mutation.isPending}
              >
                Delete expense
              </button>
            </div>
          </li>
        ))}
      </ul>
      {!expensesQuery.data?.length && (
        <p className="feature-help">No expenses recorded yet.</p>
      )}

      {hasParticipants ? (
        <form className="feature-form expense-form" onSubmit={submit}>
          <h3>{editingId ? "Edit expense" : "Record an expense"}</h3>
          <div className="feature-field">
            <label htmlFor="expense-description">Expense description</label>
            <input
              id="expense-description"
              value={form.description}
              onChange={(event) => {
                updateForm({ description: event.target.value });
                setFieldError("description", null);
                setFieldError("form", null);
              }}
              disabled={mutation.isPending}
            />
          </div>
          <div className="feature-field">
            <label htmlFor="expense-amount">Expense amount</label>
            <input
              ref={amountInputRef}
              id="expense-amount"
              inputMode="decimal"
              value={form.amount}
              onChange={(event) => {
                updateForm({ amount: event.target.value });
                setFieldError("amount", null);
                setFieldError("form", null);
              }}
              aria-invalid={Boolean(errorText(errors, "amount"))}
              aria-describedby={
                errorText(errors, "amount") ? fieldErrorId("amount") : undefined
              }
              disabled={mutation.isPending}
            />
            {errorText(errors, "amount") && (
              <p
                id={fieldErrorId("amount")}
                className="feature-error"
                role="alert"
              >
                {errorText(errors, "amount")}
              </p>
            )}
          </div>

          <fieldset className="expense-fieldset">
            <legend>Contributors</legend>
            {form.contributors.map((contributor, index) => {
              const participantError =
                errors[`contributors.${index}.participantId`];
              const amountError =
                errors[`contributors.${index}.amount`] ?? errors.contributors;
              return (
                <div
                  className="contributor-row"
                  key={`${index}-${contributor.participantId}`}
                >
                  <div className="feature-field">
                    <label htmlFor={`contributor-${index}-participant`}>
                      Contributor {index + 1} participant
                    </label>
                    <select
                      id={`contributor-${index}-participant`}
                      value={contributor.participantId}
                      onChange={(event) =>
                        updateContributor(index, {
                          participantId: event.target.value,
                        })
                      }
                      aria-invalid={Boolean(participantError)}
                      disabled={mutation.isPending}
                    >
                      {formParticipants.map((participant) => (
                        <option key={participant.id} value={participant.id}>
                          {displayParticipant(participant)}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className="feature-field">
                    <label htmlFor={`contributor-${index}-amount`}>
                      Contributor {index + 1} amount
                    </label>
                    <input
                      id={`contributor-${index}-amount`}
                      inputMode="decimal"
                      value={contributor.amount}
                      onChange={(event) =>
                        updateContributor(index, { amount: event.target.value })
                      }
                      aria-invalid={Boolean(amountError)}
                      aria-describedby={
                        amountError ? fieldErrorId("contributors") : undefined
                      }
                      disabled={mutation.isPending}
                    />
                  </div>
                  {form.contributors.length > 1 && (
                    <button
                      type="button"
                      className="feature-button feature-button-secondary"
                      onClick={() =>
                        setForm((current) => ({
                          ...current,
                          contributors: current.contributors.filter(
                            (_, contributorIndex) => contributorIndex !== index,
                          ),
                        }))
                      }
                      disabled={mutation.isPending}
                    >
                      Remove contributor
                    </button>
                  )}
                </div>
              );
            })}
            {errors.contributors && (
              <p
                id={fieldErrorId("contributors")}
                className="feature-error"
                role="alert"
              >
                {errors.contributors}
              </p>
            )}
            <button
              type="button"
              className="feature-button feature-button-secondary"
              onClick={() =>
                setForm((current) => ({
                  ...current,
                  contributors: [
                    ...current.contributors,
                    {
                      participantId: formParticipants[0]?.id ?? "",
                      amount: "",
                    },
                  ],
                }))
              }
              disabled={mutation.isPending}
            >
              Add contributor
            </button>
          </fieldset>

          <fieldset className="expense-fieldset">
            <legend>Beneficiaries</legend>
            {formParticipants.map((participant) => (
              <label className="checkbox-field" key={participant.id}>
                <input
                  type="checkbox"
                  checked={form.beneficiaryIds.includes(participant.id)}
                  onChange={(event) => {
                    const beneficiaryIds = event.target.checked
                      ? [...form.beneficiaryIds, participant.id]
                      : form.beneficiaryIds.filter(
                          (id) => id !== participant.id,
                        );
                    updateForm({ beneficiaryIds });
                    setFieldError("beneficiaries", null);
                    setFieldError("form", null);
                  }}
                  disabled={mutation.isPending}
                />
                Beneficiary {displayParticipant(participant)}
              </label>
            ))}
            {errors.beneficiaries && (
              <p
                id={fieldErrorId("beneficiaries")}
                className="feature-error"
                role="alert"
              >
                {errors.beneficiaries}
              </p>
            )}
          </fieldset>

          {errors.form &&
            !errors.amount &&
            !errors.contributors &&
            !errors.beneficiaries && (
              <p className="feature-error" role="alert" aria-live="polite">
                {errors.form}
              </p>
            )}
          <div className="participant-actions">
            <button
              type="submit"
              className="feature-button"
              disabled={mutation.isPending}
              aria-busy={mutation.isPending}
            >
              {mutation.isPending
                ? "Saving…"
                : editingId
                  ? "Save expense"
                  : "Create expense"}
            </button>
            {editingId && (
              <button
                type="button"
                className="feature-button feature-button-secondary"
                onClick={cancelEdit}
                disabled={mutation.isPending}
              >
                Cancel edit
              </button>
            )}
          </div>
        </form>
      ) : (
        <p className="feature-empty" role="status">
          Add participants first before recording an expense.
        </p>
      )}
    </section>
  );
}
