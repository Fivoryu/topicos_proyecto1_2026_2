import 'package:dio/dio.dart';
import 'package:openapi/openapi.dart';

import '../../domain/read_models/read_models.dart';
import '../auth/auth_transport.dart';
import 'repository_support.dart';

abstract interface class ParticipantsOperations {
  Future<Response<List<ParticipantResponse>>> listParticipants({
    required String groupId,
  });
}

class GeneratedParticipantsOperations implements ParticipantsOperations {
  const GeneratedParticipantsOperations(this.api);

  final ParticipantsApi api;

  @override
  Future<Response<List<ParticipantResponse>>> listParticipants({
    required String groupId,
  }) => api.listParticipantsApiV1GroupsGroupIdParticipantsGet(groupId: groupId);
}

abstract interface class ParticipantsReader {
  Future<List<ParticipantReadModel>> listParticipants(String groupId);
}

class ParticipantsRepository implements ParticipantsReader {
  ParticipantsRepository({required this.operations});

  factory ParticipantsRepository.fromTransport(AuthTransport transport) =>
      ParticipantsRepository(
        operations: GeneratedParticipantsOperations(
          transport.client.getParticipantsApi(),
        ),
      );

  final ParticipantsOperations operations;

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

  Future<List<ParticipantReadModel>> fetch(String groupId) =>
      listParticipants(groupId);
}

typedef ParticipantsReadRepository = ParticipantsRepository;
