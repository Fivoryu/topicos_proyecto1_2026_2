import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/openapi.dart';

import 'package:cuentas_claras_mobile/data/repositories/participants_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/presentation/participants/participants_mutation_cubit.dart';

const participant = ParticipantReadModel(
  id: 'p-1',
  groupId: 'g-1',
  name: 'Ana',
  archived: false,
);

void main() {
  test('delegates all commands and trims names', () async {
    final writer = _FakeWriter(participant);
    final cubit = _cubit(writer);
    await cubit.add(' Ana ');
    await cubit.rename('p-1', ' Renamed ');
    await cubit.archive('p-1');
    await cubit.reactivate('p-1');
    await cubit.delete('p-1');

    expect(writer.commands.join(','), 'add,rename,archive,reactivate,delete');
    expect(writer.names.join(','), 'Ana,Renamed');
    expect(writer.ids.join(','), 'p-1,p-1,p-1,p-1');
  });
  test('rejects a blank name without a writer call', () async {
    final writer = _FakeWriter(participant);
    final cubit = _cubit(writer);
    await cubit.rename('p-1', ' \t ');

    expect(writer.commands, isEmpty);
    expect(cubit.state.failure!.kind, MutationFailureKind.validation);
    expect(cubit.state.failure!.fieldErrors['name'], isNotEmpty);
  });
  test('shows loading/disabled and then the server result', () async {
    final writer = _FakeWriter(participant)
      ..pending = Completer<ParticipantReadModel>();
    final cubit = _cubit(writer);
    final request = cubit.add('Ana');
    expect(cubit.state.status, ParticipantsMutationStatus.loading);
    expect(cubit.state.isDisabled, isTrue);
    expect(cubit.state.result, isNull);
    writer.pending!.complete(participant);
    await request;

    expect(cubit.state.status, ParticipantsMutationStatus.success);
    expect(cubit.state.result, same(participant));
  });
  test('keeps loading until post-success refresh completes', () async {
    final refresh = Completer<void>();
    final cubit = ParticipantsMutationCubit(
      writer: _FakeWriter(participant),
      groupId: 'g-1',
      onMutationSuccess: () => refresh.future,
    );
    final request = cubit.add('Ana');

    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, ParticipantsMutationStatus.loading);
    refresh.complete();
    await request;

    expect(cubit.state.status, ParticipantsMutationStatus.success);
    await cubit.close();
  });
  test(
    'maps post-success refresh failures to recovery without success',
    () async {
      final states = <ParticipantsMutationStatus>[];
      final cubit = ParticipantsMutationCubit(
        writer: _FakeWriter(participant),
        groupId: 'g-1',
        onMutationSuccess: () async => throw _dioError(401, null),
      );
      final subscription = cubit.stream.listen(
        (state) => states.add(state.status),
      );

      await cubit.add('Ana');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, ParticipantsMutationStatus.failure);
      expect(cubit.state.failure!.kind, MutationFailureKind.recovery);
      expect(states, [
        ParticipantsMutationStatus.loading,
        ParticipantsMutationStatus.failure,
      ]);
      await subscription.cancel();
      await cubit.close();
    },
  );
  test(
    'exposes a retry capability after post-success refresh failure',
    () async {
      final cubit = ParticipantsMutationCubit(
        writer: _FakeWriter(participant),
        groupId: 'g-1',
        onMutationSuccess: () async => throw StateError('refresh failed'),
        onPostMutationRefreshRetry: () async {},
      );

      await cubit.add('Ana');

      expect(cubit.state.status, ParticipantsMutationStatus.failure);
      expect(cubit.state.result, isNull);
      expect(cubit.canRetryPostMutationRefresh, isTrue);
      await cubit.close();
    },
  );
  test('does not expose retry for an initial writer failure', () async {
    final cubit = ParticipantsMutationCubit(
      writer: _FakeWriter(participant)..error = StateError('write failed'),
      groupId: 'g-1',
      onPostMutationRefreshRetry: () async {},
    );

    await cubit.add('Ana');

    expect(cubit.state.status, ParticipantsMutationStatus.failure);
    expect(cubit.canRetryPostMutationRefresh, isFalse);
    await cubit.close();
  });
  test('retries post-success refresh without a second writer call', () async {
    final writer = _FakeWriter(participant);
    var refreshAttempts = 0;
    final cubit = ParticipantsMutationCubit(
      writer: writer,
      groupId: 'g-1',
      onMutationSuccess: () async => throw StateError('refresh failed'),
      onPostMutationRefreshRetry: () async {
        refreshAttempts++;
      },
    );

    await cubit.add('Ana');
    expect(cubit.state.status, ParticipantsMutationStatus.failure);
    expect(cubit.state.successMessage, isNull);
    await cubit.retryPostMutationRefresh();

    expect(refreshAttempts, 1);
    expect(writer.commands, ['add']);
    expect(cubit.state.status, ParticipantsMutationStatus.success);
    expect(cubit.state.result, same(participant));
    expect(cubit.state.successMessage, 'Participant added.');
    expect(cubit.canRetryPostMutationRefresh, isFalse);
    await cubit.close();
  });
  test('retains a null delete result for a refresh retry', () async {
    final writer = _FakeWriter(participant);
    final cubit = ParticipantsMutationCubit(
      writer: writer,
      groupId: 'g-1',
      onMutationSuccess: () async => throw StateError('refresh failed'),
      onPostMutationRefreshRetry: () async {},
    );

    await cubit.delete('p-1');
    expect(cubit.canRetryPostMutationRefresh, isTrue);
    await cubit.retryPostMutationRefresh();

    expect(writer.commands, ['delete']);
    expect(cubit.state.status, ParticipantsMutationStatus.success);
    expect(cubit.state.result, isNull);
    expect(cubit.state.successMessage, 'Participant deleted.');
    expect(cubit.canRetryPostMutationRefresh, isFalse);
    await cubit.close();
  });
  test('reports deletion completion separately from its null result', () async {
    final cubit = _cubit(_FakeWriter(participant));

    await cubit.delete('p-1');

    expect(cubit.state.status, ParticipantsMutationStatus.success);
    expect(cubit.state.result, isNull);
    expect(cubit.state.successMessage, 'Participant deleted.');
    await cubit.close();
  });
  test('keeps post-success refresh retryable after retry failure', () async {
    final cubit = ParticipantsMutationCubit(
      writer: _FakeWriter(participant),
      groupId: 'g-1',
      onMutationSuccess: () async => throw StateError('refresh failed'),
      onPostMutationRefreshRetry: () async => throw StateError('still down'),
    );

    await cubit.add('Ana');
    await cubit.retryPostMutationRefresh();

    expect(cubit.state.status, ParticipantsMutationStatus.failure);
    expect(cubit.state.failure!.kind, MutationFailureKind.recovery);
    expect(cubit.canRetryPostMutationRefresh, isTrue);
    await cubit.close();
  });
  test(
    'suppresses late post-success refresh retry completion after close',
    () async {
      final retry = Completer<void>();
      final cubit = ParticipantsMutationCubit(
        writer: _FakeWriter(participant),
        groupId: 'g-1',
        onMutationSuccess: () async => throw StateError('refresh failed'),
        onPostMutationRefreshRetry: () => retry.future,
      );

      await cubit.add('Ana');
      final request = cubit.retryPostMutationRefresh();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, ParticipantsMutationStatus.loading);
      await cubit.close();
      retry.complete();
      await request;

      expect(cubit.state.status, ParticipantsMutationStatus.loading);
    },
  );
  test('clears stale post-success retry state for a new mutation', () async {
    var firstRefresh = true;
    final cubit = ParticipantsMutationCubit(
      writer: _FakeWriter(participant),
      groupId: 'g-1',
      onMutationSuccess: () async {
        if (firstRefresh) {
          firstRefresh = false;
          throw StateError('refresh failed');
        }
      },
      onPostMutationRefreshRetry: () async {},
    );

    await cubit.add('Ana');
    expect(cubit.canRetryPostMutationRefresh, isTrue);
    final nextMutation = cubit.add('Bea');
    expect(cubit.canRetryPostMutationRefresh, isFalse);
    await nextMutation;

    expect(cubit.state.status, ParticipantsMutationStatus.success);
    expect(cubit.canRetryPostMutationRefresh, isFalse);
    await cubit.close();
  });
  test('ignores late post-success refresh completion after close', () async {
    final refresh = Completer<void>();
    final cubit = ParticipantsMutationCubit(
      writer: _FakeWriter(participant),
      groupId: 'g-1',
      onMutationSuccess: () => refresh.future,
    );
    final request = cubit.add('Ana');

    await Future<void>.delayed(Duration.zero);
    await cubit.close();
    refresh.complete();
    await request;

    expect(cubit.isClosed, isTrue);
    expect(cubit.state.status, ParticipantsMutationStatus.loading);
  });
  test('ignores duplicate calls while busy', () async {
    final writer = _FakeWriter(participant)
      ..pending = Completer<ParticipantReadModel>();
    final cubit = _cubit(writer);
    final first = cubit.add('Ana');
    await cubit.rename('p-1', 'Other');
    expect(writer.commands, ['add']);
    writer.pending!.complete(participant);
    await first;
  });
  test(
    'maps duplicate participant name to a field validation failure',
    () async {
      final state = await _failureState(
        _dioError(
          409,
          ErrorResponse(
            errorCode: 'duplicate_participant_name',
            message: 'A participant with this name already exists.',
            fieldErrors: [
              FieldError(
                field: 'name',
                message: 'Choose a different participant name.',
              ),
            ],
          ),
        ),
      );

      expect(state.failure!.kind, MutationFailureKind.validation);
      expect(
        state.failure!.message,
        'A participant with this name already exists.',
      );
      expect(
        state.failure!.fieldErrors['name'],
        'Choose a different participant name.',
      );
    },
  );
  test('maps field, authorization, protected, and recovery errors', () async {
    final fieldState = await _failureState(
      _dioError(
        422,
        ErrorResponse(
          errorCode: 'invalid_participant_name',
          message: 'The name is invalid.',
          fieldErrors: [
            FieldError(field: 'name', message: 'Name is already used.'),
          ],
        ),
      ),
    );
    expect(fieldState.failure!.kind, MutationFailureKind.validation);
    expect(fieldState.failure!.fieldErrors['name'], 'Name is already used.');

    await _kind(_dioError(401, null), MutationFailureKind.unauthorized);
    await _kind(_dioError(403, null), MutationFailureKind.forbidden);
    await _kind(
      _dioError(
        409,
        ErrorResponse(
          errorCode: 'participant_in_use',
          message: 'Referenced by history.',
        ),
      ),
      MutationFailureKind.protectedReference,
    );
    await _kind(
      DioException(
        requestOptions: RequestOptions(path: '/participants'),
        type: DioExceptionType.connectionError,
      ),
      MutationFailureKind.recovery,
    );
    await _kind(_dioError(503, null), MutationFailureKind.recovery);
    await _kind(
      ParticipantWriteException('invalid name'),
      MutationFailureKind.validation,
    );
    await _kind(
      _dioError(422, <String, dynamic>{'error_code': 'broken'}),
      MutationFailureKind.corruption,
    );
  });
  test('ignores late success and failure after close', () async {
    final writer = _FakeWriter(participant)
      ..pending = Completer<ParticipantReadModel>();
    final cubit = _cubit(writer);
    final request = cubit.add('Ana');
    await cubit.close();
    writer.pending!.complete(participant);
    await request;

    final failedWriter = _FakeWriter(participant)
      ..pendingError = Completer<void>();
    final failedCubit = _cubit(failedWriter);
    final failedRequest = failedCubit.add('Ana');
    await failedCubit.close();
    failedWriter.pendingError!.completeError(StateError('late'));
    await failedRequest;
  });
}

