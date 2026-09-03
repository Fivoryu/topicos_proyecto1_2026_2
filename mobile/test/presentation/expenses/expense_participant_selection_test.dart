import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/domain/read_models/read_models.dart';
import 'package:cuentas_claras_mobile/presentation/expenses/expense_participant_selection.dart';

void main() {
  test('selects active participants for a new expense in input order', () {
    final options = selectableExpenseParticipants(
      participants: [
        _participant('a', 'Ana'),
        _participant('archived', 'Former guest', archived: true),
        _participant('b', 'Bruno'),
      ],
    );

    expect(_ids(options), ['a', 'b']);
  });

  test('keeps referenced archived rows and current names on edit', () {
    final options = selectableExpenseParticipants(
      participants: [
        _participant('active', 'Active'),
        _participant('contributor', 'Current contributor', archived: true),
        _participant('beneficiary', 'Current beneficiary', archived: true),
        _participant('unrelated', 'Unrelated', archived: true),
      ],
      existingExpense: _expense(
        contributors: [_contributor('contributor', 'Stale contributor', true)],
        beneficiaries: [_beneficiary('beneficiary', 'Stale beneficiary', true)],
      ),
    );

    expect(_ids(options), ['active', 'contributor', 'beneficiary']);
    expect(options[1].name, 'Current contributor');
  });

  test('reconstructs missing archived references from server metadata', () {
    final options = selectableExpenseParticipants(
      participants: [_participant('active', 'Active')],
      existingExpense: _expense(
        contributors: [
          _contributor('missing-contributor', 'Former contributor', true),
        ],
        beneficiaries: [
          _beneficiary('missing-beneficiary', 'Former beneficiary', true),
        ],
      ),
    );

    expect(_ids(options), [
      'active',
      'missing-contributor',
      'missing-beneficiary',
    ]);
    expect(options[1].name, 'Former contributor');
    expect(options[2].name, 'Former beneficiary');
    expect(options.skip(1).every((option) => option.archived), isTrue);
  });

  test('does not duplicate participant rows or repeated references', () {
    final options = selectableExpenseParticipants(
      participants: [
        _participant('active', 'Active'),
        _participant('active', 'Duplicate active'),
        _participant('archived', 'Archived', archived: true),
        _participant('archived', 'Duplicate archived', archived: true),
      ],
      existingExpense: _expense(
        contributors: [
          _contributor('archived', 'Archived', true),
          _contributor('archived', 'Archived', true),
        ],
        beneficiaries: [_beneficiary('archived', 'Archived', true)],
      ),
    );

    expect(_ids(options), ['active', 'archived']);
  });

  test('does not mutate inputs and returns an unmodifiable list', () {
    final participants = <ParticipantReadModel>[
      _participant('active', 'Active'),
    ];
    final before = List<ParticipantReadModel>.of(participants);
    final options = selectableExpenseParticipants(participants: participants);

    expect(participants, orderedEquals(before));
    expect(
      () => options.add(
        const ExpenseParticipantOption(id: 'new', name: 'New', archived: false),
      ),
      throwsUnsupportedError,
    );
  });
}

List<String> _ids(Iterable<ExpenseParticipantOption> options) =>
    options.map((option) => option.id).toList();

ParticipantReadModel _participant(
  String id,
  String name, {
  bool archived = false,
}) => ParticipantReadModel(
  id: id,
  groupId: 'group-1',
  name: name,
  archived: archived,
);

ExpenseContributorReadModel _contributor(
  String id,
  String name,
  bool archived,
) => ExpenseContributorReadModel(
  participantId: id,
  name: name,
  archived: archived,
  amountCents: 100,
);

ExpenseBeneficiaryReadModel _beneficiary(
  String id,
  String name,
  bool archived,
) => ExpenseBeneficiaryReadModel(
  participantId: id,
  name: name,
  archived: archived,
);

ExpenseReadModel _expense({
  List<ExpenseContributorReadModel> contributors = const [],
  List<ExpenseBeneficiaryReadModel> beneficiaries = const [],
}) => ExpenseReadModel(
  id: 'expense-1',
  groupId: 'group-1',
  description: 'Trip',
  amountCents: 100,
  contributors: contributors,
  beneficiaries: beneficiaries,
);
