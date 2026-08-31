import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';

import '../../domain/read_models/read_models.dart';
import '../auth/auth_transport.dart';
import 'repository_support.dart';

abstract interface class SettlementOperations {
  Future<Response<SettlementResponse>> getSettlement({required String groupId});
}

class GeneratedSettlementOperations implements SettlementOperations {
  const GeneratedSettlementOperations(this.api);

  final SettlementApi api;

  @override
  Future<Response<SettlementResponse>> getSettlement({
    required String groupId,
  }) => api.getSettlementApiV1GroupsGroupIdSettlementGet(groupId: groupId);
}

abstract interface class SettlementReader {
  Future<SettlementReadModel> getSettlement(String groupId);
}

class SettlementRepository implements SettlementReader {
  SettlementRepository({required this.operations});

  factory SettlementRepository.fromTransport(AuthTransport transport) =>
      SettlementRepository(
        operations: GeneratedSettlementOperations(
          transport.client.getSettlementApi(),
        ),
      );

  final SettlementOperations operations;

  @override
  Future<SettlementReadModel> getSettlement(String groupId) async {
    try {
      return SettlementReadModel.fromDto(
        requireReadData(
          await operations.getSettlement(groupId: groupId),
          'settlement',
        ),
      );
    } on ReadRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw corruptionFailure(error, 'settlement');
    }
  }

  Future<SettlementReadModel> fetch(String groupId) => getSettlement(groupId);
}

typedef SettlementReadRepository = SettlementRepository;
