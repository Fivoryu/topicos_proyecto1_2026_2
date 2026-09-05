import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/data/repositories/expenses_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/participants_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/domain/write_models/write_models.dart';
import 'package:cuentas_claras_mobile/presentation/expenses/expense_history_screen.dart';
import 'package:cuentas_claras_mobile/presentation/expenses/expense_mutation_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/expenses/expense_mutation_widgets.dart';
import 'package:cuentas_claras_mobile/presentation/expenses/expenses_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/participants/participants_cubit.dart';

void main() {
  testWidgets(
    'wires create, edit, and delete actions when mutation is supplied',
    (tester) async {
      final writer = _HistoryWriter();
      final expenses = ExpensesCubit(
        reader: _HistoryExpensesReader(),
        groupId: 'group-1',
      );
      final participants = ParticipantsCubit(
        reader: _HistoryParticipantsReader(),
        groupId: 'group-1',
      );
      final mutation = ExpenseMutationCubit(writer: writer, groupId: 'group-1');
      await expenses.load();
      await participants.load();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseHistoryScreen(
              cubit: expenses,
              participantsCubit: participants,
              mutationCubit: mutation,
              loadOnOpen: false,
            ),
          ),
        ),
      );

      expect(find.byType(ExpenseWriteForm), findsOneWidget);
      expect(find.byType(ExpenseDeleteAction), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'New dinner');
      await tester.enterText(find.byType(TextFormField).at(1), '12.00');
      await tester.enterText(find.byType(TextFormField).at(2), '12.00');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add expense'));
      await tester.pumpAndSettle();
      expect(writer.commands, ['create']);

      await tester.ensureVisible(find.text('Edit'));
      await tester.tap(find.text('Edit'));
      await tester.pump();
      expect(find.byType(ExpenseWriteForm), findsNWidgets(2));
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Save changes'),
      );
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save changes'));
      await tester.pumpAndSettle();
      expect(writer.commands, ['create', 'edit:expense-1']);

      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Delete expense').first,
      );
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Delete expense').first,
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(writer.commands, ['create', 'edit:expense-1', 'delete:expense-1']);

      await expenses.close();
      await participants.close();
      await mutation.close();
    },
  );

  testWidgets(
    'keeps displayed expense state until the authoritative REST refresh',
    (tester) async {
      final reader = _MutableHistoryExpensesReader();
      final expenses = ExpensesCubit(reader: reader, groupId: 'group-1');
      final participants = ParticipantsCubit(
        reader: _HistoryParticipantsReader(),
        groupId: 'group-1',
      );
      final writer = _PendingHistoryWriter();
      final mutation = ExpenseMutationCubit(
        writer: writer,
        groupId: 'group-1',
        onMutationSuccess: () async {
          reader.data = const [_refreshedHistoryExpense];
          await expenses.load(propagateFailure: true);
        },
      );
      await expenses.load();
      await participants.load();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseHistoryScreen(
              cubit: expenses,
              participantsCubit: participants,
              mutationCubit: mutation,
              loadOnOpen: false,
            ),
          ),
        ),
      );
      expect(find.text('Lodging'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Draft');
      await tester.enterText(find.byType(TextFormField).at(1), '12.00');
      await tester.enterText(find.byType(TextFormField).at(2), '12.00');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add expense'));
      await tester.pump();

      expect(writer.commands, ['create']);
      expect(find.text('Lodging'), findsOneWidget);
      expect(find.text('Server refreshed dinner'), findsNothing);
      expect(expenses.state.expenses.single.description, 'Lodging');

      writer.createResponse.complete(_refreshedHistoryExpense);
      await tester.pumpAndSettle();

      expect(find.text('Lodging'), findsNothing);
      expect(find.text('Server refreshed dinner'), findsOneWidget);
      expect(
        expenses.state.expenses.single.description,
        'Server refreshed dinner',
      );

      await expenses.close();
      await participants.close();
      await mutation.close();
    },
  );

  testWidgets('keeps empty history guidance with mutation controls', (
    tester,
  ) async {
    final expenses = ExpensesCubit(
      reader: _EmptyHistoryExpensesReader(),
      groupId: 'group-1',
    );
    final participants = ParticipantsCubit(
      reader: _HistoryParticipantsReader(),
      groupId: 'group-1',
    );
    final mutation = ExpenseMutationCubit(
      writer: _HistoryWriter(),
      groupId: 'group-1',
    );
    await expenses.load();
    await participants.load();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseHistoryScreen(
            cubit: expenses,
            participantsCubit: participants,
            mutationCubit: mutation,
            loadOnOpen: false,
          ),
        ),
      ),
    );

    expect(find.text('No expenses recorded yet.'), findsOneWidget);
    expect(find.byType(ExpenseWriteForm), findsOneWidget);
    expect(find.byType(ExpenseDeleteAction), findsNothing);
    expect(find.text('Edit'), findsNothing);

    await expenses.close();
    await participants.close();
    await mutation.close();
  });

  testWidgets('keeps expense history read-only when mutation is omitted', (
    tester,
  ) async {
    final expenses = ExpensesCubit(
      reader: _HistoryExpensesReader(),
      groupId: 'group-1',
    );
    await expenses.load();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseHistoryScreen(cubit: expenses, loadOnOpen: false),
        ),
      ),
    );

    expect(find.text('Lodging'), findsOneWidget);
    expect(find.byType(ExpenseWriteForm), findsNothing);
    expect(find.byType(ExpenseDeleteAction), findsNothing);
    expect(find.text('Edit'), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);

    await expenses.close();
  });
}