ParticipantsMutationCubit _cubit(ParticipantsWriter writer) =>
    ParticipantsMutationCubit(writer: writer, groupId: 'g-1');

Future<void> _kind(Object error, MutationFailureKind kind) async {
  expect((await _failureState(error)).failure!.kind, kind);
}

Future<ParticipantsMutationState> _failureState(Object error) async {
  final cubit = _cubit(_FakeWriter(participant)..error = error);
  await cubit.add('Ana');
  final state = cubit.state;
  await cubit.close();
  return state;
}

DioException _dioError(int status, Object? data) => DioException(
  requestOptions: RequestOptions(path: '/participants'),
  response: Response<dynamic>(
    requestOptions: RequestOptions(path: '/participants'),
    statusCode: status,
    data: data,
  ),
);

class _FakeWriter implements ParticipantsWriter {
  _FakeWriter(this.result);

  final ParticipantReadModel result;
  final commands = <String>[];
  final names = <String>[];
  final ids = <String>[];
  Object? error;
  Completer<ParticipantReadModel>? pending;
  Completer<void>? pendingError;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final args = invocation.positionalArguments;
    final command = switch (invocation.memberName) {
      #addParticipant => 'add',
      #renameParticipant => 'rename',
      #archiveParticipant => 'archive',
      #reactivateParticipant => 'reactivate',
      #deleteParticipant => 'delete',
      _ => throw UnimplementedError(),
    };
    commands.add(command);
    if (command != 'add') ids.add(args[1] as String);
    if (command == 'add' || command == 'rename') names.add(args.last as String);
    if (command == 'delete') {
      if (error != null) return Future<void>.error(error!);
      if (pendingError != null) return pendingError!.future;
      return Future<void>.value();
    }
    if (error != null) return Future<ParticipantReadModel>.error(error!);
    if (pendingError != null) return pendingError!.future.then((_) => result);
    if (pending != null) return pending!.future;
    return Future<ParticipantReadModel>.value(result);
  }
}
