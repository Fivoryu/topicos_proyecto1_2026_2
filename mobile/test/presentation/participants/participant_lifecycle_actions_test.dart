import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/data/repositories/participants_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/presentation/participants/participant_lifecycle_actions.dart';
import 'package:cuentas_claras_mobile/presentation/participants/participants_mutation_cubit.dart';

const participant = ParticipantReadModel(
  id: 'p-1',
  groupId: 'g-1',
  name: 'Ana',
  archived: false,
);

void main() {
  testWidgets('archive and reactivate follow the archived flag', (
    tester,
  ) async {
    await _action(tester, participant, 'Archive', 'archive');
    await _action(
      tester,
      const ParticipantReadModel(
        id: 'p-1',
        groupId: 'g-1',
        name: 'Ana',
        archived: true,
      ),
      'Reactivate',
      'reactivate',
    );
  });

  testWidgets('delete cancel, barrier, and back never call the writer', (
    tester,
  ) async {
    final dismissals = <Future<void> Function(WidgetTester)>[
      (t) async => t.tap(find.text('Cancel')),
      (t) async => t.tapAt(const Offset(1, 1)),
      (t) async => t.binding.handlePopRoute(),
    ];
    for (final dismiss in dismissals) {
      await _dismiss(tester, dismiss);
    }
  });

  testWidgets('confirmed delete runs once and disables 48dp-safe actions', (
    tester,
  ) async {
    final writer = _Writer()..pending = Completer<void>();
    final cubit = _cubit(writer);
    await _pump(
      tester,
      ParticipantLifecycleActions(cubit: cubit, participant: participant),
    );
    await tester.tap(find.text('Delete'));
    await tester.pump();
    await tester.tap(find.text('Delete').last);
    await tester.pump();
    expect(writer.commands, ['delete']);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byType(OutlinedButton).first)
          .onPressed,
      isNull,
    );
    expect(
      tester.getSize(find.byType(OutlinedButton).last).height,
      greaterThanOrEqualTo(48),
    );
    writer.pending!.complete();
    await cubit.close();
  });

  testWidgets('protected and recovery failures are visible live messages', (
    tester,
  ) async {
    final cubit = _cubit(_Writer());
    await _pump(
      tester,
      ParticipantLifecycleActions(cubit: cubit, participant: participant),
    );
    cubit.emit(
      ParticipantsMutationState.failure(
        MutationFailure(
          kind: MutationFailureKind.protectedReference,
          message: 'This participant is protected by historical references.',
        ),
      ),
    );
    await _settle(tester);
    final protected = find.textContaining('protected by historical');
    expect(protected, findsOneWidget);
    expect(tester.getSemantics(protected).flagsCollection.isLiveRegion, isTrue);
    cubit.emit(
      ParticipantsMutationState.failure(
        MutationFailure(
          kind: MutationFailureKind.recovery,
          message: 'Please try again.',
        ),
      ),
    );
    await _settle(tester);
    expect(find.text('Please try again.'), findsOneWidget);
    await cubit.close();
  });
}

Future<void> _action(
  WidgetTester tester,
  ParticipantReadModel model,
  String label,
  String command,
) async {
  final writer = _Writer(), cubit = _cubit(writer);
  await _pump(
    tester,
    ParticipantLifecycleActions(cubit: cubit, participant: model),
  );
  await tester.tap(find.text(label));
  await tester.pump();
  expect(writer.commands, [command]);
  await cubit.close();
}

Future<void> _dismiss(
  WidgetTester tester,
  Future<void> Function(WidgetTester) dismiss,
) async {
  final writer = _Writer(), cubit = _cubit(writer);
  await _pump(
    tester,
    ParticipantLifecycleActions(cubit: cubit, participant: participant),
  );
  await tester.tap(find.text('Delete'));
  await tester.pump();
  await dismiss(tester);
  await tester.pump();
  expect(writer.commands, isEmpty);
  await cubit.close();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

ParticipantsMutationCubit _cubit(ParticipantsWriter writer) =>
    ParticipantsMutationCubit(writer: writer, groupId: 'g-1');

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pump();
}

class _Writer implements ParticipantsWriter {
  final commands = <String>[];
  Completer<void>? pending;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final command = switch (invocation.memberName) {
      #addParticipant => 'add',
      #renameParticipant => 'rename',
      #archiveParticipant => 'archive',
      #reactivateParticipant => 'reactivate',
      #deleteParticipant => 'delete',
      _ => throw UnimplementedError(),
    };
    commands.add(command);
    if (command == 'delete') return pending?.future ?? Future<void>.value();
    return pending == null
        ? Future<ParticipantReadModel>.value(participant)
        : pending!.future.then((_) => participant);
  }
}