class _MutableHistoryExpensesReader implements ExpensesReader {
  List<ExpenseReadModel> data = const [_historyExpense];

  @override
  Future<List<ExpenseReadModel>> listExpenses(String groupId) async => data;
}

class _EmptyHistoryExpensesReader implements ExpensesReader {
  @override
  Future<List<ExpenseReadModel>> listExpenses(String groupId) async => const [];
}

class _PendingHistoryWriter implements ExpensesWriter {
  final commands = <String>[];
  final createResponse = Completer<ExpenseReadModel>();

  @override
  Future<ExpenseReadModel> createExpense(
    String groupId,
    ExpenseWriteDraft draft,
  ) async {
    commands.add('create');
    return createResponse.future;
  }

  @override
  Future<ExpenseReadModel> editExpense(
    String groupId,
    String expenseId,
    ExpenseWriteDraft draft,
  ) async {
    commands.add('edit:$expenseId');
    return _historyExpense;
  }

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {
    commands.add('delete:$expenseId');
  }
}

class _HistoryExpensesReader implements ExpensesReader {
  @override
  Future<List<ExpenseReadModel>> listExpenses(String groupId) =>
      Future.value(const [_historyExpense]);
}

class _HistoryParticipantsReader implements ParticipantsReader {
  @override
  Future<List<ParticipantReadModel>> listParticipants(String groupId) =>
      Future.value(const [_historyParticipant]);
}

class _HistoryWriter implements ExpensesWriter {
  final commands = <String>[];

  @override
  Future<ExpenseReadModel> createExpense(
    String groupId,
    ExpenseWriteDraft draft,
  ) async {
    commands.add('create');
    return _historyExpense;
  }

  @override
  Future<ExpenseReadModel> editExpense(
    String groupId,
    String expenseId,
    ExpenseWriteDraft draft,
  ) async {
    commands.add('edit:$expenseId');
    return _historyExpense;
  }

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {
    commands.add('delete:$expenseId');
  }
}

const _historyParticipant = ParticipantReadModel(
  id: 'participant-1',
  groupId: 'group-1',
  name: 'Ana',
  archived: false,
);

const _refreshedHistoryExpense = ExpenseReadModel(
  id: 'expense-1',
  groupId: 'group-1',
  description: 'Server refreshed dinner',
  amountCents: 96000,
  contributors: [
    ExpenseContributorReadModel(
      participantId: 'participant-1',
      name: 'Ana',
      archived: false,
      amountCents: 96000,
    ),
  ],
  beneficiaries: [
    ExpenseBeneficiaryReadModel(
      participantId: 'participant-1',
      name: 'Ana',
      archived: false,
    ),
  ],
);

const _historyExpense = ExpenseReadModel(
  id: 'expense-1',
  groupId: 'group-1',
  description: 'Lodging',
  amountCents: 96000,
  contributors: [
    ExpenseContributorReadModel(
      participantId: 'participant-1',
      name: 'Ana',
      archived: false,
      amountCents: 96000,
    ),
  ],
  beneficiaries: [
    ExpenseBeneficiaryReadModel(
      participantId: 'participant-1',
      name: 'Ana',
      archived: false,
    ),
  ],
);
