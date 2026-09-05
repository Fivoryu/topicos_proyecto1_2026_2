import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/formatters/cents_formatter.dart';
import '../../core/theme/tokens.dart';
import '../../domain/read_models/read_models.dart';
import '../participants/participants_cubit.dart';
import '../read_status.dart';
import '../read_view_helpers.dart';
import 'expense_mutation_cubit.dart';
import 'expense_mutation_widgets.dart';
import 'expense_participant_selection.dart';
import 'expenses_cubit.dart';

/// Expense history with optional mutation controls supplied by the domain scope.
class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({
    required this.cubit,
    this.loadOnOpen = true,
    this.mutationCubit,
    this.participantsCubit,
    super.key,
  });

  final ExpensesCubit cubit;
  final bool loadOnOpen;
  final ExpenseMutationCubit? mutationCubit;
  final ParticipantsCubit? participantsCubit;

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  String? _editingExpenseId;

  @override
  void initState() {
    super.initState();
    if (widget.loadOnOpen) {
      unawaited(widget.cubit.load());
      final participantsCubit = widget.participantsCubit;
      if (participantsCubit != null &&
          participantsCubit.state.status == ReadStatus.loading) {
        unawaited(participantsCubit.load());
      }
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<ExpensesState>(
    stream: widget.cubit.stream,
    initialData: widget.cubit.state,
    builder: (context, snapshot) {
      final state = snapshot.data ?? widget.cubit.state;
      final mutationCubit = widget.mutationCubit;
      if (state.status != ReadStatus.loaded &&
          state.status != ReadStatus.empty) {
        return _buildReadFailure(context, state, mutationCubit);
      }
      if (mutationCubit == null) {
        return state.expenses.isEmpty
            ? const ReadCard(child: Text('No expenses recorded yet.'))
            : _buildReadOnlyList(context, state);
      }
      return StreamBuilder<ParticipantsState>(
        stream: widget.participantsCubit?.stream,
        initialData: widget.participantsCubit?.state,
        builder: (context, participantsSnapshot) {
          final participantsState =
              participantsSnapshot.data ?? widget.participantsCubit?.state;
          final participants = participantsState?.participants ?? const [];
          return _buildMutationView(
            context,
            state,
            mutationCubit,
            participants,
          );
        },
      );
    },
  );

  Widget _buildReadFailure(
    BuildContext context,
    ExpensesState state,
    ExpenseMutationCubit? mutationCubit,
  ) {
    final retryMutation = mutationCubit?.canRetryPostMutationRefresh == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReadStateMessage(
          status: state.status,
          resource: 'expenses',
          message: state.message,
          onRetry: retryMutation ? null : widget.cubit.reload,
        ),
        if (retryMutation)
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingSm),
            child: OutlinedButton(
              onPressed: () =>
                  unawaited(mutationCubit!.retryPostMutationRefresh()),
              child: const Text('Retry refresh'),
            ),
          ),
      ],
    );
  }

  Widget _buildMutationView(
    BuildContext context,
    ExpensesState state,
    ExpenseMutationCubit mutationCubit,
    Iterable<ParticipantReadModel> participants,
  ) {
    final options = selectableExpenseParticipants(participants: participants);
    final mutationState = mutationCubit.state;
    return StreamBuilder<ExpenseMutationState>(
      stream: mutationCubit.stream,
      initialData: mutationState,
      builder: (context, snapshot) {
        final currentMutation = snapshot.data ?? mutationCubit.state;
        // The outer history view owns scrolling for embedded mutation content.
        return SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExpenseWriteForm(
                cubit: mutationCubit,
                participants: options,
                scrollable: false,
              ),
              const SizedBox(height: DesignTokens.spacingSm),
              if (state.expenses.isEmpty)
                const ReadCard(child: Text('No expenses recorded yet.'))
              else
                _buildEditableList(
                  context,
                  state,
                  mutationCubit,
                  currentMutation.isDisabled,
                  participants,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadOnlyList(BuildContext context, ExpensesState state) =>
      ReadCard(
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
                child: _expenseDetails(context, expense),
              ),
            ),
          ],
        ),
      );

  Widget _buildEditableList(
    BuildContext context,
    ExpensesState state,
    ExpenseMutationCubit mutationCubit,
    bool mutationDisabled,
    Iterable<ParticipantReadModel> participants,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ReadCard(
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _expenseDetails(context, expense),
                    TextButton(
                      onPressed: mutationDisabled
                          ? null
                          : () => _startEditing(expense.id),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      for (final expense in state.expenses)
        if (_editingExpenseId == expense.id) ...[
          ExpenseWriteForm(
            key: ValueKey('edit-${expense.id}'),
            cubit: mutationCubit,
            participants: selectableExpenseParticipants(
              participants: participants,
              existingExpense: expense,
            ),
            expense: expense,
            scrollable: false,
            onCancel: _cancelEditing,
          ),
          const SizedBox(height: DesignTokens.spacingSm),
        ],
      for (final expense in state.expenses) ...[
        ExpenseDeleteAction(cubit: mutationCubit, expense: expense),
        const SizedBox(height: DesignTokens.spacingSm),
      ],
    ],
  );

  Widget _expenseDetails(
    BuildContext context,
    ExpenseReadModel expense,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(expense.description, style: Theme.of(context).textTheme.bodyLarge),
      Text(
        formatCents(expense.amountCents),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      Text(
        expense.beneficiaries.map((beneficiary) => beneficiary.name).join(', '),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  void _startEditing(String expenseId) {
    if (!mounted) return;
    setState(() => _editingExpenseId = expenseId);
  }

  void _cancelEditing() {
    if (!mounted) return;
    setState(() => _editingExpenseId = null);
  }
}

typedef ExpenseHistoryReadScreen = ExpenseHistoryScreen;
