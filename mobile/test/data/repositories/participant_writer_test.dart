import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/openapi.dart';

import 'package:cuentas_claras_mobile/data/repositories/participants_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';

Response<T> _response<T>(T? data) => Response<T>(
  data: data,
  statusCode: 200,
  requestOptions: RequestOptions(path: '/api/v1/groups/group-1/participants'),
);

ParticipantResponse _participant({bool archived = false}) =>
    ParticipantResponse(
      id: 'participant-1',
      groupId: 'group-1',
      name: 'Ana',
      archived: archived,
      createdAt: DateTime.utc(2026, 9, 2),
    );

void main() {
  test(
    'adds and renames with trimmed names and server response mapping',
    () async {
      final operations = _FakeParticipantOperations();
      final repository = ParticipantsRepository(
        operations: operations,
        csrfTokenProvider: () async => 'csrf-token',
      );

      final added = await repository.addParticipant('group-1', '  Ana  ');
      final renamed = await repository.renameParticipant(
        'group-1',
        'participant-1',
        '  Ana Renamed  ',
      );

      expect(operations.addRequest?.name, 'Ana');
      expect(operations.renameRequest?.name, 'Ana Renamed');
      expect(operations.addToken, 'csrf-token');
      expect(operations.renameToken, 'csrf-token');
      expect(added, isA<ParticipantReadModel>());
      expect(renamed.name, 'Ana Renamed');
      expect(renamed.id, 'participant-1');
    },
  );

  test('rejects blank names before calling the generated operation', () async {
    final operations = _FakeParticipantOperations();
    final repository = ParticipantsRepository(
      operations: operations,
      csrfTokenProvider: () async => 'csrf-token',
    );

    await expectLater(
      repository.addParticipant('group-1', '   '),
      throwsA(isA<ParticipantWriteException>()),
    );
    await expectLater(
      repository.renameParticipant('group-1', 'participant-1', '\t'),
      throwsA(isA<ParticipantWriteException>()),
    );

    expect(operations.addCalls, 0);
    expect(operations.renameCalls, 0);
  });
}

class _FakeParticipantOperations implements ParticipantsOperations {
  ParticipantWriteRequest? addRequest;
  RenameParticipantRequest? renameRequest;
  String? addToken;
  String? renameToken;
  var addCalls = 0;
  var renameCalls = 0;

  @override
  Future<Response<ParticipantResponse>> addParticipant({
    required String groupId,
    required String xCSRFToken,
    required ParticipantWriteRequest participantWriteRequest,
  }) async {
    addCalls++;
    addRequest = participantWriteRequest;
    addToken = xCSRFToken;
    return _response(_participant());
  }

  @override
  Future<Response<List<ParticipantResponse>>> listParticipants({
    required String groupId,
  }) async => _response(const []);

  @override
  Future<Response<ParticipantResponse>> renameParticipant({
    required String groupId,
    required String participantId,
    required String xCSRFToken,
    required RenameParticipantRequest renameParticipantRequest,
  }) async {
    renameCalls++;
    renameRequest = renameParticipantRequest;
    renameToken = xCSRFToken;
    return _response(
      ParticipantResponse(
        id: 'participant-1',
        groupId: groupId,
        name: renameParticipantRequest.name,
        archived: false,
      ),
    );
  }
}
