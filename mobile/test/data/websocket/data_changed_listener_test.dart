import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

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
