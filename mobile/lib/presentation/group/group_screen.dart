import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../domain/read_models/read_models.dart';
import '../read_status.dart';
import '../read_view_helpers.dart';
import 'group_cubit.dart';
import 'group_policy_mutation_cubit.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({
    required this.cubit,
    this.role = 'member',
    this.mutationCubit,
    this.policyMutationCubit,
    this.loadOnOpen = true,
    super.key,
  }) : assert(
         mutationCubit == null || policyMutationCubit == null,
         'Use only one policy mutation Cubit parameter.',
       );

  final GroupCubit cubit;
  final String role;
  final GroupPolicyMutationCubit? mutationCubit;
  final GroupPolicyMutationCubit? policyMutationCubit;
  final bool loadOnOpen;

  GroupPolicyMutationCubit? get effectiveMutationCubit =>
      mutationCubit ?? policyMutationCubit;

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.loadOnOpen) unawaited(widget.cubit.load());
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<GroupState>(
    stream: widget.cubit.stream,
    initialData: widget.cubit.state,
    builder: (context, snapshot) {
      final state = snapshot.data ?? widget.cubit.state;
      if (state.status != ReadStatus.loaded || state.group == null) {
        return ReadStateMessage(
          status: state.status,
          resource: 'group',
          message: state.message,
          onRetry: widget.cubit.reload,
        );
      }
      final mutationCubit = widget.effectiveMutationCubit;
      if (mutationCubit == null) {
        return _buildLoaded(context, state.group!, null);
      }
      return StreamBuilder<GroupPolicyMutationState>(
        stream: mutationCubit.stream,
        initialData: mutationCubit.state,
        builder: (context, mutationSnapshot) => _buildLoaded(
          context,
          state.group!,
          mutationSnapshot.data ?? mutationCubit.state,
        ),
      );
    },
  );

  Widget _buildLoaded(
    BuildContext context,
    GroupReadModel group,
    GroupPolicyMutationState? mutationState,
  ) {
    final canChangePolicy =
        mutationState != null && _canChangePolicy(group.settlementPolicy);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: DesignTokens.spacingLg),
        child: ReadCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Group', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: DesignTokens.spacingXs),
              Text(
                group.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: DesignTokens.spacingMd),
              Text(
                'Settlement policy',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (canChangePolicy)
                _buildPolicyControls(context, group, mutationState)
              else ...[
                Text(
                  _policyLabel(group.settlementPolicy),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (mutationState != null &&
                    !_canChangePolicy(group.settlementPolicy))
                  Padding(
                    padding: const EdgeInsets.only(top: DesignTokens.spacingSm),
                    child: Text(
                      'Only the group owner can change this policy.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
              ],
              if (mutationState != null)
                _buildMutationFeedback(context, mutationState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyControls(
    BuildContext context,
    GroupReadModel group,
    GroupPolicyMutationState mutationState,
  ) {
    final disabled = mutationState.isDisabled;
    return RadioGroup<SettlementPolicy>(
      groupValue: group.settlementPolicy,
      onChanged: (policy) {
        if (!disabled && policy != null) {
          unawaited(widget.effectiveMutationCubit!.update(policy));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioListTile<SettlementPolicy>(
            key: const ValueKey('policy-owner-only'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Owner only'),
            value: SettlementPolicy.ownerOnly,
            enabled: !disabled,
          ),
          RadioListTile<SettlementPolicy>(
            key: const ValueKey('policy-any-member'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Any member'),
            value: SettlementPolicy.anyMember,
            enabled: !disabled,
          ),
        ],
      ),
    );
  }

  Widget _buildMutationFeedback(
    BuildContext context,
    GroupPolicyMutationState state,
  ) {
    if (state.status == GroupPolicyMutationStatus.loading) {
      return Semantics(
        liveRegion: true,
        label: 'Updating settlement policy',
        child: const Padding(
          padding: EdgeInsets.only(top: DesignTokens.spacingSm),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: DesignTokens.spacingSm),
              Text('Updating settlement policy…'),
            ],
          ),
        ),
      );
    }
    if (state.status == GroupPolicyMutationStatus.success) {
      return Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.only(top: DesignTokens.spacingSm),
          child: Text(state.successMessage ?? 'Settlement policy updated.'),
        ),
      );
    }
    final failure = state.failure;
    if (state.status != GroupPolicyMutationStatus.failure || failure == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              failure.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          for (final fieldError in failure.fieldErrors.values)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.spacingXs),
              child: Text(fieldError),
            ),
          if (widget.effectiveMutationCubit!.canRetryPostMutationRefresh)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.spacingSm),
              child: OutlinedButton(
                key: const ValueKey('policy-retry-refresh'),
                onPressed: () => unawaited(
                  widget.effectiveMutationCubit!.retryPostMutationRefresh(),
                ),
                child: const Text('Retry refresh'),
              ),
            ),
        ],
      ),
    );
  }

  bool _canChangePolicy(SettlementPolicy policy) {
    final normalizedRole = widget.role.trim().toLowerCase();
    return normalizedRole == 'owner' ||
        normalizedRole == 'member' && policy == SettlementPolicy.anyMember;
  }

  String _policyLabel(SettlementPolicy policy) => switch (policy) {
    SettlementPolicy.ownerOnly => 'Owner only',
    SettlementPolicy.anyMember => 'Any member',
  };
}

typedef GroupReadScreen = GroupScreen;
