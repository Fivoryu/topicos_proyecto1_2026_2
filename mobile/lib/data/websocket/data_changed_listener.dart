import 'dart:async';
import 'dart:convert';

/// A REST reload callback owned by a read Cubit.
typedef ReadReload = FutureOr<void> Function();

/// Listens only for the invalidation type from the group WebSocket.
///
/// The event payload is deliberately not exposed to reload callbacks. REST is
/// the only source of money, names, roles, and other read data.
class DataChangedListener {
  DataChangedListener({
    required Stream<Object?> frames,
    Iterable<ReadReload> reloaders = const [],
  }) : _frames = frames,
       _reloaders = [...reloaders];

  final Stream<Object?> _frames;
  final List<ReadReload> _reloaders;
  StreamSubscription<Object?>? _subscription;

  bool get isListening => _subscription != null;

  void addReloader(ReadReload reloader) => _reloaders.add(reloader);

  void start() {
    if (_subscription != null) return;
    _subscription = _frames.listen(
      (frame) {
        if (isDataChangedFrame(frame)) unawaited(_reloadSafely());
      },
      onError: (_) {
        // A WebSocket outage is non-authoritative; manual and startup REST
        // loads remain available and no stale frame is treated as data.
      },
    );
  }

  Future<void> reloadFromRest() => _reload();

  Future<void> _reloadSafely() async {
    try {
      await _reload();
    } on Object {
      // A failed invalidation reload is surfaced by the Cubit's own state on
      // the next explicit REST load; the listener must not kill the stream.
    }
  }

  Future<void> _reload() async {
    await Future.wait(
      _reloaders.map((reloader) => Future<void>.sync(reloader)),
    );
  }

  Future<void> close() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }
}

/// Reads only the `type` discriminator and ignores every other frame field.
bool isDataChangedFrame(Object? frame) {
  if (frame is Map) return frame['type'] == 'data_changed';
  if (frame is! String) return false;
  try {
    final decoded = jsonDecode(frame);
    return decoded is Map && decoded['type'] == 'data_changed';
  } on FormatException {
    return false;
  }
}

typedef WebSocketDataChangedListener = DataChangedListener;
typedef MobileWebSocketListener = DataChangedListener;
