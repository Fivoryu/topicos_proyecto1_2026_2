import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';

import '../../domain/read_models/read_models.dart';
import '../auth/auth_transport.dart';
import 'repository_support.dart';

abstract interface class BalancesOperations {
  Future<Response<BalancesResponse>> getBalances({required String groupId});
}

class GeneratedBalancesOperations implements BalancesOperations {
  const GeneratedBalancesOperations(this.api);

  final BalancesApi api;

  @override
  Future<Response<BalancesResponse>> getBalances({required String groupId}) =>
      api.getBalancesApiV1GroupsGroupIdBalancesGet(groupId: groupId);
}

abstract interface class BalancesReader {
  Future<BalancesReadModel> getBalances(String groupId);
}

class BalancesRepository implements BalancesReader {
  BalancesRepository({required this.operations});

  factory BalancesRepository.fromTransport(AuthTransport transport) =>
      BalancesRepository(
        operations: GeneratedBalancesOperations(
          transport.client.getBalancesApi(),
        ),
      );

  final BalancesOperations operations;

  @override
  Future<BalancesReadModel> getBalances(String groupId) async {
    try {
      return BalancesReadModel.fromDto(
        requireReadData(
          await operations.getBalances(groupId: groupId),
          'balances',
        ),
      );
    } on ReadRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw corruptionFailure(error, 'balances');
    }
  }

  Future<BalancesReadModel> fetch(String groupId) => getBalances(groupId);
}

typedef BalanceReadRepository = BalancesRepository;
