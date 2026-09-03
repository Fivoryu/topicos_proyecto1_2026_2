import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';

import '../../data/repositories/participants_repository.dart';
import '../../data/repositories/repository_support.dart';
import '../../domain/read_models/read_models.dart';

enum ParticipantsMutationStatus { idle, loading, success, failure }

enum MutationFailureKind {
  validation,
  unauthorized,
  forbidden,
  protectedReference,
  recovery,
  corruption,
}

class MutationFailure {
  MutationFailure({
    required this.kind,
    required this.message,
    Map<String, String> fieldErrors = const {},
  }) : fieldErrors = Map.unmodifiable(fieldErrors);
  final MutationFailureKind kind;
  final String message;
  final Map<String, String> fieldErrors;
}

class ParticipantsMutationState {
  const ParticipantsMutationState({
    this.status = ParticipantsMutationStatus.idle,
    this.result,
    this.failure,
    this.successMessage,
  });
  const ParticipantsMutationState.loading()
    : this(status: ParticipantsMutationStatus.loading);
  const ParticipantsMutationState.success(
    ParticipantReadModel? result, {
    String? successMessage,
  }) : this(
         status: ParticipantsMutationStatus.success,
         result: result,
         successMessage: successMessage,
       );
  ParticipantsMutationState.failure(MutationFailure failure)
    : this(status: ParticipantsMutationStatus.failure, failure: failure);
  final ParticipantsMutationStatus status;
  final ParticipantReadModel? result;
  final MutationFailure? failure;
  final String? successMessage;
  bool get isLoading => status == ParticipantsMutationStatus.loading;
  bool get isDisabled => isLoading;
}

class _PostMutationRefreshException implements Exception {
  const _PostMutationRefreshException(this.cause, this.stackTrace);

  final Object cause;
  final StackTrace stackTrace;
}

MutationFailure mapParticipantMutationFailure(Object error) {
  if (error is _PostMutationRefreshException) return _recoveryFailure();
  if (error is ParticipantWriteException) {
    return MutationFailure(
      kind: MutationFailureKind.validation,
      message: error.message,
    );
  }
  if (error is DioException) return _mapDioFailure(error);
  if ((error is ReadRepositoryException && error.isCorruption) ||
      error is FormatException) {
    return _corruptionFailure();
  }
  return _recoveryFailure();
}

MutationFailure _mapDioFailure(DioException error) {
  final status = error.response?.statusCode;
  if (status == 401) {
    return MutationFailure(
      kind: MutationFailureKind.unauthorized,
      message: 'Your session expired. Please sign in again.',
    );
  }
  if (status == 403) {
    return MutationFailure(
      kind: MutationFailureKind.forbidden,
      message: 'You are not authorized to change participants.',
    );
  }
  if (status != null && status >= 500) return _recoveryFailure();
  final response = error.response;
  if (response == null) return _recoveryFailure();
  final payload = _parseErrorResponse(response.data);
  if (payload == null) return _corruptionFailure();
  if (payload.errorCode == 'participant_in_use') {
    return MutationFailure(
      kind: MutationFailureKind.protectedReference,
      message:
          'This participant is protected by historical references; '
          'archive it instead of deleting it.',
    );
  }
  final fields = <String, String>{
    for (final fieldError in payload.fieldErrors ?? const <FieldError>[])
      fieldError.field: fieldError.message,
  };
  return MutationFailure(
    kind: MutationFailureKind.validation,
    message: payload.message,
    fieldErrors: fields,
  );
}

ErrorResponse? _parseErrorResponse(Object? data) {
  if (data is ErrorResponse) return data;
  if (data is! Map) return null;
  try {
    return ErrorResponse.fromJson(Map<String, dynamic>.from(data));
  } on Object {
    return null;
  }
}

MutationFailure _recoveryFailure() => MutationFailure(
  kind: MutationFailureKind.recovery,
  message: 'The participant action could not be completed. Please try again.',
);
MutationFailure _corruptionFailure() => MutationFailure(
  kind: MutationFailureKind.corruption,
  message:
      'The participant response was incomplete or invalid. Please try again.',
);

