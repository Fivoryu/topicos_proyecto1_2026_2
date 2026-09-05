import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/data/refresh/refresh_coordinator.dart';

void main() {
  test('defines explicit and conservative impact plans', () {
    expect(RefreshCoordinator.targetsFor(RefreshImpact.participant), {
      RefreshTarget.participants,
      RefreshTarget.expenses,
      RefreshTarget.balances,
      RefreshTarget.settlement,
    });
    expect(RefreshCoordinator.targetsFor(RefreshImpact.expense), {
      RefreshTarget.participants,
      RefreshTarget.expenses,
      RefreshTarget.balances,
      RefreshTarget.settlement,
    });
    expect(RefreshCoordinator.targetsFor(RefreshImpact.policy), {
      RefreshTarget.group,
    });
    expect(
      RefreshCoordinator.targetsFor(RefreshImpact.unknown),
      RefreshTarget.values.toSet(),
    );
  });

  test('waits for every required reload and coalesces duplicates', () async {
    final gates = {
      for (final target in RefreshTarget.values) target: Completer<void>(),
    };
    final calls = <RefreshTarget>[];
    final coordinator = RefreshCoordinator(
      reloaders: {
        for (final target in RefreshTarget.values)
          target: () async {
            calls.add(target);
            await gates[target]!.future;
          },
      },
    );

    final first = coordinator.refresh(RefreshImpact.participant);
    final duplicate = coordinator.refresh(RefreshImpact.participant);
    var completed = false;
    first.then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);

    expect(identical(first, duplicate), isTrue);
    expect(coordinator.state.status, RefreshStatus.refreshing);
    expect(
      calls,
      containsAll(RefreshCoordinator.targetsFor(RefreshImpact.participant)),
    );
    expect(completed, isFalse);

    for (final target in RefreshCoordinator.targetsFor(
      RefreshImpact.participant,
    )) {
      gates[target]!.complete();
    }
    await first;

    expect(completed, isTrue);
    expect(coordinator.state.status, RefreshStatus.ready);
    expect(calls, hasLength(4));
  });

  test(
    'completes participant, expense, and policy plans after every REST reload',
    () async {
      final plans = {
        RefreshImpact.participant: {
          RefreshTarget.participants,
          RefreshTarget.expenses,
          RefreshTarget.balances,
          RefreshTarget.settlement,
        },
        RefreshImpact.expense: {
          RefreshTarget.participants,
          RefreshTarget.expenses,
          RefreshTarget.balances,
          RefreshTarget.settlement,
        },
        RefreshImpact.policy: {RefreshTarget.group},
      };

      for (final entry in plans.entries) {
        final required = entry.value.toList();
        final gates = {
          for (final target in required) target: Completer<void>(),
        };
        final calls = <RefreshTarget>[];
        final coordinator = RefreshCoordinator(
          reloaders: {
            for (final target in RefreshTarget.values)
              target: () async {
                calls.add(target);
                await gates[target]?.future;
              },
          },
        );

        var completed = false;
        final refresh = coordinator.refresh(entry.key);
        refresh.then((_) => completed = true);
        await Future<void>.delayed(Duration.zero);

        expect(calls.toSet(), entry.value);
        expect(coordinator.state.status, RefreshStatus.refreshing);
        expect(completed, isFalse);

        for (final target in required.take(required.length - 1)) {
          gates[target]!.complete();
        }
        await Future<void>.delayed(Duration.zero);
        expect(completed, isFalse);
        expect(coordinator.state.status, RefreshStatus.refreshing);

        gates[required.last]!.complete();
        await refresh;
        expect(completed, isTrue);
        expect(coordinator.state.status, RefreshStatus.ready);
      }
    },
  );

  test('queues a new impact without rerunning active targets', () async {
    final gates = {
      for (final target in RefreshTarget.values) target: Completer<void>(),
    };
    final calls = <RefreshTarget>[];
    final coordinator = RefreshCoordinator(
      reloaders: {
        for (final target in RefreshTarget.values)
          target: () async {
            calls.add(target);
            await gates[target]!.future;
          },
      },
    );

    final first = coordinator.refresh(RefreshImpact.participant);
    final queued = coordinator.refresh(RefreshImpact.policy);
    await Future<void>.delayed(Duration.zero);
    expect(identical(first, queued), isTrue);
    expect(calls, hasLength(4));

    for (final target in RefreshCoordinator.targetsFor(
      RefreshImpact.participant,
    )) {
      gates[target]!.complete();
    }
    await Future<void>.delayed(Duration.zero);
    expect(calls, contains(RefreshTarget.group));
    gates[RefreshTarget.group]!.complete();
    await first;
    expect(calls, hasLength(5));
  });

  test('unknown impact reloads all targets', () async {
    final calls = <RefreshTarget>[];
    final coordinator = RefreshCoordinator(
      reloaders: {
        for (final target in RefreshTarget.values)
          target: () {
            calls.add(target);
          },
      },
    );

    await coordinator.refresh(RefreshImpact.unknown);

    expect(calls, RefreshTarget.values);
  });

  test('exposes retryable failure and retries every required target', () async {
    var failExpenses = true;
    final calls = <RefreshTarget, int>{};
    final coordinator = RefreshCoordinator(
      reloaders: {
        for (final target in RefreshTarget.values)
          target: () async {
            calls[target] = (calls[target] ?? 0) + 1;
            if (target == RefreshTarget.expenses && failExpenses) {
              throw StateError('expenses unavailable');
            }
          },
      },
    );

    await expectLater(
      coordinator.refresh(RefreshImpact.expense),
      throwsA(isA<StateError>()),
    );
    expect(coordinator.state.status, RefreshStatus.failed);
    expect(coordinator.state.canRetry, isTrue);
    expect(coordinator.state.targets, {RefreshTarget.expenses});
    expect(calls.values, everyElement(1));

    failExpenses = false;
    await coordinator.retry();

    expect(coordinator.state.status, RefreshStatus.ready);
    expect(calls, {
      RefreshTarget.participants: 1,
      RefreshTarget.expenses: 2,
      RefreshTarget.balances: 1,
      RefreshTarget.settlement: 1,
    });
  });

  test('waits for every target before exposing partial failure', () async {
    final expenseGate = Completer<void>();
    final balanceGate = Completer<void>();
    final calls = <RefreshTarget>[];
    final coordinator = RefreshCoordinator(
      reloaders: {
        RefreshTarget.group: () => calls.add(RefreshTarget.group),
        RefreshTarget.participants: () => calls.add(RefreshTarget.participants),
        RefreshTarget.expenses: () async {
          calls.add(RefreshTarget.expenses);
          await expenseGate.future;
          throw StateError('expenses unavailable');
        },
        RefreshTarget.balances: () async {
          calls.add(RefreshTarget.balances);
          await balanceGate.future;
          throw StateError('balances unavailable');
        },
        RefreshTarget.settlement: () => calls.add(RefreshTarget.settlement),
      },
    );

    final refresh = coordinator.refresh(RefreshImpact.expense);
    var completed = false;
    refresh.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {
        completed = true;
      },
    );
    await Future<void>.delayed(Duration.zero);
    expect(coordinator.state.status, RefreshStatus.refreshing);
    expect(calls, hasLength(4));

    expenseGate.complete();
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    expect(coordinator.state.status, RefreshStatus.refreshing);

    balanceGate.complete();
    await expectLater(refresh, throwsA(isA<StateError>()));
    expect(completed, isTrue);
    expect(coordinator.state.status, RefreshStatus.failed);
    expect(coordinator.state.targets, {
      RefreshTarget.expenses,
      RefreshTarget.balances,
    });
  });
}
