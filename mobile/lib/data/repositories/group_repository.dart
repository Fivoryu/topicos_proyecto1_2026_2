import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';

import '../../domain/read_models/read_models.dart';
import '../auth/auth_transport.dart';
import 'repository_support.dart';

abstract interface class GroupOperations {
  Future<Response<GroupResponse>> getGroup({required String groupId});
}

class GeneratedGroupOperations implements GroupOperations {
  const GeneratedGroupOperations(this.api);

  final GroupsApi api;

  @override
  Future<Response<GroupResponse>> getGroup({required String groupId}) =>
      api.getGroupApiV1GroupsGroupIdGet(groupId: groupId);
}

abstract interface class GroupReader {
  Future<GroupReadModel> getGroup(String groupId);
}

class GroupRepository implements GroupReader {
  GroupRepository({required this.operations});

  factory GroupRepository.fromTransport(AuthTransport transport) =>
      GroupRepository(
        operations: GeneratedGroupOperations(transport.client.getGroupsApi()),
      );

  final GroupOperations operations;

  @override
  Future<GroupReadModel> getGroup(String groupId) async {
    try {
      return GroupReadModel.fromDto(
        requireReadData(await operations.getGroup(groupId: groupId), 'group'),
      );
    } on ReadRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw corruptionFailure(error, 'group');
    }
  }

  Future<GroupReadModel> fetch(String groupId) => getGroup(groupId);
}

typedef GroupReadRepository = GroupRepository;
