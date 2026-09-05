import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/openapi.dart';
import 'package:cuentas_claras_mobile/data/repositories/expenses_repository.dart';
import 'package:cuentas_claras_mobile/data/repositories/repository_support.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/domain/write_models/write_models.dart';
import 'package:cuentas_claras_mobile/presentation/expenses/expense_mutation_cubit.dart';

const _result = ExpenseReadModel(
  id: 'e',
  groupId: 'g',
  description: 'd',
  amountCents: 1230,
  contributors: [],
  beneficiaries: [],
);

void main() {
  test(
    'delegates commands, waits for refresh, and reports exact results',
    () async {
      final writer = _Writer()..createPending = Completer<ExpenseReadModel>();
      final refresh = Completer<void>();
      final draft = _draft();
      final cubit = _cubit(writer, () => refresh.future);
      final create = cubit.create(draft);
      expect(cubit.state.status, ExpenseMutationStatus.loading);
      expect(writer.draft, same(draft));
      writer.createPending!.complete(_result);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, ExpenseMutationStatus.loading);
      refresh.complete();
      await create;
      expect(cubit.state.result, same(_result));
      expect(cubit.state.successMessage, 'Expense created.');
      await cubit.edit('e', draft);
      await cubit.delete('e');
      expect(writer.calls.join(','), 'create:g,edit:g:e,delete:g:e');
      expect(cubit.state.result, isNull);
      expect(cubit.state.successMessage, 'Expense deleted.');
    },
  );
  test(
    'rejects invalid drafts without writer calls and exposes field errors',
    () async {
      final writer = _Writer();
      final cubit = _cubit(writer);
      await cubit.create(
        _draft(description: ' ', contributor: false, beneficiary: false),
      );
      expect(cubit.state.failure!.kind, ExpenseMutationFailureKind.validation);
      expect(
        cubit.state.failure!.fieldErrors.keys,
        containsAll(['description', 'contributors', 'beneficiaries']),
      );
      await cubit.create(_draft(contributorId: ' \t '));
      expect(
        cubit.state.failure!.fieldErrors,
        contains('contributors[0].participantId'),
      );
      expect(writer.calls, isEmpty);
    },
  );
  test('ignores duplicate commands while busy', () async {
    final writer = _Writer()..createPending = Completer<ExpenseReadModel>();
    final cubit = _cubit(writer);
    final first = cubit.create(_draft());
    await cubit.edit('e', _draft());
    expect(writer.calls, ['create:g']);
    writer.createPending!.complete(_result);
    await first;
  });
  test('suppresses late writer completion after close', () async {
    final writer = _Writer()..createPending = Completer<ExpenseReadModel>();
    final cubit = _cubit(writer);
    final request = cubit.create(_draft());
    await cubit.close();
    writer.createPending!.complete(_result);
    await request;
    expect(cubit.isClosed, isTrue);
    expect(cubit.state.status, ExpenseMutationStatus.loading);
  });
  test('maps API error payloads and malformed responses safely', () {
    final generated = _mapped(
      status: 422,
      data: ErrorResponse(
        errorCode: 'expense_invalid',
        message: 'Fix the expense.',
        fieldErrors: [FieldError(field: 'amount', message: 'Enter an amount.')],
      ),
    );
    expect(generated.kind, ExpenseMutationFailureKind.validation);
    expect(generated.message, 'Fix the expense.');
    expect(generated.fieldErrors, {'amount': 'Enter an amount.'});
    expect(
      () => generated.fieldErrors['amount'] = 'changed',
      throwsUnsupportedError,
    );
    final mapped = _mapped(
      status: 409,
      data: {
        'error_code': 'expense_conflict',
        'message': 'Choose another expense.',
        'field_errors': [
          {'field': 'description', 'message': 'Already used.'},
        ],
      },
    );
    expect(mapped.kind, ExpenseMutationFailureKind.validation);
    expect(mapped.fieldErrors, {'description': 'Already used.'});
    expect(
      _mapped(status: 404, data: {'error_code': 'missing_message'}).kind,
      ExpenseMutationFailureKind.corruption,
    );
  });
  test('maps transport and repository failures without leaking details', () {
    expect(
      _mapped(status: 401).message,
      'Your session expired. Please sign in again.',
    );
    expect(
      _mapped(status: 403).message,
      'You are not authorized to change expenses.',
    );
    expect(_mapped(status: 503).message, 'Please try again.');
    for (final error in [
      _dio(type: DioExceptionType.connectionError),
      const ExpenseWriteException('csrf'),
      const ReadRepositoryException('config'),
      Object(),
    ]) {
      expect(
        mapExpenseMutationFailure(error).kind,
        ExpenseMutationFailureKind.recovery,
      );
    }
    for (final error in [
      const ExpenseWriteException('bad', isCorruption: true),
      const ReadRepositoryException('bad', isCorruption: true),
      const FormatException('secret'),
    ]) {
      final failure = mapExpenseMutationFailure(error);
      expect(failure.kind, ExpenseMutationFailureKind.corruption);
      expect(failure.message, isNot(contains('secret')));
    }
  });
  test(
    'keeps server authorization and contribution validation authoritative',
    () async {
      var refreshCalls = 0;
      final writer = _Writer()
        ..createError = _dio(
          statusCode: 422,
          data: ErrorResponse(
            errorCode: 'expense_contribution_mismatch',
            message: 'Contributions do not match the expense amount.',
            fieldErrors: [
              FieldError(
                field: 'contributors',
                message: 'Contribution total must match the amount.',
              ),
            ],
          ),
        )
        ..editError = _dio(statusCode: 403)
        ..deleteError = _dio(statusCode: 401);
      final cubit = _cubit(writer, () async => refreshCalls++);
      final draft = _draft();

      await cubit.create(draft);
      expect(writer.draft, same(draft));
      expect(writer.draft!.amount.text, '12.30');
      expect(writer.draft!.contributors.single.amount.text, '12.30');
      expect(cubit.state.failure?.kind, ExpenseMutationFailureKind.validation);
      expect(
        cubit.state.failure?.fieldErrors['contributors'],
        'Contribution total must match the amount.',
      );
      expect(refreshCalls, 0);

      await cubit.edit('e', draft);
      expect(cubit.state.failure?.kind, ExpenseMutationFailureKind.forbidden);
      expect(refreshCalls, 0);

      await cubit.delete('e');
      expect(
        cubit.state.failure?.kind,
        ExpenseMutationFailureKind.unauthorized,
      );
      expect(refreshCalls, 0);
      expect(writer.calls, ['create:g', 'edit:g:e', 'delete:g:e']);
    },
  );
  test(
    'retries refresh without repeating the writer or losing its result',
    () async {
      var refreshCalls = 0;
      var retryCalls = 0;
      final writer = _Writer();
      final cubit = _cubit(writer, () async {
        refreshCalls++;
        throw StateError('refresh');
      }, () async => retryCalls++);
      await cubit.create(_draft());
      expect(writer.calls, ['create:g']);
      expect(refreshCalls, 1);
      expect(cubit.canRetryPostMutationRefresh, isTrue);
      await cubit.retryPostMutationRefresh();
      expect(retryCalls, 1);
      expect(writer.calls, ['create:g']);
      expect(cubit.state.result, same(_result));
      expect(cubit.state.successMessage, 'Expense created.');
      expect(cubit.canRetryPostMutationRefresh, isFalse);
    },
  );
  test('retains null delete refresh state across retry failure', () async {
    var retryCalls = 0;
    final writer = _Writer();
    final cubit = _cubit(
      writer,
      () async => throw StateError('refresh'),
      () async {
        retryCalls++;
        if (retryCalls == 1) throw StateError('retry');
      },
    );
    await cubit.delete('e');
    await cubit.retryPostMutationRefresh();
    expect(cubit.state.failure!.kind, ExpenseMutationFailureKind.recovery);
    expect(cubit.canRetryPostMutationRefresh, isTrue);
    await cubit.retryPostMutationRefresh();
    expect(cubit.state.result, isNull);
    expect(cubit.state.successMessage, 'Expense deleted.');
    expect(writer.calls, ['delete:g:e']);
  });
  test(
    'busy retry preserves pending state and a new invalid mutation clears it',
    () async {
      final retry = Completer<void>();
      final writer = _Writer();
      final cubit = _cubit(
        writer,
        () async => throw StateError('refresh'),
        () => retry.future,
      );
      await cubit.create(_draft());
      final retryRequest = cubit.retryPostMutationRefresh();
      await cubit.create(_draft(description: ' '));
      expect(cubit.canRetryPostMutationRefresh, isTrue);
      retry.complete();
      await retryRequest;
      await cubit.create(_draft());
      expect(cubit.canRetryPostMutationRefresh, isTrue);
      await cubit.create(_draft(description: ' '));
      expect(cubit.canRetryPostMutationRefresh, isFalse);
      expect(writer.calls, ['create:g', 'create:g']);
    },
  );
  test('close suppresses late refresh retry completion', () async {
    final retry = Completer<void>();
    final cubit = _cubit(
      _Writer(),
      () async => throw StateError('refresh'),
      () => retry.future,
    );
    await cubit.create(_draft());
    final request = cubit.retryPostMutationRefresh();
    await cubit.close();
    retry.complete();
    await request;
    expect(cubit.isClosed, isTrue);
    expect(cubit.canRetryPostMutationRefresh, isFalse);
    expect(cubit.state.status, ExpenseMutationStatus.loading);
  });
}

