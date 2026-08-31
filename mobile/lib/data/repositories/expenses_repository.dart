import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';

import '../../domain/read_models/read_models.dart';
import '../auth/auth_transport.dart';
import 'repository_support.dart';

abstract interface class ExpensesOperations {
  Future<Response<List<ExpenseResponse>>> listExpenses({
    required String groupId,
  });
}

class GeneratedExpensesOperations implements ExpensesOperations {
  const GeneratedExpensesOperations(this.api);

  final ExpensesApi api;

  @override
  Future<Response<List<ExpenseResponse>>> listExpenses({
    required String groupId,
  }) => api.listExpensesApiV1GroupsGroupIdExpensesGet(groupId: groupId);
}

abstract interface class ExpensesReader {
  Future<List<ExpenseReadModel>> listExpenses(String groupId);
}

class ExpensesRepository implements ExpensesReader {
  ExpensesRepository({required this.operations});

  factory ExpensesRepository.fromTransport(AuthTransport transport) =>
      ExpensesRepository(
        operations: GeneratedExpensesOperations(
          transport.client.getExpensesApi(),
        ),
      );

  final ExpensesOperations operations;

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

  Future<List<ExpenseReadModel>> fetch(String groupId) => listExpenses(groupId);
}

typedef ExpenseReadRepository = ExpensesRepository;
