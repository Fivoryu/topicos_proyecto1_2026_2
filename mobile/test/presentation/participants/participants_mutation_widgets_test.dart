import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/data/repositories/participants_repository.dart';
import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/presentation/participants/participants_mutation_cubit.dart';
import 'package:cuentas_claras_mobile/presentation/participants/participants_mutation_widgets.dart';

const participant = ParticipantReadModel(
  id: 'p-1',
  groupId: 'g-1',
  name: 'Ana',
  archived: false,
);

void main() {
  testWidgets('forms show labels, trim names, and cancel rename', (
    tester,
  ) async {
    final addWriter = _Writer(), addCubit = _cubit(addWriter);
    await _pump(tester, ParticipantNameForm(cubit: addCubit));
    expect(find.text('Add participant'), findsNWidgets(2));
    expect(find.text('Participant name'), findsOneWidget);
    await tester.enterText(find.byType(TextField), ' Ada ');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add participant'));
    await tester.pump();
    expect(addWriter.names, ['Ada']);

    var cancelled = false;
    final renameWriter = _Writer(), renameCubit = _cubit(renameWriter);
    await _pump(
      tester,
      ParticipantNameForm(
        cubit: renameCubit,
        participant: participant,
        onCancel: () => cancelled = true,
      ),
    );
    expect(find.text('Rename participant'), findsOneWidget);
    await tester.enterText(find.byType(TextField), ' Renamed ');
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(renameWriter.names, ['Renamed']);
    await tester.tap(find.text('Cancel'));
    expect(cancelled, isTrue);
    await addCubit.close();
    await renameCubit.close();
  });

  testWidgets('blank names show an inline live error without a call', (
    tester,
  ) async {
    final writer = _Writer(), cubit = _cubit(writer);
    await _pump(tester, ParticipantNameForm(cubit: cubit));
    await tester.enterText(find.byType(TextField), ' \t ');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add participant'));
    await tester.pump();
    expect(writer.commands, isEmpty);
    expect(find.text('Enter a participant name.'), findsOneWidget);
    final message = find.text('Participant name must not be blank.');
    expect(message, findsOneWidget);
    expect(tester.getSemantics(message).flagsCollection.isLiveRegion, isTrue);
    await cubit.close();
  });

  testWidgets('loading disables form controls and shows a 48dp-safe progress', (
    tester,
  ) async {
    final writer = _Writer()..pending = Completer<void>();
    final cubit = _cubit(writer);
    await _pump(tester, ParticipantNameForm(cubit: cubit));
    final request = cubit.add('Ana');
    await _settle(tester);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.getSize(find.byType(ElevatedButton)).height,
      greaterThanOrEqualTo(48),
    );
    writer.pending!.complete();
    await request;
    await cubit.close();
  });
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
  final names = <String>[];
  Completer<void>? pending;

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
    if (command == 'add') names.add(args[1] as String);
    if (command == 'rename') names.add(args[2] as String);
    if (command == 'delete') return pending?.future ?? Future<void>.value();
    return pending == null
        ? Future<ParticipantReadModel>.value(participant)
        : pending!.future.then((_) => participant);
  }
}
