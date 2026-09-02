import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';

import '../../domain/read_models/read_models.dart';
import '../auth/auth_transport.dart';
import 'repository_support.dart';

typedef CsrfTokenProvider = Future<String> Function();

abstract interface class ParticipantsOperations {
  Future<Response<ParticipantResponse>> addParticipant({
    required String groupId,
    required String xCSRFToken,
    required ParticipantWriteRequest participantWriteRequest,
  });

  Future<Response<ParticipantResponse>> archiveParticipant({
    required String groupId,
    required String participantId,
    required String xCSRFToken,
  });

  Future<Response<void>> deleteParticipant({
    required String groupId,
    required String participantId,
    required String xCSRFToken,
  });

  Future<Response<List<ParticipantResponse>>> listParticipants({
    required String groupId,
  });

  Future<Response<ParticipantResponse>> reactivateParticipant({
    required String groupId,
    required String participantId,
    required String xCSRFToken,
  });

  Future<Response<ParticipantResponse>> renameParticipant({
    required String groupId,
    required String participantId,
    required String xCSRFToken,
    required RenameParticipantRequest renameParticipantRequest,
  });
}

class GeneratedParticipantsOperations implements ParticipantsOperations {
  const GeneratedParticipantsOperations(this.api);

  final ParticipantsApi api;

  @override
  Future<Response<ParticipantResponse>> addParticipant({
    required String groupId,
    required String xCSRFToken,
    required ParticipantWriteRequest participantWriteRequest,
  }) => api.addParticipantApiV1GroupsGroupIdParticipantsPost(
    groupId: groupId,
    xCSRFToken: xCSRFToken,
    participantWriteRequest: participantWriteRequest,
  );

  @override
  Future<Response<ParticipantResponse>> archiveParticipant({
    required String groupId,
    required String participantId,
    required String xCSRFToken,
  }) => api
      .archiveParticipantApiV1GroupsGroupIdParticipantsParticipantIdArchivePost(
        groupId: groupId,
        participantId: participantId,
        xCSRFToken: xCSRFToken,
      );

  @override
  Future<Response<void>> deleteParticipant({
    required String groupId,
    required String participantId,
    required String xCSRFToken,
  }) => api.deleteParticipantApiV1GroupsGroupIdParticipantsParticipantIdDelete(
    groupId: groupId,
    participantId: participantId,
    xCSRFToken: xCSRFToken,
  );

  @override
  Future<Response<List<ParticipantResponse>>> listParticipants({
    required String groupId,
  }) => api.listParticipantsApiV1GroupsGroupIdParticipantsGet(groupId: groupId);

  @override
  Future<Response<ParticipantResponse>> reactivateParticipant({
    required String groupId,
    required String participantId,
    required String xCSRFToken,
  }) => api
      .reactivateParticipantApiV1GroupsGroupIdParticipantsParticipantIdReactivatePost(
        groupId: groupId,
        participantId: participantId,
        xCSRFToken: xCSRFToken,
      );

  @override
  Future<Response<ParticipantResponse>> renameParticipant({
    required String groupId,
    required String participantId,
    required String xCSRFToken,
    required RenameParticipantRequest renameParticipantRequest,
  }) => api.renameParticipantApiV1GroupsGroupIdParticipantsParticipantIdPatch(
    groupId: groupId,
    participantId: participantId,
    xCSRFToken: xCSRFToken,
    renameParticipantRequest: renameParticipantRequest,
  );
}

abstract interface class ParticipantsReader {
  Future<List<ParticipantReadModel>> listParticipants(String groupId);
}

class ParticipantWriteException extends StateError {
  ParticipantWriteException(super.message);
}

class ParticipantsRepository implements ParticipantsReader {
  ParticipantsRepository({required this.operations, this.csrfTokenProvider});

  factory ParticipantsRepository.fromTransport(AuthTransport transport) =>
      ParticipantsRepository(
        operations: GeneratedParticipantsOperations(
          transport.client.getParticipantsApi(),
        ),
        csrfTokenProvider: () =>
            _csrfTokenFromJar(transport.cookieJar, transport.baseUri),
      );

  final ParticipantsOperations operations;
  final CsrfTokenProvider? csrfTokenProvider;

  @override
  Future<List<ParticipantReadModel>> listParticipants(String groupId) async {
    try {
      final data = requireReadData(
        await operations.listParticipants(groupId: groupId),
        'participants',
      );
      return List.unmodifiable(data.map(ParticipantReadModel.fromDto));
    } on ReadRepositoryException {
      rethrow;
    } on FormatException catch (error) {
      throw corruptionFailure(error, 'participants');
    }
  }

  Future<ParticipantReadModel> addParticipant(
    String groupId,
    String name,
  ) async {
    final data = requireReadData(
      await operations.addParticipant(
        groupId: groupId,
        xCSRFToken: await _csrfToken(),
        participantWriteRequest: ParticipantWriteRequest(
          name: _trimmedName(name),
        ),
      ),
      'participant',
    );
    return ParticipantReadModel.fromDto(data);
  }

  Future<ParticipantReadModel> renameParticipant(
    String groupId,
    String participantId,
    String name,
  ) async {
    final data = requireReadData(
      await operations.renameParticipant(
        groupId: groupId,
        participantId: participantId,
        xCSRFToken: await _csrfToken(),
        renameParticipantRequest: RenameParticipantRequest(
          name: _trimmedName(name),
        ),
      ),
      'participant',
    );
    return ParticipantReadModel.fromDto(data);
  }

  Future<ParticipantReadModel> archiveParticipant(
    String groupId,
    String participantId,
  ) async {
    final data = requireReadData(
      await operations.archiveParticipant(
        groupId: groupId,
        participantId: participantId,
        xCSRFToken: await _csrfToken(),
      ),
      'participant',
    );
    return ParticipantReadModel.fromDto(data);
  }

  Future<ParticipantReadModel> reactivateParticipant(
    String groupId,
    String participantId,
  ) async {
    final data = requireReadData(
      await operations.reactivateParticipant(
        groupId: groupId,
        participantId: participantId,
        xCSRFToken: await _csrfToken(),
      ),
      'participant',
    );
    return ParticipantReadModel.fromDto(data);
  }

  Future<void> deleteParticipant(String groupId, String participantId) async {
    await operations.deleteParticipant(
      groupId: groupId,
      participantId: participantId,
      xCSRFToken: await _csrfToken(),
    );
  }

  Future<List<ParticipantReadModel>> fetch(String groupId) =>
      listParticipants(groupId);

  Future<String> _csrfToken() async {
    final provider = csrfTokenProvider;
    if (provider == null) {
      throw ParticipantWriteException('CSRF token provider is not configured.');
    }
    return provider();
  }
}

String _trimmedName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    throw ParticipantWriteException('Participant name must not be blank.');
  }
  return trimmed;
}

Future<String> _csrfTokenFromJar(CookieJar cookieJar, Uri baseUri) async {
  final cookies = await cookieJar.loadForRequest(baseUri);
  for (final cookie in cookies) {
    if (cookie.name == csrfCookieName) return cookie.value;
  }
  throw ParticipantWriteException(
    'A CSRF token is required for this operation.',
  );
}

typedef ParticipantsReadRepository = ParticipantsRepository;
