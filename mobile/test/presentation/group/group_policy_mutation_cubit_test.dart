import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/data/repositories/group_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/presentation/group/group_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/group/group_policy_mutation_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/group/group_screen.dart';

void main() {
  test(
    'waits for authoritative refresh before reporting policy success',
    () async {
      final refresh = Completer<void>();
      final writer = _PolicyWriter();
      final cubit = GroupPolicyMutationCubit(
        writer: writer,
        groupId: 'group-1',
        onMutationSuccess: () => refresh.future,
      );

      final update = cubit.updateSettlementPolicy(SettlementPolicy.anyMember);
      await Future<void>.delayed(Duration.zero);

      expect(writer.policies, [SettlementPolicy.anyMember]);
      expect(cubit.state.status, GroupPolicyMutationStatus.loading);
      expect(cubit.state.successMessage, isNull);

      refresh.complete();
      await update;

      expect(cubit.state.status, GroupPolicyMutationStatus.success);
      expect(cubit.state.result?.settlementPolicy, SettlementPolicy.anyMember);
      await cubit.close();
    },
  );

  test('prevents duplicate submits while a policy update is pending', () async {
    final response = Completer<GroupReadModel>();
    final writer = _PolicyWriter(response: response.future);
    final cubit = GroupPolicyMutationCubit(writer: writer, groupId: 'group-1');

    final first = cubit.update(SettlementPolicy.anyMember);
    final second = cubit.update(SettlementPolicy.ownerOnly);
    await Future<void>.delayed(Duration.zero);

    expect(writer.policies, [SettlementPolicy.anyMember]);
    response.complete(_group(SettlementPolicy.anyMember));
    await Future.wait([first, second]);
    expect(cubit.state.result?.settlementPolicy, SettlementPolicy.anyMember);
    await cubit.close();
  });

  test(
    'retries one failed post-success refresh without repeating the writer',
    () async {
      var refreshAttempts = 0;
      final writer = _PolicyWriter();
      final cubit = GroupPolicyMutationCubit(
        writer: writer,
        groupId: 'group-1',
        onMutationSuccess: () async {
          throw StateError('refresh unavailable');
        },
        onPostMutationRefreshRetry: () async {
          refreshAttempts++;
        },
      );

      await cubit.update(SettlementPolicy.anyMember);

      expect(writer.policies, [SettlementPolicy.anyMember]);
      expect(cubit.state.status, GroupPolicyMutationStatus.failure);
      expect(
        cubit.state.failure?.kind,
        GroupPolicyMutationFailureKind.recovery,
      );
      expect(cubit.canRetryPostMutationRefresh, isTrue);

      await cubit.retryPostMutationRefresh();

      expect(refreshAttempts, 1);
      expect(writer.policies, [SettlementPolicy.anyMember]);
      expect(cubit.state.status, GroupPolicyMutationStatus.success);
      expect(cubit.canRetryPostMutationRefresh, isFalse);
      await cubit.close();
    },
  );

  test(
    'maps authorization, validation, action, network, corruption, and recovery failures',
    () async {
      final failures = <Object, GroupPolicyMutationFailureKind>{
        _dioFailure(401): GroupPolicyMutationFailureKind.unauthorized,
        _dioFailure(403): GroupPolicyMutationFailureKind.forbidden,
        _dioFailure(422, {
          'field_errors': {
            'settlementPolicy': ['invalid'],
          },
        }): GroupPolicyMutationFailureKind.validation,
        _dioFailure(409, {'action': 'policy_conflict'}):
            GroupPolicyMutationFailureKind.action,
        DioException(
          requestOptions: RequestOptions(path: '/groups/group-1'),
          type: DioExceptionType.connectionError,
        ): GroupPolicyMutationFailureKind.network,
        const GroupWriteException('bad group response', isCorruption: true):
            GroupPolicyMutationFailureKind.corruption,
        StateError('temporary failure'):
            GroupPolicyMutationFailureKind.recovery,
      };

      for (final entry in failures.entries) {
        final cubit = GroupPolicyMutationCubit(
          writer: _PolicyWriter(error: entry.key),
          groupId: 'group-1',
        );
        await cubit.update(SettlementPolicy.anyMember);
        expect(cubit.state.failure?.kind, entry.value);
        expect(cubit.state.failure?.message, isNotEmpty);
        await cubit.close();
      }
    },
  );

  testWidgets(
    'shows only supported owner controls and keeps server policy authoritative',
    (tester) async {
      final groupCubit = GroupCubit(
        reader: _GroupReader(_group(SettlementPolicy.ownerOnly)),
        groupId: 'group-1',
      );
      await groupCubit.load();
      final writer = _PolicyWriter();
      final policyCubit = GroupPolicyMutationCubit(
        writer: writer,
        groupId: 'group-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GroupScreen(
            cubit: groupCubit,
            role: 'owner',
            mutationCubit: policyCubit,
            loadOnOpen: false,
          ),
        ),
      );

      expect(find.text('Owner only'), findsOneWidget);
      expect(find.text('Any member'), findsOneWidget);
      expect(find.byType(RadioListTile<SettlementPolicy>), findsNWidgets(2));

      await tester.tap(find.byKey(const ValueKey('policy-any-member')));
      await tester.pump();

      expect(writer.policies, [SettlementPolicy.anyMember]);
      expect(
        groupCubit.state.group?.settlementPolicy,
        SettlementPolicy.ownerOnly,
      );

      await policyCubit.close();
      await groupCubit.close();
    },
  );

  testWidgets('keeps member read-only while owner-only policy is current', (
    tester,
  ) async {
    final groupCubit = GroupCubit(
      reader: _GroupReader(_group(SettlementPolicy.ownerOnly)),
      groupId: 'group-1',
    );
    await groupCubit.load();
    final writer = _PolicyWriter();
    final policyCubit = GroupPolicyMutationCubit(
      writer: writer,
      groupId: 'group-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GroupScreen(
          cubit: groupCubit,
          role: 'member',
          mutationCubit: policyCubit,
          loadOnOpen: false,
        ),
      ),
    );

    expect(find.byType(RadioListTile<SettlementPolicy>), findsNothing);
    expect(
      find.text('Only the group owner can change this policy.'),
      findsOneWidget,
    );
    expect(find.text('Owner only'), findsOneWidget);
    expect(find.text('Any member'), findsNothing);

    await policyCubit.close();
    await groupCubit.close();
  });

  testWidgets(
    'enables supported policy controls for members when any-member policy is current',
    (tester) async {
      final groupCubit = GroupCubit(
        reader: _GroupReader(_group(SettlementPolicy.anyMember)),
        groupId: 'group-1',
      );
      await groupCubit.load();
      final writer = _PolicyWriter();
      final policyCubit = GroupPolicyMutationCubit(
        writer: writer,
        groupId: 'group-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GroupScreen(
            cubit: groupCubit,
            role: 'member',
            mutationCubit: policyCubit,
            loadOnOpen: false,
          ),
        ),
      );

      expect(find.byType(RadioListTile<SettlementPolicy>), findsNWidgets(2));
      expect(
        find.text('Only the group owner can change this policy.'),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('policy-owner-only')));
      await tester.pump();

      expect(writer.policies, [SettlementPolicy.ownerOnly]);
      expect(
        groupCubit.state.group?.settlementPolicy,
        SettlementPolicy.anyMember,
      );

      await policyCubit.close();
      await groupCubit.close();
    },
  );

  testWidgets(
    'shows accessible refresh recovery without repeating the writer',
    (tester) async {
      final groupCubit = GroupCubit(
        reader: _GroupReader(_group(SettlementPolicy.ownerOnly)),
        groupId: 'group-1',
      );
      await groupCubit.load();
      final writer = _PolicyWriter();
      final policyCubit = GroupPolicyMutationCubit(
        writer: writer,
        groupId: 'group-1',
        onMutationSuccess: () async => throw StateError('refresh failed'),
        onPostMutationRefreshRetry: () async {},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GroupScreen(
            cubit: groupCubit,
            role: 'owner',
            mutationCubit: policyCubit,
            loadOnOpen: false,
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('policy-any-member')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('latest group data could not be loaded'),
        findsOneWidget,
      );
      expect(find.text('Retry refresh'), findsOneWidget);
      expect(
        groupCubit.state.group?.settlementPolicy,
        SettlementPolicy.ownerOnly,
      );

      await tester.tap(find.text('Retry refresh'));
      await tester.pumpAndSettle();

      expect(writer.policies, [SettlementPolicy.anyMember]);
      expect(find.text('Settlement policy updated.'), findsOneWidget);
      await policyCubit.close();
      await groupCubit.close();
    },
  );
}

GroupReadModel _group(SettlementPolicy policy) => GroupReadModel(
  id: 'group-1',
  name: 'Trip',
  ownerAccountId: 'owner-1',
  settlementPolicy: policy,
);

DioException _dioFailure(int status, [Object? data]) {
  final requestOptions = RequestOptions(path: '/groups/group-1');
  return DioException(
    requestOptions: requestOptions,
    response: Response<Object>(
      statusCode: status,
      data: data,
      requestOptions: requestOptions,
    ),
  );
}

class _PolicyWriter implements GroupWriter {
  _PolicyWriter({this.response, this.error});

  final Future<GroupReadModel>? response;
  final Object? error;
  final policies = <SettlementPolicy>[];

  @override
  Future<GroupReadModel> updateSettlementPolicy(
    String groupId,
    SettlementPolicy policy,
  ) {
    policies.add(policy);
    if (error != null) return Future<GroupReadModel>.error(error!);
    return response ?? Future<GroupReadModel>.value(_group(policy));
  }
}

class _GroupReader implements GroupReader {
  _GroupReader(this.group);

  final GroupReadModel group;

  @override
  Future<GroupReadModel> getGroup(String groupId) async => group;
}
