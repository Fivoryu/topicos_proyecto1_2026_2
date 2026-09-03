import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/openapi.dart';

import 'package:cuentas_claras_mobile/data/repositories/expenses_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/domain/write_models/write_models.dart';

Response<T> _response<T>(T? data, {int statusCode = 200}) => Response<T>(
  data: data,
  statusCode: statusCode,
  requestOptions: RequestOptions(path: '/expenses'),
);

void main() {
  test(
    'create and edit preserve lexical requests and server responses',
    () async {
      final operations = _Operations(
        createData: _expense(amountCents: 1230),
        editData: _expense(amountCents: 999),
      );
      final repository = _repository(operations, 'csrf-token');
      final draft = _draft(
        amount: '00012.30',
        contributorAmounts: ['0001.20', '0000.10'],
        beneficiaryIds: ['guest-2', 'guest-1'],
      );

      final created = await repository.createExpense('group-1', draft);
      final edited = await repository.editExpense(
        'group-1',
        'expense-1',
        draft,
      );

      expect(created.amountCents, 1230);
      expect(created.contributors.single.amountCents, 1);
      expect(edited.amountCents, 999);
      expect(operations.createCall!.$1, 'group-1');
      expect(operations.createCall!.$2, 'csrf-token');
      expect(operations.editCall!.$1, 'group-1');
      expect(operations.editCall!.$2, 'expense-1');
      expect(operations.editCall!.$3, 'csrf-token');
      expect(operations.createCall!.$3.toJson(), {
        'amount': '00012.30',
        'beneficiary_ids': ['guest-2', 'guest-1'],
        'contributors': [
          {'amount': '0001.20', 'participant_id': 'payer-1'},
          {'amount': '0000.10', 'participant_id': 'payer-2'},
        ],
        'description': 'Dinner',
      });
      expect(
        operations.editCall!.$4.toJson(),
        operations.createCall!.$3.toJson(),
      );
    },
  );

  test(
    'delete delegates scope and token and accepts a null 204 body',
    () async {
      final operations = _Operations();
      await _repository(
        operations,
        'delete-token',
      ).deleteExpense('group-2', 'expense-2');
      expect(operations.deleteCall, ('group-2', 'expense-2', 'delete-token'));
    },
  );

  test(
    'missing csrf and list-only operations fail before write calls',
    () async {
      final write = _Operations();
      await _expectWriteFailure(
        _repository(write, null).deleteExpense('group-1', 'expense-1'),
      );
      expect(write.deleteCalls, 0);
      await _expectWriteFailure(
        _repository(
          _ListOnlyOperations(),
        ).deleteExpense('group-1', 'expense-1'),
      );
    },
  );

  test(
    'null and malformed write responses are typed corruption failures',
    () async {
      await _expectCorruption(
        _repository(
          _Operations(createData: null),
        ).createExpense('group-1', _draft()),
      );
      await _expectCorruption(
        _repository(
          _Operations(editData: _expense(id: '', amountCents: -1)),
        ).editExpense('group-1', 'expense-1', _draft()),
      );
    },
  );

  test(
    'DioException server and network failures are rethrown unchanged',
    () async {
      final failures = <DioException>[
        _dioFailure(401, {'error_code': 'signed_out'}),
        _dioFailure(403, {'action': 'owner_required'}),
        _dioFailure(422, {
          'field_errors': {
            'amount': ['invalid'],
          },
        }),
        DioException(
          requestOptions: RequestOptions(path: '/expenses'),
          type: DioExceptionType.connectionError,
        ),
        _dioFailure(503, {'error_code': 'unavailable'}),
      ];
      for (final failure in failures) {
        await expectLater(
          _repository(
            _Operations(error: failure),
          ).createExpense('group-1', _draft()),
          throwsA(same(failure)),
        );
      }
    },
  );

  test('does not correct a server contribution mismatch', () async {
    final failure = _dioFailure(422, {
      'error_code': 'contribution_mismatch',
      'message': 'Contributor amounts must equal the expense amount.',
    });
    final operations = _Operations(error: failure);
    await expectLater(
      _repository(operations).createExpense(
        'group-1',
        _draft(amount: '10.00', contributorAmounts: ['1.00']),
      ),
      throwsA(same(failure)),
    );
    expect(operations.createCall!.$3.amount, '10.00');
    expect(operations.createCall!.$3.contributors.single.amount, '1.00');
  });

  test('forwards server-owned reference and shape errors unchanged', () async {
    final failure = _dioFailure(422, {
      'error_code': 'invalid_participant_reference',
      'message': 'The expense references an invalid participant.',
    });
    final operations = _Operations(error: failure);
    final draft = ExpenseWriteDraft(
      description: 'Dinner',
      amount: ExpenseAmount.parse('10.00'),
      contributors: [
        ExpenseContributorDraft(
          participantId: 'foreign-participant',
          amount: ExpenseAmount.parse('10.00'),
        ),
      ],
      beneficiaryIds: const [],
    );

    await expectLater(
      _repository(operations).createExpense('group-1', draft),
      throwsA(same(failure)),
    );
    expect(
      operations.createCall!.$3.contributors.single.participantId,
      'foreign-participant',
    );
    expect(operations.createCall!.$3.beneficiaryIds, isEmpty);
  });

  test('invalid amount prevents draft construction and generated calls', () {
    final operations = _Operations();
    expect(
      () => _draft(amount: '0'),
      throwsA(isA<InvalidExpenseAmountException>()),
    );
    expect(operations.createCalls, 0);
  });
}

