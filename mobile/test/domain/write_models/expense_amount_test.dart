import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras_mobile/domain/write_models/write_models.dart';

void main() {
  group('ExpenseAmount.parse', () {
    test('preserves accepted lexical text and converts exact cents', () {
      const accepted = {
        '1': 100,
        '1.2': 120,
        '1.20': 120,
        '0001.05': 105,
        '21474836.47': 2147483647,
      };

      for (final entry in accepted.entries) {
        final amount = ExpenseAmount.parse(entry.key);
        expect(amount.text, entry.key);
        expect(amount.cents, entry.value);
      }
    });

    test('rejects values outside the frozen decimal grammar', () {
      const invalid = [
        '',
        ' ',
        ' 1.20 ',
        '\t1.2',
        '1.2\n',
        '+1',
        '-1',
        '1,20',
        '1_20',
        '1e2',
        '.5',
        '1.',
        '1.000',
        '0',
        '0.00',
        '0000',
        '21474836.48',
        '21474837',
      ];

      for (final text in invalid) {
        expect(
          () => ExpenseAmount.parse(text),
          throwsA(isA<InvalidExpenseAmountException>()),
          reason: 'expected rejection for $text',
        );
      }
    });
  });

  test('write drafts copy and expose unmodifiable collections', () {
    final contributors = [
      ExpenseContributorDraft(
        participantId: 'participant-1',
        amount: ExpenseAmount.parse('1.20'),
      ),
    ];
    final beneficiaryIds = ['participant-1'];
    final amount = ExpenseAmount.parse('12.00');
    final draft = ExpenseWriteDraft(
      description: 'Dinner',
      amount: amount,
      contributors: contributors,
      beneficiaryIds: beneficiaryIds,
    );

    contributors.add(
      ExpenseContributorDraft(
        participantId: 'participant-2',
        amount: ExpenseAmount.parse('2'),
      ),
    );
    beneficiaryIds.add('participant-2');

    expect(draft.description, 'Dinner');
    expect(draft.amount, amount);
    expect(draft.contributors, hasLength(1));
    expect(draft.beneficiaryIds, ['participant-1']);
    expect(
      () => draft.beneficiaryIds.add('participant-3'),
      throwsUnsupportedError,
    );
    expect(() => draft.contributors.clear(), throwsUnsupportedError);
  });
}
