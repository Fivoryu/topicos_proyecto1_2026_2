import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../domain/read_models/read_models.dart';
import '../read_status.dart';
import '../read_view_helpers.dart';
import 'group_cubit.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({required this.cubit, this.loadOnOpen = true, super.key});

  final GroupCubit cubit;
  final bool loadOnOpen;

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
      final group = state.group!;
      final policy = switch (group.settlementPolicy) {
        SettlementPolicy.ownerOnly => 'Owner only',
        SettlementPolicy.anyMember => 'Any member',
      };
      return ReadCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Group', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: DesignTokens.spacingXs),
            Text(group.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: DesignTokens.spacingMd),
            Text(
              'Settlement policy',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(policy, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    },
  );
}

typedef GroupReadScreen = GroupScreen;
