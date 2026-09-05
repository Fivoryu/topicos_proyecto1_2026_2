import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cuentas_claras_mobile/data/repositories/expenses_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/domain/write_models/write_models.dart';
import 'package:cuentas_claras_mobile/presentation/expenses/expense_mutation_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/expenses/expense_mutation_widgets.dart';
import 'package:cuentas_claras_mobile/presentation/expenses/expense_participant_selection.dart';

const _result = ExpenseReadModel(
  id: 'e-1',
  groupId: 'g-1',
  description: 'Dinner',
  amountCents: 1230,
  contributors: [],
  beneficiaries: [],
);

void main() {
  testWidgets('invalid fields show errors and make no writer calls', (t) async {
    final writer = _Writer();
    final cubit = _cubit(writer);
    await _pump(
      t,
      ExpenseWriteForm(cubit: cubit, participants: [_option('a', 'Ana')]),
    );
    await t.enterText(find.byType(TextFormField).at(1), 'not-money');
    await _tap(t, find.byType(CheckboxListTile).first);
    await _tap(t, find.widgetWithText(ElevatedButton, 'Add expense'));
    await t.pump();
    for (final error in [
      'Enter a description.',
      'Enter a valid positive amount.',
      'Enter a contribution amount.',
      'Select at least one beneficiary.',
    ]) {
      expect(find.text(error), findsOneWidget);
    }
    expect(writer.calls, isEmpty);
    expect(find.bySemanticsLabel('Description'), findsOneWidget);
    expect(find.bySemanticsLabel('Contract amount'), findsOneWidget);
    expect(
      t
          .getSemantics(find.text('Select at least one beneficiary.'))
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );
    for (final button in [
      ...find.byType(ElevatedButton).evaluate(),
      ...find.byType(OutlinedButton).evaluate(),
    ]) {
      expect(
        t.getSize(find.byWidget(button.widget)).height,
        greaterThanOrEqualTo(48),
      );
    }
    await cubit.close();
  });

  testWidgets('valid create preserves lexical values and reaches success', (
    t,
  ) async {
    final writer = _Writer();
    var cancelled = false;
    final cubit = _cubit(writer);
    await _pump(
      t,
      ExpenseWriteForm(
        cubit: cubit,
        participants: [_option('a', 'Ana'), _option('b', 'Bruno')],
        onCancel: () => cancelled = true,
      ),
    );
    await t.enterText(find.byType(TextFormField).at(0), '  Dinner  ');
    await t.enterText(find.byType(TextFormField).at(1), '12.3');
    await t.enterText(find.byType(TextFormField).at(2), '4.50');
    await _tap(t, find.widgetWithText(ElevatedButton, 'Add expense'));
    await _settle(t);
    expect(writer.calls, ['create']);
    expect(writer.draft!.description, '  Dinner  ');
    expect(writer.draft!.amount.text, '12.3');
    expect(writer.draft!.contributors.single.participantId, 'a');
    expect(writer.draft!.contributors.single.amount.text, '4.50');
    expect(writer.draft!.beneficiaryIds, ['a', 'b']);
    expect(find.text('Expense created.'), findsOneWidget);
    await _tap(t, find.widgetWithText(OutlinedButton, 'Cancel'));
    expect(cancelled, isTrue);
    await cubit.close();
  });

  testWidgets('edit retains archived IDs and loading blocks duplicates', (
    t,
  ) async {
    final writer = _Writer()..pending = Completer<ExpenseReadModel>();
    final cubit = _cubit(writer);
    const expense = ExpenseReadModel(
      id: 'e-1',
      groupId: 'g-1',
      description: 'Trip',
      amountCents: 750,
      contributors: [
        ExpenseContributorReadModel(
          participantId: 'old',
          name: 'Former',
          archived: true,
          amountCents: 750,
        ),
      ],
      beneficiaries: [
        ExpenseBeneficiaryReadModel(
          participantId: 'old',
          name: 'Former',
          archived: true,
        ),
      ],
    );
    await _pump(
      t,
      ExpenseWriteForm(
        cubit: cubit,
        expense: expense,
        participants: [
          _option('a', 'Ana'),
          const ExpenseParticipantOption(
            id: 'old',
            name: 'Former',
            archived: true,
          ),
        ],
        onCancel: () {},
      ),
    );
    await _tap(t, find.widgetWithText(ElevatedButton, 'Save changes'));
    await _tap(t, find.widgetWithText(ElevatedButton, 'Save changes'));
    await t.pump();
    expect(writer.calls, ['edit:e-1']);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      t.widget<ElevatedButton>(find.byType(ElevatedButton).last).onPressed,
      isNull,
    );
    expect(
      t
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Cancel'))
          .onPressed,
      isNull,
    );
    writer.pending!.complete(_result);
    await _settle(t);
    expect(writer.draft!.contributors.single.participantId, 'old');
    expect(writer.draft!.beneficiaryIds, ['old']);
    await cubit.close();
  });

  testWidgets(
    'delete cancellation and dialog dismissal never call the writer',
    (t) async {
      final dismissals = <Future<void> Function(WidgetTester)>[
        (tester) => tester.tap(find.text('Cancel')),
        (tester) => tester.tapAt(const Offset(1, 1)),
        (tester) => tester.binding.handlePopRoute(),
      ];
      for (final dismiss in dismissals) {
        final writer = _Writer();
        final cubit = _cubit(writer);
        await _pump(t, ExpenseDeleteAction(cubit: cubit, expense: _result));
        await _tap(t, find.widgetWithText(OutlinedButton, 'Delete expense'));
        await t.pump();
        await dismiss(t);
        await t.pump();
        expect(writer.calls, isEmpty);
        await cubit.close();
      }
    },
  );

  testWidgets('confirmed delete runs once with accessible loading feedback', (
    t,
  ) async {
    final writer = _Writer()..pendingDelete = Completer<void>();
    final cubit = _cubit(writer);
    await _pump(t, ExpenseDeleteAction(cubit: cubit, expense: _result));

    final action = find.byType(OutlinedButton).first;
    expect(action, findsOneWidget);
    expect(find.bySemanticsLabel('Delete expense'), findsOneWidget);
    expect(t.getSize(action).height, greaterThanOrEqualTo(48));
    await _tap(t, action);
    await t.pump();
    expect(find.text('Delete expense?'), findsOneWidget);
    await _tap(t, find.widgetWithText(TextButton, 'Delete'));
    await t.pump();

    expect(writer.calls, ['delete:e-1']);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(t.widget<OutlinedButton>(action).onPressed, isNull);
    expect(
      t
          .getSemantics(find.bySemanticsLabel('Deleting expense'))
          .flagsCollection
          .isButton,
      isTrue,
    );
    await t.tap(action);
    await t.pump();
    expect(writer.calls, ['delete:e-1']);

    writer.pendingDelete!.complete();
    await _settle(t);
    expect(cubit.state.result, isNull);
    expect(find.text('Expense deleted.'), findsOneWidget);
    await cubit.close();
  });

  testWidgets(
    'delete server failure stays visible with an actionable retry path',
    (t) async {
      final writer = _Writer()..deleteError = StateError('delete failed');
      final cubit = _cubit(writer);
      await _pump(t, ExpenseDeleteAction(cubit: cubit, expense: _result));
      await _tap(t, find.widgetWithText(OutlinedButton, 'Delete expense'));
      await t.pump();
      await _tap(t, find.widgetWithText(TextButton, 'Delete'));
      await _settle(t);

      expect(writer.calls, ['delete:e-1']);
      expect(find.text('Please try again.'), findsOneWidget);
      expect(
        t
            .getSemantics(find.text('Please try again.'))
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Delete expense'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Retry refresh'),
        findsNothing,
      );
      await cubit.close();
    },
  );

  testWidgets(
    'delete refresh failure exposes live recovery and retries without repeating delete',
    (t) async {
      var retryCalls = 0;
      final writer = _Writer();
      final cubit = ExpenseMutationCubit(
        writer: writer,
        groupId: 'g-1',
        onMutationSuccess: () async => throw StateError('refresh failed'),
        onPostMutationRefreshRetry: () async => retryCalls++,
      );
      await _pump(t, ExpenseDeleteAction(cubit: cubit, expense: _result));
      await _tap(t, find.widgetWithText(OutlinedButton, 'Delete expense'));
      await t.pump();
      await _tap(t, find.widgetWithText(TextButton, 'Delete'));
      await _settle(t);

      expect(writer.calls, ['delete:e-1']);
      expect(find.text('Please try again.'), findsOneWidget);
      expect(
        t
            .getSemantics(find.text('Please try again.'))
            .flagsCollection
            .isLiveRegion,
        isTrue,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Retry refresh'),
        findsOneWidget,
      );
      await _tap(t, find.widgetWithText(OutlinedButton, 'Retry refresh'));
      await _settle(t);

      expect(retryCalls, 1);
      expect(writer.calls, ['delete:e-1']);
      expect(cubit.state.result, isNull);
      expect(find.text('Expense deleted.'), findsOneWidget);
      await cubit.close();
    },
  );
}

