const _maxExpenseCents = 2147483647;

final _expenseAmountPattern = RegExp(r'[0-9]+(?:\.[0-9]{1,2})?');

class InvalidExpenseAmountException extends FormatException {
  InvalidExpenseAmountException(String source) : super(_message, source);

  static const _message =
      'Expense amount must be a positive decimal with one or two fractional '
      'digits and no surrounding whitespace; maximum is 21474836.47.';
}

final class ExpenseAmount {
  ExpenseAmount._(this.text, this.cents);

  factory ExpenseAmount.parse(String text) => parseExpenseAmount(text);

  final String text;
  final int cents;
}

ExpenseAmount parseExpenseAmount(String text) {
  final match = _expenseAmountPattern.firstMatch(text);
  if (match == null || match.group(0) != text) {
    _throwInvalidExpenseAmount(text);
  }

  final separator = text.indexOf('.');
  final wholeEnd = separator == -1 ? text.length : separator;
  var wholeUnits = 0;
  for (var index = 0; index < wholeEnd; index++) {
    final digit = text.codeUnitAt(index) - 48;
    if (wholeUnits > (_maxExpenseCents ~/ 100 - digit) ~/ 10) {
      _throwInvalidExpenseAmount(text);
    }
    wholeUnits = wholeUnits * 10 + digit;
  }

  var cents = wholeUnits * 100;
  if (separator != -1) {
    final fractionLength = text.length - separator - 1;
    final firstDigit = text.codeUnitAt(separator + 1) - 48;
    cents += fractionLength == 1
        ? firstDigit * 10
        : firstDigit * 10 + text.codeUnitAt(separator + 2) - 48;
  }

  if (cents <= 0 || cents > _maxExpenseCents) {
    _throwInvalidExpenseAmount(text);
  }
  return ExpenseAmount._(text, cents);
}

Never _throwInvalidExpenseAmount(String source) =>
    throw InvalidExpenseAmountException(source);

final class ExpenseContributorDraft {
  const ExpenseContributorDraft({
    required this.participantId,
    required this.amount,
  });

  final String participantId;
  final ExpenseAmount amount;
}

final class ExpenseWriteDraft {
  ExpenseWriteDraft({
    required this.description,
    required this.amount,
    required List<ExpenseContributorDraft> contributors,
    required List<String> beneficiaryIds,
  }) : contributors = List.unmodifiable(contributors),
       beneficiaryIds = List.unmodifiable(beneficiaryIds);

  final String description;
  final ExpenseAmount amount;
  final List<ExpenseContributorDraft> contributors;
  final List<String> beneficiaryIds;
}
