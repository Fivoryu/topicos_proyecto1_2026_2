import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/formatters/cents_formatter.dart';
import '../../core/theme/tokens.dart';
import '../read_status.dart';
import '../read_view_helpers.dart';
import 'settlement_cubit.dart';

/// Read-only settlement view; ordered transfers or the all-settled empty state.
class SettlementScreen extends StatefulWidget {
  const SettlementScreen({
    required this.cubit,
    this.loadOnOpen = true,
    super.key,
  });

  final SettlementCubit cubit;
  final bool loadOnOpen;

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.loadOnOpen) unawaited(widget.cubit.load());
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<SettlementState>(
    stream: widget.cubit.stream,
    initialData: widget.cubit.state,
    builder: (context, snapshot) {
      final state = snapshot.data ?? widget.cubit.state;
      if (state.status != ReadStatus.loaded &&
          state.status != ReadStatus.empty) {
        return ReadStateMessage(
          status: state.status,
          resource: 'settlement',
          message: state.message,
          onRetry: widget.cubit.reload,
        );
      }
      final settlement = state.settlement;
      if (settlement == null || settlement.settled) {
        return const ReadCard(child: Text('Everyone is settled'));
      }
      return ReadCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transfers', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: DesignTokens.spacingSm),
            ...settlement.transfers.map(
              (transfer) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: DesignTokens.spacingXs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${transfer.fromName} → ${transfer.toName}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      formatCents(transfer.amountCents),
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

typedef SettlementReadScreen = SettlementScreen;