DioException _dio({
  int? statusCode,
  Object? data,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  final request = RequestOptions(path: '/expenses');
  return DioException(
    requestOptions: request,
    type: type,
    response: statusCode == null
        ? null
        : Response<dynamic>(
            requestOptions: request,
            statusCode: statusCode,
            data: data,
          ),
  );
}

ExpenseMutationFailure _mapped({int? status, Object? data}) =>
    mapExpenseMutationFailure(_dio(statusCode: status, data: data));

ExpenseMutationCubit _cubit(
  _Writer writer, [
  Future<void> Function()? refresh,
  Future<void> Function()? retry,
]) => ExpenseMutationCubit(
  writer: writer,
  groupId: 'g',
  onMutationSuccess: refresh,
  onPostMutationRefreshRetry: retry,
);

ExpenseContributorDraft _contributor(String id) => ExpenseContributorDraft(
  participantId: id,
  amount: ExpenseAmount.parse('12.30'),
);

ExpenseWriteDraft _draft({
  String description = 'Dinner',
  bool contributor = true,
  bool beneficiary = true,
  String contributorId = 'participant-1',
}) => ExpenseWriteDraft(
  description: description,
  amount: ExpenseAmount.parse('12.30'),
  contributors: contributor ? [_contributor(contributorId)] : const [],
  beneficiaryIds: beneficiary ? const ['participant-2'] : const [],
);

class _Writer implements ExpensesWriter {
  final calls = <String>[];
  ExpenseWriteDraft? draft;
  Completer<ExpenseReadModel>? createPending;
  Object? createError;
  Object? editError;
  Object? deleteError;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    final args = invocation.positionalArguments;
    final name = invocation.memberName;
    if (name == #deleteExpense) {
      calls.add('delete:${args[0]}:${args[1]}');
      final error = deleteError;
      return error == null ? Future<void>.value() : Future<void>.error(error);
    }
    final create = name == #createExpense;
    if (!create && name != #editExpense) return super.noSuchMethod(invocation);
    calls.add(create ? 'create:${args[0]}' : 'edit:${args[0]}:${args[1]}');
    draft = args[create ? 1 : 2] as ExpenseWriteDraft;
    final error = create ? createError : editError;
    if (error != null) return Future<ExpenseReadModel>.error(error);
    return create
        ? createPending?.future ?? Future.value(_result)
        : Future.value(_result);
  }
}
