import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/openapi.dart';

import 'package:cuentas_claras_mobile/data/repositories/group_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';

Response<T> _response<T>(T? data, {int statusCode = 200}) => Response<T>(
  data: data,
  statusCode: statusCode,
  requestOptions: RequestOptions(path: '/api/v1/groups/group-1'),
);

GroupResponse _group({
  String id = 'group-1',
  String name = 'Trip',
  String ownerAccountId = 'owner-1',
  GroupResponseSettlementPolicyEnum policy =
      GroupResponseSettlementPolicyEnum.ownerOnly,
}) => GroupResponse(
  id: id,
  name: name,
  ownerAccountId: ownerAccountId,
  settlementPolicy: policy,
);

void main() {
  test(
    'updates each supported policy with CSRF and maps the server response',
    () async {
      const cases =
          <(SettlementPolicy, GroupUpdateRequestSettlementPolicyEnum)>[
            (
              SettlementPolicy.ownerOnly,
              GroupUpdateRequestSettlementPolicyEnum.ownerOnly,
            ),
            (
              SettlementPolicy.anyMember,
              GroupUpdateRequestSettlementPolicyEnum.anyMember,
            ),
          ];

      for (final (policy, expectedPolicy) in cases) {
        final operations = _FakeGroupOperations(
          responseData: _group(
            policy: policy == SettlementPolicy.ownerOnly
                ? GroupResponseSettlementPolicyEnum.ownerOnly
                : GroupResponseSettlementPolicyEnum.anyMember,
          ),
        );
        final repository = GroupRepository(
          operations: operations,
          csrfTokenProvider: () async => 'csrf-token',
        );

        final result = await repository.updateSettlementPolicy(
          'group-1',
          policy,
        );

        expect(result.id, 'group-1');
        expect(result.name, 'Trip');
        expect(result.ownerAccountId, 'owner-1');
        expect(result.settlementPolicy, policy);
        expect(operations.updateGroupId, 'group-1');
        expect(operations.updateToken, 'csrf-token');
        expect(operations.updateRequest?.settlementPolicy, expectedPolicy);
      }
    },
  );

  test(
    'fails before the generated operation when CSRF is unavailable',
    () async {
      final operations = _FakeGroupOperations(responseData: _group());
      final repository = GroupRepository(operations: operations);

      await expectLater(
        repository.updateSettlementPolicy(
          'group-1',
          SettlementPolicy.anyMember,
        ),
        throwsA(isA<GroupWriteException>()),
      );
      expect(operations.updateCalls, 0);
    },
  );

  test(
    'maps incomplete and corrupt responses to typed corruption failures',
    () async {
      final incomplete = GroupRepository(
        operations: _FakeGroupOperations(),
        csrfTokenProvider: () async => 'csrf-token',
      );
      await expectLater(
        incomplete.updateSettlementPolicy(
          'group-1',
          SettlementPolicy.ownerOnly,
        ),
        throwsA(
          isA<GroupWriteException>().having(
            (error) => error.isCorruption,
            'isCorruption',
            isTrue,
          ),
        ),
      );

      final corrupt = GroupRepository(
        operations: _FakeGroupOperations(
          responseData: _group(id: 'other-group'),
        ),
        csrfTokenProvider: () async => 'csrf-token',
      );
      await expectLater(
        corrupt.updateSettlementPolicy('group-1', SettlementPolicy.ownerOnly),
        throwsA(
          isA<GroupWriteException>().having(
            (error) => error.isCorruption,
            'isCorruption',
            isTrue,
          ),
        ),
      );
    },
  );

  test(
    'forwards authorization, validation, action, network, and server failures unchanged',
    () async {
      final failures = <DioException>[
        _dioFailure(401, {'error_code': 'signed_out'}),
        _dioFailure(403, {'action': 'owner_required'}),
        _dioFailure(422, {
          'field_errors': {
            'settlementPolicy': ['invalid'],
          },
        }),
        _dioFailure(409, {'action': 'policy_conflict'}),
        DioException(
          requestOptions: RequestOptions(path: '/api/v1/groups/group-1'),
          type: DioExceptionType.connectionError,
        ),
        _dioFailure(503, {'error_code': 'unavailable'}),
      ];

      for (final failure in failures) {
        final repository = GroupRepository(
          operations: _FakeGroupOperations(error: failure),
          csrfTokenProvider: () async => 'csrf-token',
        );

        await expectLater(
          repository.updateSettlementPolicy(
            'group-1',
            SettlementPolicy.anyMember,
          ),
          throwsA(same(failure)),
        );
      }
    },
  );
}

DioException _dioFailure(int status, Object data) {
  final requestOptions = RequestOptions(path: '/api/v1/groups/group-1');
  return DioException(
    requestOptions: requestOptions,
    response: Response<Object>(
      data: data,
      statusCode: status,
      requestOptions: requestOptions,
    ),
  );
}

class _FakeGroupOperations implements GroupOperations {
  _FakeGroupOperations({this.responseData, this.error});

  final GroupResponse? responseData;
  final DioException? error;
  String? updateGroupId;
  String? updateToken;
  GroupUpdateRequest? updateRequest;
  var updateCalls = 0;

  @override
  Future<Response<GroupResponse>> getGroup({required String groupId}) async =>
      _response(_group());

  @override
  Future<Response<GroupResponse>> updateGroup({
    required String groupId,
    required String xCSRFToken,
    required GroupUpdateRequest groupUpdateRequest,
  }) async {
    updateCalls++;
    updateGroupId = groupId;
    updateToken = xCSRFToken;
    updateRequest = groupUpdateRequest;
    if (error != null) throw error!;
    return _response(responseData);
  }
}
