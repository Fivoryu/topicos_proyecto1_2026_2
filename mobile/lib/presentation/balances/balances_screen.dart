import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/formatters/cents_formatter.dart';
import '../../core/theme/tokens.dart';
import '../read_status.dart';
import '../read_view_helpers.dart';
import 'balances_cubit.dart';

/// Read-only balances view; never offers money mutations.
class BalancesScreen extends StatefulWidget {
  const BalancesScreen({
    required this.cubit,
    this.loadOnOpen = true,
    super.key,
  });

  final BalancesCubit cubit;
  final bool loadOnOpen;

  @override
  State<BalancesScreen> createState() => _BalancesScreenState();
}

class _BalancesScreenState extends State<BalancesScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.loadOnOpen) unawaited(widget.cubit.load());
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<BalancesState>(
    stream: widget.cubit.stream,
    initialData: widget.cubit.state,
    builder: (context, snapshot) {
      final state = snapshot.data ?? widget.cubit.state;
      if (state.status != ReadStatus.loaded &&
          state.status != ReadStatus.empty) {
        return ReadStateMessage(status: state.status, resource: 'balances');
      }
      final participants = state.balances?.participants ?? const [];
      return ReadCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balances', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: DesignTokens.spacingSm),
            ...participants.map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: DesignTokens.spacingXs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.archived ? '${row.name} (archived)' : row.name,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      formatCents(row.balanceCents),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

typedef BalancesReadScreen = BalancesScreen;
