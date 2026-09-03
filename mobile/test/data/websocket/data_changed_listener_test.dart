import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/data/refresh/refresh_coordinator.dart';
import 'package:cuentas_claras_mobile/data/websocket/data_changed_listener.dart';

void main() {
  test(
    'reloads readers for data_changed and ignores frame payload fields',
    () async {
      final frames = StreamController<Object?>();
      var reloads = 0;
      final listener = DataChangedListener(
        frames: frames.stream,
        reloaders: [() async => reloads++],
      )..start();

      frames.add({
        'type': 'data_changed',
        'balance_cents': 999999,
        'role': 'owner',
        'participant': 'forged name',
      });
      await Future<void>.delayed(Duration.zero);

      expect(reloads, 1);
      await listener.close();
      await frames.close();
    },
  );

  test(
    'routes a Map data_changed frame to conservative coordinator refresh',
    () async {
      final frames = StreamController<Object?>();
      final calls = <RefreshTarget>[];
      final coordinator = _coordinator((target) => calls.add(target));
      final listener = DataChangedListener(
        frames: frames.stream,
        onDataChanged: () => coordinator.refresh(RefreshImpact.unknown),
      )..start();

      frames.add({
        'type': 'data_changed',
        'impact': 'participant',
        'balance_cents': 999999,
        'role': 'owner',
        'participant': 'forged name',
      });
      await Future<void>.delayed(Duration.zero);

      expect(calls, RefreshTarget.values);
      await listener.close();
      await frames.close();
    },
  );

  test('routes a JSON data_changed frame to REST reloads', () async {
    final frames = StreamController<Object?>();
    final calls = <RefreshTarget>[];
    final coordinator = _coordinator((target) => calls.add(target));
    final listener = DataChangedListener(
      frames: frames.stream,
      onDataChanged: () => coordinator.refresh(RefreshImpact.unknown),
    )..start();

    frames.add('{"type":"data_changed","group_id":"forged-group"}');
    await Future<void>.delayed(Duration.zero);

    expect(calls, RefreshTarget.values);
    await listener.close();
    await frames.close();
  });

  test('ignores non-invalidation and malformed frames', () async {
    final frames = StreamController<Object?>();
    final calls = <RefreshTarget>[];
    final coordinator = _coordinator((target) => calls.add(target));
    final listener = DataChangedListener(
      frames: frames.stream,
      onDataChanged: () => coordinator.refresh(RefreshImpact.unknown),
    )..start();

    frames.add({'type': 'group_updated'});
    frames.add('{not-json');
    frames.add(42);
    await Future<void>.delayed(Duration.zero);

    expect(calls, isEmpty);
    await listener.close();
    await frames.close();
  });

  test('coalesces duplicate frames through the coordinator', () async {
    final frames = StreamController<Object?>();
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
    final listener = DataChangedListener(
      frames: frames.stream,
      onDataChanged: () => coordinator.refresh(RefreshImpact.unknown),
    )..start();

    frames.add({'type': 'data_changed'});
    frames.add('{"type":"data_changed","role":"forged"}');
    await Future<void>.delayed(Duration.zero);

    expect(calls, RefreshTarget.values);
    for (final gate in gates.values) {
      gate.complete();
    }
    await Future<void>.delayed(Duration.zero);

    await listener.close();
    await frames.close();
  });

  test('websocket errors do not prevent a later REST reload', () async {
    final frames = StreamController<Object?>();
    var reloads = 0;
    final listener = DataChangedListener(
      frames: frames.stream,
      reloaders: [() async => reloads++],
    )..start();

    frames.addError(StateError('websocket down'));
    frames.add({'type': 'not_an_invalidation'});
    await Future<void>.delayed(Duration.zero);
    expect(reloads, 0);

    await listener.reloadFromRest();
    expect(reloads, 1);
    await listener.close();
    await frames.close();
  });
}

RefreshCoordinator _coordinator(void Function(RefreshTarget) onReload) =>
    RefreshCoordinator(
      reloaders: {
        for (final target in RefreshTarget.values)
          target: () => onReload(target),
      },
    );
