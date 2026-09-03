import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/data/repositories/balances_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/expenses_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/group_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/participants_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/repository_support.dart';
import 'package:cuentas_claras_mobile/data/repositories/settlement_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/presentation/balances/balances_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/balances/balances_screen.dart';
import 'package:cuentas_claras_mobile/presentation/expenses/expense_history_screen.dart';
import 'package:cuentas_claras_mobile/presentation/expenses/expenses_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/group/group_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/group/group_screen.dart';
import 'package:cuentas_claras_mobile/presentation/participants/participant_lifecycle_actions.dart';
import 'package:cuentas_claras_mobile/presentation/participants/participants_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/participants/participants_mutation_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/participants/participants_mutation_widgets.dart';
import 'package:cuentas_claras_mobile/presentation/participants/participants_screen.dart';
import 'package:cuentas_claras_mobile/presentation/settlement/settlement_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/settlement/settlement_screen.dart';
import 'package:cuentas_claras_mobile/presentation/read_status.dart';

void main() {
  testWidgets('renders group policy and current participant names', (
    tester,
  ) async {
    final groupCubit = GroupCubit(reader: _GroupReader(), groupId: 'group-1');
    final participantsCubit = ParticipantsCubit(
      reader: _ParticipantsReader(),
      groupId: 'group-1',
    );
    await groupCubit.load();
    await participantsCubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: [
            GroupScreen(cubit: groupCubit, loadOnOpen: false),
            ParticipantsScreen(cubit: participantsCubit, loadOnOpen: false),
          ],
        ),
      ),
    );

    expect(find.text('Samaipata'), findsOneWidget);
    expect(find.text('Owner only'), findsOneWidget);
    expect(find.text('Ana Renamed'), findsOneWidget);
    expect(find.text('Former guest'), findsOneWidget);
    expect(find.text('Archived'), findsOneWidget);

    await groupCubit.close();
    await participantsCubit.close();
  });

  testWidgets(
    'renders DA-01 balances and archived zero with the shared formatter',
    (tester) async {
      final cubit = BalancesCubit(
        reader: _BalancesReader(),
        groupId: 'group-1',
      );
      await cubit.load();

      await tester.pumpWidget(
        MaterialApp(home: BalancesScreen(cubit: cubit, loadOnOpen: false)),
      );

      expect(find.text('Bs. 560.00'), findsAtLeastNWidgets(1));
      expect(find.text('-Bs. 160.00'), findsOneWidget);
      expect(find.text('-Bs. 400.00'), findsOneWidget);
      expect(find.text('Former guest (archived)'), findsOneWidget);
      expect(find.text('Bs. 0.00'), findsAtLeastNWidgets(1));
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);

      await cubit.close();
    },
  );

  testWidgets('renders all-settled state without transfer controls', (
    tester,
  ) async {
    final cubit = SettlementCubit(
      reader: _SettlementReader(
        const SettlementReadModel(
          groupId: 'group-1',
          settlementPolicy: SettlementPolicy.ownerOnly,
          settled: true,
          transfers: [],
        ),
      ),
      groupId: 'group-1',
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(home: SettlementScreen(cubit: cubit, loadOnOpen: false)),
    );

    expect(find.text('Everyone is settled'), findsOneWidget);
    expect(find.text('Transfers'), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);

    await cubit.close();
  });

  testWidgets(
    'renders expense history and never exposes expense write controls',
    (tester) async {
      final cubit = ExpensesCubit(
        reader: _ExpensesReader(),
        groupId: 'group-1',
      );
      await cubit.load();

      await tester.pumpWidget(
        MaterialApp(
          home: ExpenseHistoryScreen(cubit: cubit, loadOnOpen: false),
        ),
      );

      expect(find.text('Lodging'), findsOneWidget);
      expect(find.text('Bs. 960.00'), findsOneWidget);
      expect(find.text('Ana Renamed'), findsOneWidget);
      expect(find.text('Create expense'), findsNothing);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);

      await cubit.close();
    },
  );

  testWidgets('keeps archived participant visible in expense history', (
    tester,
  ) async {
    final cubit = ExpensesCubit(
      reader: _ExpensesReader(data: const [_archivedExpense]),
      groupId: 'group-1',
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(home: ExpenseHistoryScreen(cubit: cubit, loadOnOpen: false)),
    );

    expect(find.text('Former guest'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('gives add-first guidance when there are no participants', (
    tester,
  ) async {
    final cubit = ParticipantsCubit(
      reader: _EmptyParticipantsReader(),
      groupId: 'group-1',
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(home: ParticipantsScreen(cubit: cubit, loadOnOpen: false)),
    );

    expect(find.textContaining('Add participants first'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('read-only participants screen has no mutation controls', (
    tester,
  ) async {
    final cubit = ParticipantsCubit(
      reader: _ParticipantsReader(),
      groupId: 'group-1',
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(home: ParticipantsScreen(cubit: cubit, loadOnOpen: false)),
    );

    expect(find.byType(ParticipantNameForm), findsNothing);
    expect(find.byType(ParticipantLifecycleActions), findsNothing);
    expect(find.text('Rename'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    await cubit.close();
  });

  testWidgets('supplied mutation Cubit exposes participant actions', (
    tester,
  ) async {
    final readCubit = ParticipantsCubit(
      reader: _ParticipantsReader(),
      groupId: 'group-1',
    );
    final mutationCubit = _mutationCubit();
    await readCubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: ParticipantsScreen(
          cubit: readCubit,
          loadOnOpen: false,
          mutationCubit: mutationCubit,
        ),
      ),
    );

    expect(find.text('Add participant'), findsNWidgets(2));
    expect(find.text('Rename'), findsNWidgets(2));
    expect(find.byType(ParticipantLifecycleActions), findsNWidgets(2));
    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('Reactivate'), findsOneWidget);
    expect(find.text('Delete'), findsNWidgets(2));
    await readCubit.close();
    await mutationCubit.close();
  });

  testWidgets('keeps protected participant after delete is rejected', (
    tester,
  ) async {
    final readCubit = ParticipantsCubit(
      reader: _ParticipantsReader(),
      groupId: 'group-1',
    );
    final protectedError = DioException(
      requestOptions: RequestOptions(path: '/participants/archived-id'),
      response: Response<dynamic>(
        statusCode: 409,
        data: <String, dynamic>{
          'error_code': 'participant_in_use',
          'message': 'Referenced by history.',
        },
        requestOptions: RequestOptions(path: '/participants/archived-id'),
      ),
    );
    final mutationCubit = _mutationCubit(
      _ParticipantsMutationWriter(deleteFailure: protectedError),
    );
    await readCubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: ParticipantsScreen(
          cubit: readCubit,
          loadOnOpen: false,
          mutationCubit: mutationCubit,
        ),
      ),
    );

    final deleteButtons = find.widgetWithText(OutlinedButton, 'Delete');
    expect(deleteButtons, findsNWidgets(2));
    await tester.ensureVisible(deleteButtons.last);
    await tester.pump();
    await tester.tap(deleteButtons.last);
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Former guest'), findsOneWidget);
    expect(
      find.text(
        'This participant is protected by historical references; '
        'archive it instead of deleting it.',
      ),
      findsAtLeastNWidgets(1),
    );
    expect(
      mutationCubit.state.failure?.kind,
      MutationFailureKind.protectedReference,
    );

    await readCubit.close();
    await mutationCubit.close();
  });

  testWidgets('shows one completion message only in mutation mode', (
    tester,
  ) async {
    final readCubit = ParticipantsCubit(
      reader: _ParticipantsReader(),
      groupId: 'group-1',
    );
    final mutationCubit = _mutationCubit();
    await readCubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: ParticipantsScreen(
          cubit: readCubit,
          loadOnOpen: false,
          mutationCubit: mutationCubit,
        ),
      ),
    );

    await mutationCubit.add('New participant');
    await tester.pump();

    expect(find.text('Participant added.'), findsOneWidget);
    expect(find.byType(ParticipantMutationFeedback), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: ParticipantsScreen(cubit: readCubit, loadOnOpen: false),
      ),
    );
    expect(find.text('Participant added.'), findsNothing);
    expect(find.byType(ParticipantNameForm), findsNothing);
    expect(find.byType(ParticipantLifecycleActions), findsNothing);

    await readCubit.close();
    await mutationCubit.close();
  });

  testWidgets(
    'shows one accessible participant refresh retry only in mutation mode',
    (tester) async {
      final readCubit = ParticipantsCubit(
        reader: _ParticipantsReader(),
        groupId: 'group-1',
      );
      final mutationCubit = ParticipantsMutationCubit(
        writer: _ParticipantsMutationWriter(),
        groupId: 'group-1',
        onMutationSuccess: () async => throw StateError('refresh failed'),
        onPostMutationRefreshRetry: () async {},
      );
      await readCubit.load();
      await mutationCubit.add('Ana');

      await tester.pumpWidget(
        MaterialApp(
          home: ParticipantsScreen(
            cubit: readCubit,
            loadOnOpen: false,
            mutationCubit: mutationCubit,
          ),
        ),
      );

      final retry = find.widgetWithText(OutlinedButton, 'Retry refresh');
      expect(retry, findsOneWidget);
      expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));

      await tester.pumpWidget(
        MaterialApp(
          home: ParticipantsScreen(cubit: readCubit, loadOnOpen: false),
        ),
      );
      expect(find.text('Retry refresh'), findsNothing);
      expect(find.byType(ParticipantNameForm), findsNothing);

      await readCubit.close();
      await mutationCubit.close();
    },
  );

  testWidgets(
    'keeps post-mutation refresh retry visible when read refresh fails',
    (tester) async {
      final reader = _ParticipantsReader();
      final readCubit = ParticipantsCubit(reader: reader, groupId: 'group-1');
      final writer = _ParticipantsMutationWriter();
      final mutationCubit = ParticipantsMutationCubit(
        writer: writer,
        groupId: 'group-1',
        onMutationSuccess: () => readCubit.load(propagateFailure: true),
        onPostMutationRefreshRetry: () {
          reader.failure = null;
          return readCubit.load(propagateFailure: true);
        },
      );
      await readCubit.load();
      reader.failure = const ReadRepositoryException('participants offline');

      await tester.pumpWidget(
        MaterialApp(
          home: ParticipantsScreen(
            cubit: readCubit,
            loadOnOpen: false,
            mutationCubit: mutationCubit,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'New participant');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add participant'));
      await tester.pumpAndSettle();

      expect(find.text('participants offline'), findsOneWidget);
      expect(find.text('Retry refresh'), findsOneWidget);
      expect(find.text('Retry participants'), findsNothing);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Retry refresh'));
      await tester.pumpAndSettle();

      expect(writer.commands, ['add']);
      expect(find.text('Participant added.'), findsOneWidget);
      expect(find.text('Retry refresh'), findsNothing);

      await readCubit.close();
      await mutationCubit.close();
    },
  );

  testWidgets('rename opens with the current name and Cancel exits', (
    tester,
  ) async {
    final readCubit = ParticipantsCubit(
      reader: _ParticipantsReader(),
      groupId: 'group-1',
    );
    final mutationCubit = _mutationCubit();
    await readCubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: ParticipantsScreen(
          cubit: readCubit,
          loadOnOpen: false,
          mutationCubit: mutationCubit,
        ),
      ),
    );
    await tester.tap(find.text('Rename').first);
    await tester.pump();

    expect(find.text('Rename participant'), findsOneWidget);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .any((field) => field.controller?.text == 'Ana Renamed'),
      isTrue,
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pump();
    expect(find.text('Rename participant'), findsNothing);
    expect(find.byType(ParticipantNameForm), findsOneWidget);
    await readCubit.close();
    await mutationCubit.close();
  });

  testWidgets(
    'supplied mutation Cubit keeps empty-state guidance and add form',
    (tester) async {
      final readCubit = ParticipantsCubit(
        reader: _EmptyParticipantsReader(),
        groupId: 'group-1',
      );
      final mutationCubit = _mutationCubit();
      await readCubit.load();

      await tester.pumpWidget(
        MaterialApp(
          home: ParticipantsScreen(
            cubit: readCubit,
            loadOnOpen: false,
            mutationCubit: mutationCubit,
          ),
        ),
      );

      expect(find.textContaining('Add participants first'), findsOneWidget);
      expect(find.byType(ParticipantNameForm), findsOneWidget);
      await readCubit.close();
      await mutationCubit.close();
    },
  );

  testWidgets('mutation progress and completion never replace read data', (
    tester,
  ) async {
    final readCubit = ParticipantsCubit(
      reader: _ParticipantsReader(),
      groupId: 'group-1',
    );
    final writer = _ParticipantsMutationWriter()
      ..pending = Completer<ParticipantReadModel>();
    final mutationCubit = _mutationCubit(writer);
    await readCubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: ParticipantsScreen(
          cubit: readCubit,
          loadOnOpen: false,
          mutationCubit: mutationCubit,
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'New participant');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add participant'));
    await tester.pump();

    expect(find.text('Ana Renamed'), findsOneWidget);
    expect(find.text('Former guest'), findsOneWidget);
    expect(find.text('New from server'), findsNothing);
    expect(
      readCubit.state.participants.map((participant) => participant.name),
      ['Ana Renamed', 'Former guest'],
    );

    writer.pending!.complete(_addedParticipant);
    await tester.pump();
    await tester.pump();
    expect(find.text('Ana Renamed'), findsOneWidget);
    expect(find.text('Former guest'), findsOneWidget);
    expect(find.text('New from server'), findsNothing);
    await readCubit.close();
    await mutationCubit.close();
  });

  testWidgets('gives helpful guidance when there are no balances', (
    tester,
  ) async {
    final cubit = BalancesCubit(
      reader: _EmptyBalancesReader(),
      groupId: 'group-1',
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(home: BalancesScreen(cubit: cubit, loadOnOpen: false)),
    );

    expect(find.text('No balances available yet.'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('exposes accessible loading state for every read surface', (
    tester,
  ) async {
    for (final surface in _loadingSurfaces()) {
      await tester.pumpWidget(MaterialApp(home: surface.screen));

      final message = 'Loading ${surface.resource}…';
      expect(find.text(message), findsOneWidget);
      expect(
        tester.getSemantics(find.text(message)).flagsCollection.isLiveRegion,
        isTrue,
      );
      expect(find.text('Retry ${surface.resource}'), findsNothing);

      await surface.close();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('exposes retryable accessible error and recovery states', (
    tester,
  ) async {
    for (final failure in [
      const ReadRepositoryException('offline'),
      const FormatException('malformed payload'),
    ]) {
      for (final surface in await _failedSurfaces(failure)) {
        await tester.pumpWidget(MaterialApp(home: surface.screen));

        final recoveryResource = surface.resource == 'expenses'
            ? 'expense history'
            : surface.resource;
        final message = failure is FormatException
            ? 'Unable to load $recoveryResource because the saved data is '
                  'corrupted. Please recover the server data before trying again.'
            : (failure as ReadRepositoryException).message;
        expect(find.text(message), findsOneWidget);
        expect(find.text('Retry ${surface.resource}'), findsOneWidget);
        expect(find.byType(OutlinedButton), findsOneWidget);
        expect(
          tester.getSize(find.byType(OutlinedButton)).height,
          greaterThanOrEqualTo(48),
        );
        expect(
          tester.getSemantics(find.text(message)).flagsCollection.isLiveRegion,
          isTrue,
        );

        await surface.close();
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });

  testWidgets('renders the Cubit-provided failure message', (tester) async {
    final cubit = GroupCubit(
      reader: _GroupReader(
        failure: const ReadRepositoryException('Group access was revoked.'),
      ),
      groupId: 'group-1',
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(home: GroupScreen(cubit: cubit, loadOnOpen: false)),
    );

    expect(find.text('Group access was revoked.'), findsOneWidget);
    expect(find.text('Unable to load group. Please try again.'), findsNothing);
    await cubit.close();
  });

  testWidgets('distinguishes unauthorized and forbidden read responses', (
    tester,
  ) async {
    final failures = {
      401: 'Your session expired. Please sign in again.',
      403: 'You are not authorized to view group.',
    };
    for (final entry in failures.entries) {
      final cubit = GroupCubit(
        reader: _GroupReader(
          failure: DioException(
            requestOptions: RequestOptions(path: '/groups/group-1'),
            response: Response<dynamic>(
              statusCode: entry.key,
              requestOptions: RequestOptions(path: '/groups/group-1'),
            ),
          ),
        ),
        groupId: 'group-1',
      );
      await cubit.load();

      await tester.pumpWidget(
        MaterialApp(home: GroupScreen(cubit: cubit, loadOnOpen: false)),
      );
      expect(find.text(entry.value), findsOneWidget);

      await cubit.close();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('exposes helpful empty states for all read surfaces', (
    tester,
  ) async {
    final expected = {
      'group': 'No group available.',
      'participants': 'No participants yet. Add participants first.',
      'expenses': 'No expenses recorded yet.',
      'balances': 'No balances available yet.',
      'settlement': 'Everyone is settled',
    };
    for (final surface in await _emptySurfaces()) {
      await tester.pumpWidget(MaterialApp(home: surface.screen));

      expect(find.text(expected[surface.resource]!), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);

      await surface.close();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

class _ReadSurface {
  const _ReadSurface({
    required this.resource,
    required this.screen,
    required this.close,
  });

  final String resource;
  final Widget screen;
  final Future<void> Function() close;
}

List<_ReadSurface> _loadingSurfaces() {
  final group = GroupCubit(reader: _GroupReader(), groupId: 'group-1');
  final participants = ParticipantsCubit(
    reader: _ParticipantsReader(),
    groupId: 'group-1',
  );
  final expenses = ExpensesCubit(reader: _ExpensesReader(), groupId: 'group-1');
  final balances = BalancesCubit(reader: _BalancesReader(), groupId: 'group-1');
  final settlement = SettlementCubit(
    reader: _SettlementReader(_settledSettlement),
    groupId: 'group-1',
  );
  return [
    _ReadSurface(
      resource: 'group',
      screen: GroupScreen(cubit: group, loadOnOpen: false),
      close: group.close,
    ),
    _ReadSurface(
      resource: 'participants',
      screen: ParticipantsScreen(cubit: participants, loadOnOpen: false),
      close: participants.close,
    ),
    _ReadSurface(
      resource: 'expenses',
      screen: ExpenseHistoryScreen(cubit: expenses, loadOnOpen: false),
      close: expenses.close,
    ),
    _ReadSurface(
      resource: 'balances',
      screen: BalancesScreen(cubit: balances, loadOnOpen: false),
      close: balances.close,
    ),
    _ReadSurface(
      resource: 'settlement',
      screen: SettlementScreen(cubit: settlement, loadOnOpen: false),
      close: settlement.close,
    ),
  ];
}

Future<List<_ReadSurface>> _failedSurfaces(Object failure) async {
  final group = GroupCubit(
    reader: _GroupReader(failure: failure),
    groupId: 'group-1',
  );
  final participants = ParticipantsCubit(
    reader: _ParticipantsReader(failure: failure),
    groupId: 'group-1',
  );
  final expenses = ExpensesCubit(
    reader: _ExpensesReader(failure: failure),
    groupId: 'group-1',
  );
  final balances = BalancesCubit(
    reader: _BalancesReader(failure: failure),
    groupId: 'group-1',
  );
  final settlement = SettlementCubit(
    reader: _SettlementReader(_settledSettlement, failure: failure),
    groupId: 'group-1',
  );
  await Future.wait([
    group.load(),
    participants.load(),
    expenses.load(),
    balances.load(),
    settlement.load(),
  ]);
  return [
    _ReadSurface(
      resource: 'group',
      screen: GroupScreen(cubit: group, loadOnOpen: false),
      close: group.close,
    ),
    _ReadSurface(
      resource: 'participants',
      screen: ParticipantsScreen(cubit: participants, loadOnOpen: false),
      close: participants.close,
    ),
    _ReadSurface(
      resource: 'expenses',
      screen: ExpenseHistoryScreen(cubit: expenses, loadOnOpen: false),
      close: expenses.close,
    ),
    _ReadSurface(
      resource: 'balances',
      screen: BalancesScreen(cubit: balances, loadOnOpen: false),
      close: balances.close,
    ),
    _ReadSurface(
      resource: 'settlement',
      screen: SettlementScreen(cubit: settlement, loadOnOpen: false),
      close: settlement.close,
    ),
  ];
}

Future<List<_ReadSurface>> _emptySurfaces() async {
  final group = GroupCubit(reader: _GroupReader(), groupId: 'group-1');
  await group.load();
  group.emit(const GroupState(status: ReadStatus.empty));

  final participants = ParticipantsCubit(
    reader: _EmptyParticipantsReader(),
    groupId: 'group-1',
  );
  await participants.load();

  final expenses = ExpensesCubit(
    reader: _ExpensesReader(data: const []),
    groupId: 'group-1',
  );
  await expenses.load();

  final balances = BalancesCubit(
    reader: _EmptyBalancesReader(),
    groupId: 'group-1',
  );
  await balances.load();

  final settlement = SettlementCubit(
    reader: _SettlementReader(_settledSettlement),
    groupId: 'group-1',
  );
  await settlement.load();

  return [
    _ReadSurface(
      resource: 'group',
      screen: GroupScreen(cubit: group, loadOnOpen: false),
      close: group.close,
    ),
    _ReadSurface(
      resource: 'participants',
      screen: ParticipantsScreen(cubit: participants, loadOnOpen: false),
      close: participants.close,
    ),
    _ReadSurface(
      resource: 'expenses',
      screen: ExpenseHistoryScreen(cubit: expenses, loadOnOpen: false),
      close: expenses.close,
    ),
    _ReadSurface(
      resource: 'balances',
      screen: BalancesScreen(cubit: balances, loadOnOpen: false),
      close: balances.close,
    ),
    _ReadSurface(
      resource: 'settlement',
      screen: SettlementScreen(cubit: settlement, loadOnOpen: false),
      close: settlement.close,
    ),
  ];
}

const _settledSettlement = SettlementReadModel(
  groupId: 'group-1',
  settlementPolicy: SettlementPolicy.ownerOnly,
  settled: true,
  transfers: [],
);

class _GroupReader implements GroupReader {
  _GroupReader({this.failure});

  final Object? failure;

  @override
  Future<GroupReadModel> getGroup(String groupId) async {
    if (failure != null) throw failure!;
    return const GroupReadModel(
      id: 'group-1',
      name: 'Samaipata',
      ownerAccountId: 'account-1',
      settlementPolicy: SettlementPolicy.ownerOnly,
    );
  }
}

class _ParticipantsReader implements ParticipantsReader {
  _ParticipantsReader({this.failure});

  Object? failure;

  @override
  Future<List<ParticipantReadModel>> listParticipants(String groupId) async {
    if (failure != null) throw failure!;
    return const [
      ParticipantReadModel(
        id: 'ana-id',
        groupId: 'group-1',
        name: 'Ana Renamed',
        archived: false,
      ),
      ParticipantReadModel(
        id: 'archived-id',
        groupId: 'group-1',
        name: 'Former guest',
        archived: true,
      ),
    ];
  }
}

class _EmptyParticipantsReader implements ParticipantsReader {
  @override
  Future<List<ParticipantReadModel>> listParticipants(String groupId) async =>
      const [];
}

const _addedParticipant = ParticipantReadModel(
  id: 'new-id',
  groupId: 'group-1',
  name: 'New from server',
  archived: false,
);

ParticipantsMutationCubit _mutationCubit([ParticipantsWriter? writer]) =>
    ParticipantsMutationCubit(
      writer: writer ?? _ParticipantsMutationWriter(),
      groupId: 'group-1',
    );

class _ParticipantsMutationWriter implements ParticipantsWriter {
  _ParticipantsMutationWriter({this.deleteFailure});

  final Object? deleteFailure;
  final commands = <String>[];
  Completer<ParticipantReadModel>? pending;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final command = switch (invocation.memberName) {
      #addParticipant => 'add',
      #renameParticipant => 'rename',
      #archiveParticipant => 'archive',
      #reactivateParticipant => 'reactivate',
      #deleteParticipant => 'delete',
      _ => throw UnimplementedError(),
    };
    commands.add(command);
    if (command == 'delete') {
      final failure = deleteFailure;
      if (failure != null) return Future<void>.error(failure);
      return Future<void>.value();
    }
    return pending?.future ??
        Future<ParticipantReadModel>.value(_addedParticipant);
  }
}

class _EmptyBalancesReader implements BalancesReader {
  @override
  Future<BalancesReadModel> getBalances(String groupId) async =>
      const BalancesReadModel(groupId: 'group-1', participants: []);
}

class _BalancesReader implements BalancesReader {
  _BalancesReader({this.failure});

  final Object? failure;

  @override
  Future<BalancesReadModel> getBalances(String groupId) async {
    if (failure != null) throw failure!;
    return const BalancesReadModel(
      groupId: 'group-1',
      participants: [
        BalanceParticipantReadModel(
          participantId: 'ana-id',
          name: 'Ana',
          archived: false,
          paidCents: 96000,
          owedCents: 40000,
          balanceCents: 56000,
        ),
        BalanceParticipantReadModel(
          participantId: 'beto-id',
          name: 'Beto',
          archived: false,
          paidCents: 0,
          owedCents: 0,
          balanceCents: 0,
        ),
        BalanceParticipantReadModel(
          participantId: 'carla-id',
          name: 'Carla',
          archived: false,
          paidCents: 0,
          owedCents: 16000,
          balanceCents: -16000,
        ),
        BalanceParticipantReadModel(
          participantId: 'diego-id',
          name: 'Diego',
          archived: false,
          paidCents: 0,
          owedCents: 40000,
          balanceCents: -40000,
        ),
        BalanceParticipantReadModel(
          participantId: 'archived-id',
          name: 'Former guest',
          archived: true,
          paidCents: 0,
          owedCents: 0,
          balanceCents: 0,
        ),
      ],
    );
  }
}

class _SettlementReader implements SettlementReader {
  _SettlementReader(this.data, {this.failure});

  final SettlementReadModel data;
  final Object? failure;

  @override
  Future<SettlementReadModel> getSettlement(String groupId) async {
    if (failure != null) throw failure!;
    return data;
  }
}

class _ExpensesReader implements ExpensesReader {
  _ExpensesReader({this.data = _defaultExpenses, this.failure});

  final List<ExpenseReadModel> data;
  final Object? failure;

  @override
  Future<List<ExpenseReadModel>> listExpenses(String groupId) async {
    if (failure != null) throw failure!;
    return data;
  }
}

const _archivedExpense = ExpenseReadModel(
  id: 'archived-expense-1',
  groupId: 'group-1',
  description: 'Former stay',
  amountCents: 1200,
  contributors: [
    ExpenseContributorReadModel(
      participantId: 'archived-id',
      name: 'Former guest',
      archived: true,
      amountCents: 1200,
    ),
  ],
  beneficiaries: [
    ExpenseBeneficiaryReadModel(
      participantId: 'archived-id',
      name: 'Former guest',
      archived: true,
    ),
  ],
);

const _defaultExpenses = [
  ExpenseReadModel(
    id: 'expense-1',
    groupId: 'group-1',
    description: 'Lodging',
    amountCents: 96000,
    contributors: [
      ExpenseContributorReadModel(
        participantId: 'ana-id',
        name: 'Ana Renamed',
        archived: false,
        amountCents: 96000,
      ),
    ],
    beneficiaries: [
      ExpenseBeneficiaryReadModel(
        participantId: 'ana-id',
        name: 'Ana Renamed',
        archived: false,
      ),
    ],
  ),
];
