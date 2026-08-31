import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/formatters/cents_formatter.dart';
import '../../core/theme/tokens.dart';
import '../read_status.dart';
import '../read_view_helpers.dart';
import 'expenses_cubit.dart';

/// Read-only expense history; never offers expense write controls.
class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({
    required this.cubit,
    this.loadOnOpen = true,
    super.key,
  });

  final ExpensesCubit cubit;
  final bool loadOnOpen;

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.loadOnOpen) unawaited(widget.cubit.load());
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<ExpensesState>(
    stream: widget.cubit.stream,
    initialData: widget.cubit.state,
    builder: (context, snapshot) {
      final state = snapshot.data ?? widget.cubit.state;
      if (state.status != ReadStatus.loaded &&
          state.status != ReadStatus.empty) {
        return ReadStateMessage(status: state.status, resource: 'expenses');
      }
      if (state.expenses.isEmpty) {
        return const ReadCard(child: Text('No expenses recorded yet.'));
      }
      return ReadCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense history',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            ...state.expenses.map(
              (expense) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: DesignTokens.spacingXs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      formatCents(expense.amountCents),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      expense.beneficiaries
                          .map((beneficiary) => beneficiary.name)
                          .join(', '),
                      style: Theme.of(context).textTheme.bodySmall,
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

typedef ExpenseHistoryReadScreen = ExpenseHistoryScreen;
