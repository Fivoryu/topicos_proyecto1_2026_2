import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';

import '../../domain/read_models/read_models.dart';
import '../../domain/write_models/write_models.dart';
import '../auth/auth_transport.dart';
import 'repository_support.dart';

typedef ExpenseCsrfTokenProvider = Future<String> Function();

abstract interface class ExpensesOperations {
  Future<Response<List<ExpenseResponse>>> listExpenses({
    required String groupId,
  });
}

abstract interface class ExpensesWriteOperations {
  Future<Response<ExpenseResponse>> createExpense({
    required String groupId,
    required String xCSRFToken,
    required ExpenseWriteRequest expenseWriteRequest,
  });

  Future<Response<ExpenseResponse>> editExpense({
    required String groupId,
    required String expenseId,
    required String xCSRFToken,
    required ExpenseWriteRequest expenseWriteRequest,
  });

  Future<Response<void>> deleteExpense({
    required String groupId,
    required String expenseId,
    required String xCSRFToken,
  });
}

class GeneratedExpensesOperations
    implements ExpensesOperations, ExpensesWriteOperations {
  const GeneratedExpensesOperations(this.api);

  final ExpensesApi api;

  @override
  Future<Response<ExpenseResponse>> createExpense({
    required String groupId,
    required String xCSRFToken,
    required ExpenseWriteRequest expenseWriteRequest,
  }) => api.createExpenseApiV1GroupsGroupIdExpensesPost(
    groupId: groupId,
    xCSRFToken: xCSRFToken,
    expenseWriteRequest: expenseWriteRequest,
  );

  @override
  Future<Response<void>> deleteExpense({
    required String groupId,
    required String expenseId,
    required String xCSRFToken,
  }) => api.deleteExpenseApiV1GroupsGroupIdExpensesExpenseIdDelete(
    groupId: groupId,
    expenseId: expenseId,
    xCSRFToken: xCSRFToken,
  );

  @override
  Future<Response<ExpenseResponse>> editExpense({
    required String groupId,
    required String expenseId,
    required String xCSRFToken,
    required ExpenseWriteRequest expenseWriteRequest,
  }) => api.editExpenseApiV1GroupsGroupIdExpensesExpenseIdPatch(
    groupId: groupId,
    expenseId: expenseId,
    xCSRFToken: xCSRFToken,
    expenseWriteRequest: expenseWriteRequest,
  );

  @override
  Future<Response<List<ExpenseResponse>>> listExpenses({
    required String groupId,
  }) => api.listExpensesApiV1GroupsGroupIdExpensesGet(groupId: groupId);
}

abstract interface class ExpensesReader {
  Future<List<ExpenseReadModel>> listExpenses(String groupId);
}

abstract interface class ExpensesWriter {
  Future<ExpenseReadModel> createExpense(
    String groupId,
    ExpenseWriteDraft draft,
  );

  Future<ExpenseReadModel> editExpense(
    String groupId,
    String expenseId,
    ExpenseWriteDraft draft,
  );

  Future<void> deleteExpense(String groupId, String expenseId);
}

class ExpenseWriteException implements Exception {
  const ExpenseWriteException(this.message, {this.isCorruption = false});

  final String message;
  final bool isCorruption;

  @override
  String toString() => message;
}

class ExpensesRepository implements ExpensesReader, ExpensesWriter {
  ExpensesRepository({required this.operations, this.csrfTokenProvider});

  factory ExpensesRepository.fromTransport(AuthTransport transport) =>
      ExpensesRepository(
        operations: GeneratedExpensesOperations(
          transport.client.getExpensesApi(),
        ),
        csrfTokenProvider: () =>
            _csrfTokenFromJar(transport.cookieJar, transport.baseUri),
      );

  final ExpensesOperations operations;
  final ExpenseCsrfTokenProvider? csrfTokenProvider;

  @override
  Future<List<ExpenseReadModel>> listExpenses(String groupId) async {
    try {
      final data = requireReadData(
        await operations.listExpenses(groupId: groupId),
        'expense history',
      );
      return List.unmodifiable(data.map(ExpenseReadModel.fromDto));
    } on ReadRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw corruptionFailure(error, 'expense history');
    }
  }

  @override
  Future<ExpenseReadModel> createExpense(
    String groupId,
    ExpenseWriteDraft draft,
  ) async {
    final operations = _writeOperations();
    final response = await operations.createExpense(
      groupId: groupId,
      xCSRFToken: await _csrfToken(),
      expenseWriteRequest: _toRequest(draft),
    );
    return _readWriteResponse(response, groupId);
  }

  @override
  Future<ExpenseReadModel> editExpense(
    String groupId,
    String expenseId,
    ExpenseWriteDraft draft,
  ) async {
    final operations = _writeOperations();
    final response = await operations.editExpense(
      groupId: groupId,
      expenseId: expenseId,
      xCSRFToken: await _csrfToken(),
      expenseWriteRequest: _toRequest(draft),
    );
    return _readWriteResponse(response, groupId);
  }

  @override
  Future<void> deleteExpense(String groupId, String expenseId) async {
    final operations = _writeOperations();
    await operations.deleteExpense(
      groupId: groupId,
      expenseId: expenseId,
      xCSRFToken: await _csrfToken(),
    );
  }

  Future<List<ExpenseReadModel>> fetch(String groupId) => listExpenses(groupId);

  ExpensesWriteOperations _writeOperations() {
    final value = operations;
    if (value is! ExpensesWriteOperations) {
      throw const ExpenseWriteException(
        'Expense write operations are not configured.',
      );
    }
    return value as ExpensesWriteOperations;
  }

  Future<String> _csrfToken() async {
    final provider = csrfTokenProvider;
    if (provider == null) {
      throw const ExpenseWriteException(
        'CSRF token provider is not configured.',
      );
    }
    return provider();
  }
}

ExpenseWriteRequest _toRequest(ExpenseWriteDraft draft) => ExpenseWriteRequest(
  amount: draft.amount.text,
  beneficiaryIds: List.unmodifiable(draft.beneficiaryIds),
  contributors: List.unmodifiable(
    draft.contributors.map(
      (item) => ExpenseContributorRequest(
        amount: item.amount.text,
        participantId: item.participantId,
      ),
    ),
  ),
  description: draft.description,
);

ExpenseReadModel _readWriteResponse(
  Response<ExpenseResponse> response,
  String groupId,
) {
  final data = response.data;
  if (data == null) {
    throw const ExpenseWriteException(
      'The server returned incomplete expense data.',
      isCorruption: true,
    );
  }
  try {
    if (data.id.trim().isEmpty || data.groupId != groupId) {
      throw const FormatException('required expense fields are invalid');
    }
    return ExpenseReadModel.fromDto(data);
  } catch (error) {
    throw ExpenseWriteException(
      'The server returned corrupted expense data: $error',
      isCorruption: true,
    );
  }
}

Future<String> _csrfTokenFromJar(CookieJar cookieJar, Uri baseUri) async {
  final cookies = await cookieJar.loadForRequest(baseUri);
  for (final cookie in cookies) {
    if (cookie.name == csrfCookieName) return cookie.value;
  }
  throw const ExpenseWriteException(
    'A CSRF token is required for this operation.',
  );
}

typedef ExpenseReadRepository = ExpensesRepository;