ExpenseParticipantOption _option(String id, String name) =>
    ExpenseParticipantOption(id: id, name: name, archived: false);

ExpenseMutationCubit _cubit(ExpensesWriter writer) =>
    ExpenseMutationCubit(writer: writer, groupId: 'g-1');

Future<void> _pump(WidgetTester t, Widget child) =>
    t.pumpWidget(MaterialApp(home: Scaffold(body: child)));

Future<void> _tap(WidgetTester t, Finder finder) async {
  await t.ensureVisible(finder);
  await t.tap(finder);
}

Future<void> _settle(WidgetTester t) => t.pumpAndSettle();

class _Writer implements ExpensesWriter {
  final calls = <String>[];
  ExpenseWriteDraft? draft;
  Completer<ExpenseReadModel>? pending;
  Completer<void>? pendingDelete;
  Object? deleteError;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final args = invocation.positionalArguments;
    if (invocation.memberName == #deleteExpense) {
      calls.add('delete:${args[1]}');
      final error = deleteError;
      if (error != null) return Future<void>.error(error);
      return pendingDelete?.future ?? Future<void>.value();
    }
    final editing = invocation.memberName == #editExpense;
    calls.add(editing ? 'edit:${args[1]}' : 'create');
    draft = args[editing ? 2 : 1] as ExpenseWriteDraft;
    return pending?.future ?? Future.value(_result);
  }
}
