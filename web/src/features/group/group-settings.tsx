import { useEffect, useState, type FormEvent } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useSession } from "../../app/auth/session-provider";
import { groupQueryKey } from "../../core/query-client";
import type { GroupResponseSettlementPolicyEnum } from "../../generated/api";
import { formatFeatureError, readFeatureError } from "../api-error";
import { generatedGroupClient, type GroupFeatureClient } from "./api";

export interface GroupSettingsProps {
  client?: GroupFeatureClient;
  groupId?: string;
}
const policyLabel = (policy: GroupResponseSettlementPolicyEnum) =>
  policy === "owner_only" ? "Owner only" : "Any member";

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
  if (groupQuery.isPending)
    return <section className="feature-card">Loading group…</section>;
  if (groupQuery.isError || !groupQuery.data) {
    return (
      <section className="feature-card" role="alert">
        Unable to load the group. Please try again.
      </section>
    );
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
    <section className="feature-card" aria-labelledby="group-settings-title">
      <p className="feature-eyebrow">Active group</p>
      <h2 id="group-settings-title">{group.name}</h2>
      <dl className="group-details">
        <div>
          <dt>Owner account</dt>
          <dd>{group.ownerAccountId}</dd>
        </div>
        <div>
          <dt>Settlement policy</dt>
          <dd>{policyLabel(group.settlementPolicy)}</dd>
        </div>
      </dl>
      {canUpdate && (
        <form className="feature-form" onSubmit={submitPolicy}>
          <div className="feature-field">
            <label htmlFor="settlement-policy">Settlement policy</label>
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
              <option value="owner_only">Owner only</option>
              <option value="any_member">Any member</option>
            </select>
          </div>
          <button
            type="submit"
            className="feature-button"
            disabled={updatePolicy.isPending}
            aria-busy={updatePolicy.isPending}
          >
            {updatePolicy.isPending ? "Saving…" : "Save policy"}
          </button>
        </form>
      )}
      {mutationError && (
        <p className="feature-error" role="alert" aria-live="polite">
          {mutationError}
        </p>
      )}
    </section>
  );
}
export { GroupSettings as GroupFeature };
