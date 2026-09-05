import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';

import '../../domain/read_models/read_models.dart';
import '../auth/auth_transport.dart';
import 'repository_support.dart';

typedef GroupCsrfTokenProvider = Future<String> Function();

abstract interface class GroupOperations {
  Future<Response<GroupResponse>> getGroup({required String groupId});

  Future<Response<GroupResponse>> updateGroup({
    required String groupId,
    required String xCSRFToken,
    required GroupUpdateRequest groupUpdateRequest,
  });
}

class GeneratedGroupOperations implements GroupOperations {
  const GeneratedGroupOperations(this.api);

  final GroupsApi api;

  @override
  Future<Response<GroupResponse>> getGroup({required String groupId}) =>
      api.getGroupApiV1GroupsGroupIdGet(groupId: groupId);

  @override
  Future<Response<GroupResponse>> updateGroup({
    required String groupId,
    required String xCSRFToken,
    required GroupUpdateRequest groupUpdateRequest,
  }) => api.updateGroupApiV1GroupsGroupIdPatch(
    groupId: groupId,
    xCSRFToken: xCSRFToken,
    groupUpdateRequest: groupUpdateRequest,
  );
}

abstract interface class GroupReader {
  Future<GroupReadModel> getGroup(String groupId);
}

/// Writes server-authoritative group settings.
abstract interface class GroupWriter {
  Future<GroupReadModel> updateSettlementPolicy(
    String groupId,
    SettlementPolicy policy,
  );
}

class GroupWriteException implements Exception {
  const GroupWriteException(this.message, {this.isCorruption = false});

  final String message;
  final bool isCorruption;

  @override
  String toString() => message;
}

class GroupRepository implements GroupReader, GroupWriter {
  GroupRepository({required this.operations, this.csrfTokenProvider});

  factory GroupRepository.fromTransport(AuthTransport transport) =>
      GroupRepository(
        operations: GeneratedGroupOperations(transport.client.getGroupsApi()),
        csrfTokenProvider: () =>
            _csrfTokenFromJar(transport.cookieJar, transport.baseUri),
      );

  final GroupOperations operations;
  final GroupCsrfTokenProvider? csrfTokenProvider;

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

  @override
  Future<GroupReadModel> updateSettlementPolicy(
    String groupId,
    SettlementPolicy policy,
  ) async {
    final response = await operations.updateGroup(
      groupId: groupId,
      xCSRFToken: await _csrfToken(),
      groupUpdateRequest: GroupUpdateRequest(
        settlementPolicy: _settlementPolicyRequest(policy),
      ),
    );
    return _readWriteResponse(response, groupId);
  }

  Future<GroupReadModel> fetch(String groupId) => getGroup(groupId);

  Future<String> _csrfToken() async {
    final provider = csrfTokenProvider;
    if (provider == null) {
      throw const GroupWriteException('CSRF token provider is not configured.');
    }
    return provider();
  }
}

GroupUpdateRequestSettlementPolicyEnum _settlementPolicyRequest(
  SettlementPolicy policy,
) => switch (policy) {
  SettlementPolicy.ownerOnly =>
    GroupUpdateRequestSettlementPolicyEnum.ownerOnly,
  SettlementPolicy.anyMember =>
    GroupUpdateRequestSettlementPolicyEnum.anyMember,
};

GroupReadModel _readWriteResponse(
  Response<GroupResponse> response,
  String groupId,
) {
  final data = response.data;
  if (data == null) {
    throw const GroupWriteException(
      'The server returned incomplete group data.',
      isCorruption: true,
    );
  }
  try {
    if (data.id.trim().isEmpty ||
        data.id != groupId ||
        data.name.trim().isEmpty ||
        data.ownerAccountId.trim().isEmpty) {
      throw const FormatException('required group fields are invalid');
    }
    return GroupReadModel.fromDto(data);
  } catch (error) {
    throw GroupWriteException(
      'The server returned corrupted group data: $error',
      isCorruption: true,
    );
  }
}

Future<String> _csrfTokenFromJar(CookieJar cookieJar, Uri baseUri) async {
  final cookies = await cookieJar.loadForRequest(baseUri);
  for (final cookie in cookies) {
    if (cookie.name == csrfCookieName) return cookie.value;
  }
  throw const GroupWriteException(
    'A CSRF token is required for this operation.',
  );
}

typedef GroupReadRepository = GroupRepository;