class ParticipantsMutationCubit extends Cubit<ParticipantsMutationState> {
  ParticipantsMutationCubit({
    required this.writer,
    required this.groupId,
    this.onMutationSuccess,
    this.onPostMutationRefreshRetry,
  }) : super(const ParticipantsMutationState());
  final ParticipantsWriter writer;
  final String groupId;
  final Future<void> Function()? onMutationSuccess;
  final Future<void> Function()? onPostMutationRefreshRetry;
  bool _inFlight = false;
  ParticipantReadModel? _pendingRefreshResult;
  String? _pendingRefreshSuccessMessage;
  var _hasPendingRefreshResult = false;

  bool get canRetryPostMutationRefresh =>
      _hasPendingRefreshResult && onPostMutationRefreshRetry != null;
  Future<void> add(String name) => _runName(
    name,
    (normalized) => writer.addParticipant(groupId, normalized),
    'Participant added.',
  );
  Future<void> rename(String participantId, String name) => _runName(
    name,
    (normalized) =>
        writer.renameParticipant(groupId, participantId, normalized),
    'Participant renamed.',
  );
  Future<void> archive(String participantId) => _run(
    () => writer.archiveParticipant(groupId, participantId),
    successMessage: 'Participant archived.',
  );
  Future<void> reactivate(String participantId) => _run(
    () => writer.reactivateParticipant(groupId, participantId),
    successMessage: 'Participant reactivated.',
  );
  Future<void> delete(String participantId) => _run(() async {
    await writer.deleteParticipant(groupId, participantId);
    return null;
  }, successMessage: 'Participant deleted.');
  Future<void> _runName(
    String rawName,
    Future<ParticipantReadModel> Function(String name) operation,
    String successMessage,
  ) async {
    if (isClosed || _inFlight) return;
    _clearPendingRefresh();
    final name = rawName.trim();
    if (name.isEmpty) {
      emit(ParticipantsMutationState.failure(_blankNameFailure()));
      return;
    }
    await _run(() => operation(name), successMessage: successMessage);
  }

  Future<void> _run(
    Future<ParticipantReadModel?> Function() operation, {
    required String successMessage,
  }) async {
    if (isClosed || _inFlight) return;
    _clearPendingRefresh();
    _inFlight = true;
    emit(const ParticipantsMutationState.loading());
    try {
      final result = await operation();
      if (isClosed) return;
      final callback = onMutationSuccess;
      if (callback != null) {
        try {
          await callback();
        } on Object catch (error, stackTrace) {
          if (!isClosed) {
            _setPendingRefresh(result, successMessage);
          }
          throw _PostMutationRefreshException(error, stackTrace);
        }
      }
      if (!isClosed) {
        emit(
          ParticipantsMutationState.success(
            result,
            successMessage: successMessage,
          ),
        );
      }
    } on Object catch (error) {
      if (!isClosed) {
        emit(
          ParticipantsMutationState.failure(
            mapParticipantMutationFailure(error),
          ),
        );
      }
    } finally {
      _inFlight = false;
    }
  }

  Future<void> retryPostMutationRefresh() async {
    if (isClosed || _inFlight || !canRetryPostMutationRefresh) return;
    final result = _pendingRefreshResult;
    final successMessage = _pendingRefreshSuccessMessage;
    final hasResult = _hasPendingRefreshResult;
    _inFlight = true;
    emit(const ParticipantsMutationState.loading());
    try {
      await onPostMutationRefreshRetry!();
      if (isClosed) return;
      _clearPendingRefresh();
      emit(
        ParticipantsMutationState.success(
          hasResult ? result : null,
          successMessage: successMessage,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (!isClosed) {
        emit(
          ParticipantsMutationState.failure(
            mapParticipantMutationFailure(
              _PostMutationRefreshException(error, stackTrace),
            ),
          ),
        );
      }
    } finally {
      _inFlight = false;
    }
  }

  void _setPendingRefresh(ParticipantReadModel? result, String successMessage) {
    _pendingRefreshResult = result;
    _pendingRefreshSuccessMessage = successMessage;
    _hasPendingRefreshResult = true;
  }

  void _clearPendingRefresh() {
    _pendingRefreshResult = null;
    _pendingRefreshSuccessMessage = null;
    _hasPendingRefreshResult = false;
  }
}

MutationFailure _blankNameFailure() => MutationFailure(
  kind: MutationFailureKind.validation,
  message: 'Participant name must not be blank.',
  fieldErrors: const {'name': 'Enter a participant name.'},
);