Future<void> _expectWriteFailure(Future<void> operation) =>
    expectLater(operation, throwsA(isA<ExpenseWriteException>()));

Future<void> _expectCorruption(Future<ExpenseReadModel> operation) async {
  try {
    await operation;
    fail('expected a corruption failure');
  } on ExpenseWriteException catch (error) {
    expect(error.isCorruption, isTrue);
  }
}

ExpensesRepository _repository(
  ExpensesOperations operations, [
  String? token = 'csrf',
]) => ExpensesRepository(
  operations: operations,
  csrfTokenProvider: token == null ? null : () async => token,
);

ExpenseWriteDraft _draft({
  String amount = '12.30',
  List<String> contributorAmounts = const ['1.20'],
  List<String> beneficiaryIds = const ['guest-1'],
}) => ExpenseWriteDraft(
  description: 'Dinner',
  amount: ExpenseAmount.parse(amount),
  contributors: [
    for (var index = 0; index < contributorAmounts.length; index++)
      ExpenseContributorDraft(
        participantId: 'payer-${index + 1}',
        amount: ExpenseAmount.parse(contributorAmounts[index]),
      ),
  ],
  beneficiaryIds: beneficiaryIds,
);

ExpenseResponse _expense({String id = 'expense-1', int amountCents = 1230}) =>
    ExpenseResponse.fromJson({
      'id': id,
      'group_id': 'group-1',
      'description': 'Dinner',
      'amount_cents': amountCents,
      'contributors': [
        {
          'participant_id': 'payer-1',
          'name': 'Payer',
          'archived': false,
          'amount_cents': 1,
        },
      ],
      'beneficiaries': [
        {'participant_id': 'guest-1', 'name': 'Guest', 'archived': false},
      ],
    });

DioException _dioFailure(int status, Object data) {
  final requestOptions = RequestOptions(path: '/expenses');
  return DioException(
    requestOptions: requestOptions,
    response: Response<Object>(
      data: data,
      statusCode: status,
      requestOptions: requestOptions,
    ),
  );
}

class _ListOnlyOperations implements ExpensesOperations {
  @override
  Future<Response<List<ExpenseResponse>>> listExpenses({
    required String groupId,
  }) async => _response(const []);
}

class _Operations extends _ListOnlyOperations
    implements ExpensesWriteOperations {
  _Operations({this.createData, this.editData, this.error});

  final ExpenseResponse? createData;
  final ExpenseResponse? editData;
  final DioException? error;
  (String, String, ExpenseWriteRequest)? createCall;
  (String, String, String, ExpenseWriteRequest)? editCall;
  (String, String, String)? deleteCall;
  var createCalls = 0;
  var deleteCalls = 0;

  @override
  Future<Response<ExpenseResponse>> createExpense({
    required String groupId,
    required String xCSRFToken,
    required ExpenseWriteRequest expenseWriteRequest,
  }) {
    createCalls++;
    createCall = (groupId, xCSRFToken, expenseWriteRequest);
    return _result(_response(createData));
  }

  @override
  Future<Response<ExpenseResponse>> editExpense({
    required String groupId,
    required String expenseId,
    required String xCSRFToken,
    required ExpenseWriteRequest expenseWriteRequest,
  }) {
    editCall = (groupId, expenseId, xCSRFToken, expenseWriteRequest);
    return _result(_response(editData));
  }

  @override
  Future<Response<void>> deleteExpense({
    required String groupId,
    required String expenseId,
    required String xCSRFToken,
  }) {
    deleteCalls++;
    deleteCall = (groupId, expenseId, xCSRFToken);
    return _result(_response<void>(null, statusCode: 204));
  }

  Future<T> _result<T>(T value) =>
      error == null ? Future.value(value) : Future.error(error!);
}
