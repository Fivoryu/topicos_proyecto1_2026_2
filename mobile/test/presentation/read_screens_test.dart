import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/data/repositories/balances_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/expenses_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/group_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/participants_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/settlement_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/presentation/balances/balances_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/balances/balances_screen.dart';
import 'package:cuentas_claras_mobile/presentation/expenses/expense_history_screen.dart';
import 'package:cuentas_claras_mobile/presentation/expenses/expenses_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/group/group_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/group/group_screen.dart';
import 'package:cuentas_claras_mobile/presentation/participants/participants_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/participants/participants_screen.dart';
import 'package:cuentas_claras_mobile/presentation/settlement/settlement_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/settlement/settlement_screen.dart';

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
}

class _GroupReader implements GroupReader {
  @override
  Future<GroupReadModel> getGroup(String groupId) async => const GroupReadModel(
    id: 'group-1',
    name: 'Samaipata',
    ownerAccountId: 'account-1',
    settlementPolicy: SettlementPolicy.ownerOnly,
  );
}

class _ParticipantsReader implements ParticipantsReader {
  @override
  Future<List<ParticipantReadModel>> listParticipants(String groupId) async =>
      const [
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

class _EmptyParticipantsReader implements ParticipantsReader {
  @override
  Future<List<ParticipantReadModel>> listParticipants(String groupId) async =>
      const [];
}

class _BalancesReader implements BalancesReader {
  @override
  Future<BalancesReadModel> getBalances(String groupId) async =>
      const BalancesReadModel(
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

class _SettlementReader implements SettlementReader {
  _SettlementReader(this.data);

  final SettlementReadModel data;

  @override
  Future<SettlementReadModel> getSettlement(String groupId) async => data;
}

class _ExpensesReader implements ExpensesReader {
  @override
  Future<List<ExpenseReadModel>> listExpenses(String groupId) async => const [
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
}
