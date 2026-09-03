import 'dart:async';

import '../websocket/data_changed_listener.dart';

enum RefreshTarget { group, participants, expenses, balances, settlement }

enum RefreshImpact { participant, expense, policy, unknown }

enum RefreshStatus { idle, refreshing, ready, failed }

class RefreshState {
  RefreshState({
    required this.status,
    Iterable<RefreshTarget> targets = const [],
    this.error,
  }) : targets = Set.unmodifiable(targets);

  RefreshState.idle() : this(status: RefreshStatus.idle);

  RefreshState.refreshing(Iterable<RefreshTarget> targets)
    : this(status: RefreshStatus.refreshing, targets: targets);

  RefreshState.ready() : this(status: RefreshStatus.ready);

  RefreshState.failed(Iterable<RefreshTarget> targets, Object error)
    : this(status: RefreshStatus.failed, targets: targets, error: error);

  final RefreshStatus status;
  final Set<RefreshTarget> targets;
  final Object? error;

  bool get canRetry => status == RefreshStatus.failed && targets.isNotEmpty;
}

class RefreshCoordinator {
  RefreshCoordinator({required Map<RefreshTarget, ReadReload> reloaders})
    : _reloaders = Map.unmodifiable(reloaders) {
    final missing = RefreshTarget.values
        .where((target) => !_reloaders.containsKey(target))
        .toList();
    if (missing.isNotEmpty) {
      throw ArgumentError('Missing reloaders for: $missing');
    }
  }

  final Map<RefreshTarget, ReadReload> _reloaders;
  final Set<RefreshTarget> _pendingTargets = {};
  final Set<RefreshTarget> _activeTargets = {};
  Set<RefreshTarget> _failedTargets = {};
  Future<void>? _inFlight;
  var _closed = false;

  bool get isClosed => _closed;
  RefreshState _state = RefreshState.idle();

  RefreshState get state => _state;

  static Set<RefreshTarget> targetsFor(RefreshImpact impact) =>
      Set.unmodifiable(switch (impact) {
        RefreshImpact.participant => {
          RefreshTarget.participants,
          RefreshTarget.expenses,
          RefreshTarget.balances,
          RefreshTarget.settlement,
        },
        RefreshImpact.expense => {
          RefreshTarget.participants,
          RefreshTarget.expenses,
          RefreshTarget.balances,
          RefreshTarget.settlement,
        },
        RefreshImpact.policy => {RefreshTarget.group},
        RefreshImpact.unknown => RefreshTarget.values.toSet(),
      });

  Future<void> refresh(RefreshImpact impact) {
    if (_closed) return Future<void>.value();
    final targets = targetsFor(impact);
    if (_inFlight == null) {
      _pendingTargets.addAll(targets);
    } else {
      _pendingTargets.addAll(targets.difference(_activeTargets));
    }
    return _startOrJoin();
  }

  Future<void> retry() {
    if (_closed) return Future<void>.value();
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    if (_failedTargets.isEmpty) return Future<void>.value();
    _pendingTargets.addAll(_failedTargets);
    return _startOrJoin();
  }

  Future<void> _startOrJoin() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final operation = Completer<void>();
    _inFlight = operation.future;
    unawaited(_drain(operation));
    return operation.future;
  }

  Future<void> _drain(Completer<void> operation) async {
    try {
      while (_pendingTargets.isNotEmpty) {
        final targets = Set<RefreshTarget>.from(_pendingTargets);
        _pendingTargets.clear();
        _activeTargets
          ..clear()
          ..addAll(targets);
        _state = RefreshState.refreshing(targets);
        Object? firstError;
        StackTrace? firstStackTrace;
        final failedTargets = <RefreshTarget>{};
        await Future.wait<void>(
          targets.map((target) async {
            try {
              await Future<void>.sync(_reloaders[target]!);
            } on Object catch (error, stackTrace) {
              firstError ??= error;
              firstStackTrace ??= stackTrace;
              failedTargets.add(target);
            }
          }),
        );
        _activeTargets.clear();
        if (_closed) {
          operation.complete();
          return;
        }
        if (failedTargets.isNotEmpty) {
          final error = firstError!;
          final stackTrace = firstStackTrace!;
          _failedTargets = failedTargets;
          _state = RefreshState.failed(failedTargets, error);
          operation.completeError(error, stackTrace);
          return;
        }
      }
      if (_closed) {
        operation.complete();
        return;
      }
      _failedTargets = {};
      _state = RefreshState.ready();
      operation.complete();
    } on Object catch (error, stackTrace) {
      if (!operation.isCompleted) operation.completeError(error, stackTrace);
    } finally {
      _inFlight = null;
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _pendingTargets.clear();
    _activeTargets.clear();
    _failedTargets = {};
    _state = RefreshState.idle();
  }
}
