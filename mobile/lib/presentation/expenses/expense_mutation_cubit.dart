import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';

import '../../data/repositories/expenses_repository.dart';
import '../../data/repositories/repository_support.dart';
import '../../domain/read_models/read_models.dart';
import '../../domain/write_models/write_models.dart';

enum ExpenseMutationStatus { idle, loading, success, failure }

enum ExpenseMutationFailureKind {
  validation,
  unauthorized,
  forbidden,
  recovery,
  corruption,
}

final class ExpenseMutationFailure {
  ExpenseMutationFailure({
    required this.kind,
    required this.message,
    Map<String, String> fieldErrors = const {},
  }) : fieldErrors = Map.unmodifiable(fieldErrors);
  final ExpenseMutationFailureKind kind;
  final String message;
  final Map<String, String> fieldErrors;
}

final class ExpenseMutationState {
  const ExpenseMutationState({
    this.status = ExpenseMutationStatus.idle,
    this.result,
    this.failure,
    this.successMessage,
  });
  const ExpenseMutationState.success(ExpenseReadModel? result, String message)
    : this(
        status: ExpenseMutationStatus.success,
        result: result,
        successMessage: message,
      );
  const ExpenseMutationState.failure(ExpenseMutationFailure failure)
    : this(status: ExpenseMutationStatus.failure, failure: failure);
  final ExpenseMutationStatus status;
  final ExpenseReadModel? result;
  final ExpenseMutationFailure? failure;
  final String? successMessage;
  bool get isLoading => status == ExpenseMutationStatus.loading;
  bool get isDisabled => isLoading;
}

class _PostMutationRefreshException implements Exception {
  const _PostMutationRefreshException();
}

ExpenseMutationFailure mapExpenseMutationFailure(Object error) {
  if (error is _PostMutationRefreshException) return _recoveryFailure();
  if (error is DioException) return _mapDioFailure(error);
  if ((error is ExpenseWriteException && error.isCorruption) ||
      (error is ReadRepositoryException && error.isCorruption) ||
      error is FormatException) {
    return _corruptionFailure();
  }
  return _recoveryFailure();
}

ExpenseMutationFailure _mapDioFailure(DioException error) {
  final status = error.response?.statusCode;
  if (status == 401) {
    return ExpenseMutationFailure(
      kind: ExpenseMutationFailureKind.unauthorized,
      message: 'Your session expired. Please sign in again.',
    );
  }
  if (status == 403) {
    return ExpenseMutationFailure(
      kind: ExpenseMutationFailureKind.forbidden,
      message: 'You are not authorized to change expenses.',
    );
  }
  if ((status != null && status >= 500) ||
      error.type == DioExceptionType.connectionError ||
      error.response == null) {
    return _recoveryFailure();
  }
  final payload = _parseErrorResponse(error.response!.data);
  if (payload == null) return _corruptionFailure();
  return ExpenseMutationFailure(
    kind: ExpenseMutationFailureKind.validation,
    message: payload.message,
    fieldErrors: {
      for (final fieldError in payload.fieldErrors ?? const <FieldError>[])
        fieldError.field: fieldError.message,
    },
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

ExpenseMutationFailure _recoveryFailure() => ExpenseMutationFailure(
  kind: ExpenseMutationFailureKind.recovery,
  message: 'Please try again.',
);

ExpenseMutationFailure _corruptionFailure() => ExpenseMutationFailure(
  kind: ExpenseMutationFailureKind.corruption,
  message: 'Please try again.',
);

final class ExpenseMutationCubit extends Cubit<ExpenseMutationState> {
  ExpenseMutationCubit({
    required this.writer,
    required this.groupId,
    this.onMutationSuccess,
    this.onPostMutationRefreshRetry,
  }) : super(const ExpenseMutationState());
  final ExpensesWriter writer;
  final String groupId;
  final Future<void> Function()? onMutationSuccess;
  final Future<void> Function()? onPostMutationRefreshRetry;
  bool _inFlight = false;
  ExpenseReadModel? _pendingRefreshResult;
  String? _pendingRefreshSuccessMessage;

  bool get canRetryPostMutationRefresh =>
      !isClosed &&
      _pendingRefreshSuccessMessage != null &&
      onPostMutationRefreshRetry != null;

  Future<void> create(ExpenseWriteDraft draft) => _run(
    () => writer.createExpense(groupId, draft),
    'Expense created.',
    validation: _validate(draft),
  );
  Future<void> edit(String expenseId, ExpenseWriteDraft draft) => _run(
    () => writer.editExpense(groupId, expenseId, draft),
    'Expense updated.',
    validation: _validate(draft),
  );
  Future<void> delete(String expenseId) => _run(() async {
    await writer.deleteExpense(groupId, expenseId);
    return null;
  }, 'Expense deleted.');

  Future<void> _run(
    Future<ExpenseReadModel?> Function() operation,
    String message, {
    ExpenseMutationFailure? validation,
  }) async {
    if (isClosed || _inFlight) return;
    _clearPendingRefresh();
    if (validation != null) {
      emit(ExpenseMutationState.failure(validation));
      return;
    }
    _inFlight = true;
    emit(const ExpenseMutationState(status: ExpenseMutationStatus.loading));
    try {
      final result = await operation();
      if (isClosed) return;
      final refresh = onMutationSuccess;
      if (refresh != null) {
        try {
          await refresh();
        } on Object {
          if (!isClosed) _setPendingRefresh(result, message);
          throw const _PostMutationRefreshException();
        }
      }
      if (!isClosed) emit(ExpenseMutationState.success(result, message));
    } on Object catch (error) {
      if (!isClosed) {
        emit(ExpenseMutationState.failure(mapExpenseMutationFailure(error)));
      }
    } finally {
      _inFlight = false;
    }
  }

  Future<void> retryPostMutationRefresh() async {
    if (isClosed || _inFlight || !canRetryPostMutationRefresh) return;
    final result = _pendingRefreshResult;
    final message = _pendingRefreshSuccessMessage!;
    _inFlight = true;
    emit(const ExpenseMutationState(status: ExpenseMutationStatus.loading));
    try {
      await onPostMutationRefreshRetry!();
      if (isClosed) return;
      _clearPendingRefresh();
      emit(ExpenseMutationState.success(result, message));
    } on Object {
      if (!isClosed) {
        emit(ExpenseMutationState.failure(_recoveryFailure()));
      }
    } finally {
      _inFlight = false;
    }
  }

  void _setPendingRefresh(ExpenseReadModel? result, String message) {
    _pendingRefreshResult = result;
    _pendingRefreshSuccessMessage = message;
  }

  void _clearPendingRefresh() {
    _pendingRefreshResult = null;
    _pendingRefreshSuccessMessage = null;
  }

  ExpenseMutationFailure? _validate(ExpenseWriteDraft draft) {
    final errors = <String, String>{};
    if (draft.description.trim().isEmpty) {
      errors['description'] = 'Enter a description.';
    }
    if (draft.contributors.isEmpty) {
      errors['contributors'] = 'Add at least one contributor.';
    }
    for (var i = 0; i < draft.contributors.length; i++) {
      if (draft.contributors[i].participantId.trim().isEmpty) {
        errors['contributors[$i].participantId'] = 'Select a contributor.';
      }
    }
    if (draft.beneficiaryIds.isEmpty) {
      errors['beneficiaries'] = 'Add at least one beneficiary.';
    }
    return errors.isEmpty
        ? null
        : ExpenseMutationFailure(
            kind: ExpenseMutationFailureKind.validation,
            message: 'Please correct the expense fields.',
            fieldErrors: errors,
          );
  }
}
