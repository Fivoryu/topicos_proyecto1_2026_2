import { useEffect, useState, type FormEvent } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useSession } from "../../app/auth/session-provider";
import { Button, ErrorCard, LoadingCard, Panel, PanelHeading, StatusBadge } from "../../components/ui";
import { groupQueryKey } from "../../core/query-client";
import type { GroupResponseSettlementPolicyEnum } from "../../generated/api";
import { formatFeatureError, readFeatureError } from "../api-error";
import { generatedGroupClient, type GroupFeatureClient } from "./api";

export interface GroupSettingsProps {
  client?: GroupFeatureClient;
  groupId?: string;
}
const policyLabel = (policy: GroupResponseSettlementPolicyEnum) =>
  policy === "owner_only" ? "Solo propietario" : "Cualquier miembro";

export function GroupSettings({
  client = generatedGroupClient,
  groupId: configuredGroupId,
}: GroupSettingsProps) {
  const session = useSession();
  const queryClient = useQueryClient();
  const serverGroupId = session.session?.activeGroupId;
  const groupId =
    configuredGroupId ??
    (typeof serverGroupId === "string" ? serverGroupId : "");
  const [selectedPolicy, setSelectedPolicy] = useState<
    GroupResponseSettlementPolicyEnum | ""
  >("");
  const [mutationError, setMutationError] = useState<string | null>(null);
  const groupQuery = useQuery({
    queryKey: groupQueryKey("group", groupId),
    queryFn: () => client.getGroup(groupId),
    enabled: session.isAuthenticated && Boolean(groupId),
  });
  useEffect(() => {
    if (groupQuery.data) setSelectedPolicy(groupQuery.data.settlementPolicy);
  }, [groupQuery.data]);
  const updatePolicy = useMutation({
    mutationFn: (policy: GroupResponseSettlementPolicyEnum) =>
      client.updatePolicy(groupId, policy),
    onSuccess: async (updatedGroup) => {
      setMutationError(null);
      setSelectedPolicy(updatedGroup.settlementPolicy);
      await queryClient.invalidateQueries({
        queryKey: groupQueryKey("group", groupId),
      });
    },
    onError: async (error: unknown) =>
      setMutationError(formatFeatureError(await readFeatureError(error))),
  });
  if (groupQuery.isPending) return <LoadingCard>Cargando grupo…</LoadingCard>;
  if (groupQuery.isError || !groupQuery.data) {
    return <ErrorCard>No se pudo cargar el grupo. Intenta nuevamente.</ErrorCard>;
  }
  const group = groupQuery.data;
  const canUpdate =
    session.session?.role === "owner" ||
    group.settlementPolicy === "any_member";
  function submitPolicy(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!selectedPolicy || updatePolicy.isPending) return;
    setMutationError(null);
    updatePolicy.mutate(selectedPolicy);
  }
  return (
    <Panel className="group-card" labelledBy="group-settings-title">
      <PanelHeading
        eyebrow="Grupo activo"
        title={group.name}
        titleId="group-settings-title"
        action={<StatusBadge tone="success">Activo</StatusBadge>}
      />
      <dl className="group-details">
        <div>
          <dt>Cuenta propietaria</dt>
          <dd>{group.ownerAccountId}</dd>
        </div>
        <div>
          <dt>Política de liquidación</dt>
          <dd>{policyLabel(group.settlementPolicy)}</dd>
        </div>
      </dl>
      {canUpdate && (
        <form className="feature-form" onSubmit={submitPolicy}>
          <div className="feature-field">
            <label htmlFor="settlement-policy">Política de liquidación</label>
            <select
              id="settlement-policy"
              value={selectedPolicy}
              onChange={(event) => {
                setSelectedPolicy(
                  event.target.value as GroupResponseSettlementPolicyEnum,
                );
                setMutationError(null);
              }}
              disabled={updatePolicy.isPending}
            >
              <option value="owner_only">Solo propietario</option>
              <option value="any_member">Cualquier miembro</option>
            </select>
          </div>
          <Button
            type="submit"
            disabled={updatePolicy.isPending}
            aria-busy={updatePolicy.isPending}
          >
            {updatePolicy.isPending ? "Guardando…" : "Guardar política"}
          </Button>
        </form>
      )}
      {mutationError && (
        <p className="feature-error" role="alert" aria-live="polite">
          {mutationError}
        </p>
      )}
    </Panel>
  );
}
export { GroupSettings as GroupFeature };
