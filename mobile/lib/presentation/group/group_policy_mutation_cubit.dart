import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';

import '../../data/repositories/group_repository.dart';
import '../../domain/read_models/read_models.dart';

enum GroupPolicyMutationStatus { idle, loading, success, failure }

enum GroupPolicyMutationFailureKind {
  validation,
  unauthorized,
  forbidden,
  action,
  network,
  corruption,
  recovery,
}

final class GroupPolicyMutationFailure {
  GroupPolicyMutationFailure({
    required this.kind,
    required this.message,
    Map<String, String> fieldErrors = const {},
  }) : fieldErrors = Map.unmodifiable(fieldErrors);

  final GroupPolicyMutationFailureKind kind;
  final String message;
  final Map<String, String> fieldErrors;
}

final class GroupPolicyMutationState {
  const GroupPolicyMutationState({
    this.status = GroupPolicyMutationStatus.idle,
    this.result,
    this.failure,
    this.successMessage,
  });

  const GroupPolicyMutationState.loading({GroupReadModel? result})
    : this(status: GroupPolicyMutationStatus.loading, result: result);

  const GroupPolicyMutationState.success(GroupReadModel result, String message)
    : this(
        status: GroupPolicyMutationStatus.success,
        result: result,
        successMessage: message,
      );

  const GroupPolicyMutationState.failure(
    GroupPolicyMutationFailure failure, {
    GroupReadModel? result,
  }) : this(
         status: GroupPolicyMutationStatus.failure,
         result: result,
         failure: failure,
       );

  final GroupPolicyMutationStatus status;
  final GroupReadModel? result;
  final GroupPolicyMutationFailure? failure;
  final String? successMessage;

  bool get isLoading => status == GroupPolicyMutationStatus.loading;
  bool get isDisabled => isLoading;
}

class _PostMutationRefreshException implements Exception {
  const _PostMutationRefreshException();
}

GroupPolicyMutationFailure mapGroupPolicyMutationFailure(Object error) {
  if (error is _PostMutationRefreshException) {
    return _recoveryFailure(
      'The policy changed, but the latest group data could not be loaded. '
      'Retry the refresh before trying another change.',
    );
  }
  if (error is GroupWriteException) {
    return error.isCorruption
        ? _corruptionFailure()
        : _actionFailure(error.message);
  }
  if (error is DioException) return _mapDioFailure(error);
  if (error is FormatException) return _corruptionFailure();
  return _recoveryFailure();
}

GroupPolicyMutationFailure _mapDioFailure(DioException error) {
  final status = error.response?.statusCode;
  if (status == 401) {
    return GroupPolicyMutationFailure(
      kind: GroupPolicyMutationFailureKind.unauthorized,
      message: 'Your session expired. Please sign in again.',
    );
  }
  if (status == 403) {
    return GroupPolicyMutationFailure(
      kind: GroupPolicyMutationFailureKind.forbidden,
      message: 'You are not authorized to change the settlement policy.',
    );
  }
  if (error.response == null || _isNetworkError(error)) {
    return GroupPolicyMutationFailure(
      kind: GroupPolicyMutationFailureKind.network,
      message:
          'The network is unavailable. Check your connection and try again.',
    );
  }
  if (status != null && status >= 500) return _recoveryFailure();

  final payload = _policyErrorPayload(error.response!.data);
  if (payload == null) return _corruptionFailure();
  final fields = payload.fieldErrors;
  if (fields.isNotEmpty ||
      payload.isValidation ||
      status == 400 ||
      status == 422) {
    return GroupPolicyMutationFailure(
      kind: GroupPolicyMutationFailureKind.validation,
      message: payload.message,
      fieldErrors: fields,
    );
  }
  if (payload.isAction) return _actionFailure(payload.message);
  return _corruptionFailure();
}

bool _isNetworkError(DioException error) => switch (error.type) {
  DioExceptionType.connectionError ||
  DioExceptionType.connectionTimeout ||
  DioExceptionType.sendTimeout ||
  DioExceptionType.receiveTimeout ||
  DioExceptionType.badCertificate => true,
  _ => false,
};

final class _PolicyErrorPayload {
  const _PolicyErrorPayload({
    required this.message,
    this.fieldErrors = const {},
    this.isAction = false,
    this.isValidation = false,
  });

  final String message;
  final Map<String, String> fieldErrors;
  final bool isAction;
  final bool isValidation;
}

_PolicyErrorPayload? _policyErrorPayload(Object? data) {
  if (data is ErrorResponse) {
    final fields = <String, String>{
      for (final fieldError in data.fieldErrors ?? const <FieldError>[])
        fieldError.field: fieldError.message,
    };
    final code = data.errorCode.toLowerCase();
    return _PolicyErrorPayload(
      message: data.message,
      fieldErrors: fields,
      isAction:
          fields.isEmpty &&
          (code.contains('action') || code.contains('conflict')),
      isValidation:
          fields.isNotEmpty ||
          code.contains('invalid') ||
          code.contains('validation'),
    );
  }
  if (data is! Map) return null;

  final message = data['message']?.toString().trim();
  final fieldErrors = <String, String>{};
  final rawFields = data['field_errors'];
  if (rawFields is Map) {
    for (final entry in rawFields.entries) {
      final value = entry.value;
      final detail = value is Iterable
          ? (value.isEmpty ? null : value.first)
          : value;
      if (detail != null) fieldErrors[entry.key.toString()] = detail.toString();
    }
  }
  final action = data['action']?.toString().trim();
  final code = data['error_code']?.toString().toLowerCase() ?? '';
  final fallbackMessage = fieldErrors.isNotEmpty
      ? 'Settlement policy is invalid.'
      : action != null && action.isNotEmpty
      ? 'The policy action could not be completed.'
      : null;
  if ((message == null || message.isEmpty) && fallbackMessage == null) {
    return null;
  }
  return _PolicyErrorPayload(
    message: message?.isNotEmpty == true ? message! : fallbackMessage!,
    fieldErrors: fieldErrors,
    isAction: action != null && action.isNotEmpty || code.contains('conflict'),
    isValidation:
        fieldErrors.isNotEmpty ||
        code.contains('invalid') ||
        code.contains('validation'),
  );
}

