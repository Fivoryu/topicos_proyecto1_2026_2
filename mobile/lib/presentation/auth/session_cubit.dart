import 'package:bloc/bloc.dart';

import '../../data/auth/auth_repository.dart';
import '../../domain/read_models/read_models.dart';

const _unset = Object();

/// Session lifecycle states exposed to presentation.
enum SessionStatus {
  unknown,
  signedOut,
  authenticating,
  authenticated,
  sessionExpired,
}

/// Presentation-only identity snapshot; cookie values never live here.
class SessionState {
  const SessionState({
    required this.status,
    this.role,
    this.activeGroupId,
    this.errorMessage,
  });

  const SessionState.unknown()
    : status = SessionStatus.unknown,
      role = null,
      activeGroupId = null,
      errorMessage = null;

  final SessionStatus status;
  final String? role;
  final String? activeGroupId;
  final String? errorMessage;

  SessionState copyWith({
    SessionStatus? status,
    Object? role = _unset,
    Object? activeGroupId = _unset,
    Object? errorMessage = _unset,
  }) => SessionState(
    status: status ?? this.status,
    role: identical(role, _unset) ? this.role : role as String?,
    activeGroupId: identical(activeGroupId, _unset)
        ? this.activeGroupId
        : activeGroupId as String?,
    errorMessage: identical(errorMessage, _unset)
        ? this.errorMessage
        : errorMessage as String?,
  );
}

/// Owns auth transitions and exposes only the server-derived role for display.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({required AuthRepository repository})
    : _repository = repository,
      super(const SessionState.unknown()) {
    _repository.onUnauthorized = (failure) {
      if (state.status == SessionStatus.authenticated) {
        markSessionExpired();
      }
    };
  }

  final AuthRepository _repository;
  var _transitionVersion = 0;

  /// Restore the session from the server; 401 lands in signedOut.
  Future<void> restoreSession() async {
    final requestVersion = _transitionVersion;
    try {
      final identity = await _repository.session();
      if (!_isCurrent(requestVersion)) return;
      emit(_authenticated(identity));
    } on Exception {
      if (!_isCurrent(requestVersion)) return;
      emit(const SessionState(status: SessionStatus.signedOut));
    }
  }

  Future<void> login({
    required String loginName,
    required String password,
  }) async {
    final requestVersion = ++_transitionVersion;
    emit(const SessionState(status: SessionStatus.authenticating));
    try {
      final identity = await _repository.login(
        loginName: loginName,
        password: password,
      );
      if (!_isCurrent(requestVersion)) return;
      emit(_authenticated(identity));
    } on Object {
      if (!_isCurrent(requestVersion)) return;
      emit(
        const SessionState(
          status: SessionStatus.signedOut,
          errorMessage:
              'Unable to sign in. Check your credentials and connection.',
        ),
      );
    }
  }

  Future<void> logout() async {
    ++_transitionVersion;
    // Clear local identity before waiting on the server so protected state is
    // disposed even when the logout request is slow or unavailable.
    if (!isClosed) {
      emit(const SessionState(status: SessionStatus.signedOut));
    }
    try {
      await _repository.logout();
    } on Object {
      // Local logout still clears protected state.
    }
  }

  void markSessionExpired() {
    ++_transitionVersion;
    if (isClosed) return;
    emit(const SessionState(status: SessionStatus.sessionExpired));
  }

  bool _isCurrent(int requestVersion) =>
      !isClosed && requestVersion == _transitionVersion;

  SessionState _authenticated(SessionIdentityReadModel identity) =>
      SessionState(
        status: SessionStatus.authenticated,
        role: identity.role.name,
        activeGroupId: identity.activeGroupId,
      );

  @override
  String toString() =>
      'SessionState(${state.status}${state.role == null ? '' : ', role=${state.role}'})';
}
