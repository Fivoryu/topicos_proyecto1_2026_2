import 'package:bloc/bloc.dart';

import '../../data/auth/auth_repository.dart';
import '../../domain/read_models/read_models.dart';

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
  const SessionState({required this.status, this.role, this.activeGroupId});

  const SessionState.unknown()
    : status = SessionStatus.unknown,
      role = null,
      activeGroupId = null;

  final SessionStatus status;
  final String? role;
  final String? activeGroupId;

  SessionState copyWith({
    SessionStatus? status,
    String? role,
    String? activeGroupId,
  }) => SessionState(
    status: status ?? this.status,
    role: role ?? this.role,
    activeGroupId: activeGroupId ?? this.activeGroupId,
  );
}

/// Owns auth transitions and exposes only the server-derived role for display.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({required AuthRepository repository})
    : _repository = repository,
      super(const SessionState.unknown()) {
    _repository.onUnauthorized = (failure) {
      if (state.status == SessionStatus.authenticated) {
        emit(state.copyWith(status: SessionStatus.sessionExpired));
      }
    };
  }

  final AuthRepository _repository;

  /// Restore the session from the server; 401 lands in signedOut.
  Future<void> restoreSession() async {
    try {
      final identity = await _repository.session();
      emit(_authenticated(identity));
    } on Exception {
      emit(const SessionState(status: SessionStatus.signedOut));
    }
  }

  Future<void> login({
    required String loginName,
    required String password,
  }) async {
    emit(state.copyWith(status: SessionStatus.authenticating));
    try {
      final identity = await _repository.login(
        loginName: loginName,
        password: password,
      );
      emit(_authenticated(identity));
    } on Exception {
      emit(const SessionState(status: SessionStatus.signedOut));
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } on Exception {
      // Local logout still clears protected state.
    }
    emit(const SessionState(status: SessionStatus.signedOut));
  }

  void markSessionExpired() =>
      emit(state.copyWith(status: SessionStatus.sessionExpired));

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