GroupPolicyMutationFailure _actionFailure(String message) =>
    GroupPolicyMutationFailure(
      kind: GroupPolicyMutationFailureKind.action,
      message: message.isEmpty
          ? 'The policy action could not be completed. Please try again.'
          : message,
    );

GroupPolicyMutationFailure _corruptionFailure() => GroupPolicyMutationFailure(
  kind: GroupPolicyMutationFailureKind.corruption,
  message:
      'The policy response was incomplete or invalid. Please recover the server data before trying again.',
);

GroupPolicyMutationFailure _recoveryFailure([
  String message =
      'The policy action could not be completed. Please try again.',
]) => GroupPolicyMutationFailure(
  kind: GroupPolicyMutationFailureKind.recovery,
  message: message,
);

final class GroupPolicyMutationCubit extends Cubit<GroupPolicyMutationState> {
  GroupPolicyMutationCubit({
    required this.writer,
    required this.groupId,
    this.onMutationSuccess,
    this.onPostMutationRefreshRetry,
  }) : super(const GroupPolicyMutationState());

  final GroupWriter writer;
  final String groupId;
  final Future<void> Function()? onMutationSuccess;
  final Future<void> Function()? onPostMutationRefreshRetry;

  bool _inFlight = false;
  GroupReadModel? _pendingRefreshResult;
  String? _pendingRefreshSuccessMessage;
  var _refreshRetryUsed = false;

  bool get canRetryPostMutationRefresh =>
      !isClosed &&
      !_refreshRetryUsed &&
      _pendingRefreshSuccessMessage != null &&
      onPostMutationRefreshRetry != null;

  Future<void> update(SettlementPolicy policy) =>
      updateSettlementPolicy(policy);

  Future<void> updatePolicy(SettlementPolicy policy) =>
      updateSettlementPolicy(policy);

  Future<void> updateSettlementPolicy(SettlementPolicy policy) async {
    if (isClosed || _inFlight) return;
    _clearPendingRefresh();
    _refreshRetryUsed = false;
    _inFlight = true;
    emit(const GroupPolicyMutationState.loading());
    try {
      final result = await writer.updateSettlementPolicy(groupId, policy);
      if (isClosed) return;
      final refresh = onMutationSuccess;
      if (refresh != null) {
        try {
          await refresh();
        } on Object {
          if (!isClosed) {
            _setPendingRefresh(result, 'Settlement policy updated.');
            emit(
              GroupPolicyMutationState.failure(
                mapGroupPolicyMutationFailure(
                  const _PostMutationRefreshException(),
                ),
                result: result,
              ),
            );
          }
          return;
        }
      }
      if (!isClosed) {
        emit(
          GroupPolicyMutationState.success(
            result,
            'Settlement policy updated.',
          ),
        );
      }
    } on Object catch (error) {
      if (!isClosed) {
        emit(
          GroupPolicyMutationState.failure(
            mapGroupPolicyMutationFailure(error),
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
    final successMessage = _pendingRefreshSuccessMessage!;
    _refreshRetryUsed = true;
    _inFlight = true;
    emit(GroupPolicyMutationState.loading(result: result));
    try {
      await onPostMutationRefreshRetry!();
      if (isClosed) return;
      _clearPendingRefresh();
      emit(GroupPolicyMutationState.success(result!, successMessage));
    } on Object {
      if (!isClosed) {
        emit(
          GroupPolicyMutationState.failure(
            _recoveryFailure(
              'The group policy is still out of date. Please try again later.',
            ),
            result: result,
          ),
        );
      }
    } finally {
      _inFlight = false;
    }
  }

  void _setPendingRefresh(GroupReadModel result, String message) {
    _pendingRefreshResult = result;
    _pendingRefreshSuccessMessage = message;
  }

  void _clearPendingRefresh() {
    _pendingRefreshResult = null;
    _pendingRefreshSuccessMessage = null;
  }
}

typedef GroupMutationCubit = GroupPolicyMutationCubit;
typedef GroupMutationState = GroupPolicyMutationState;
typedef GroupMutationStatus = GroupPolicyMutationStatus;
typedef GroupMutationFailure = GroupPolicyMutationFailure;
typedef GroupMutationFailureKind = GroupPolicyMutationFailureKind;
typedef PolicyMutationCubit = GroupPolicyMutationCubit;
typedef PolicyMutationState = GroupPolicyMutationState;
typedef PolicyMutationStatus = GroupPolicyMutationStatus;
typedef PolicyMutationFailure = GroupPolicyMutationFailure;
typedef PolicyMutationFailureKind = GroupPolicyMutationFailureKind;
