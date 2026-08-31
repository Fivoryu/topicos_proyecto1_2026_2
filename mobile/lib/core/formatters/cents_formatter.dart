/// Format server-provided integer cents without floating-point arithmetic.
String formatCents(int cents) {
  final negative = cents < 0;
  final magnitude = negative ? -cents : cents;
  final whole = magnitude ~/ 100;
  final fraction = magnitude % 100;
  final wholeText = _groupThousands(whole.toString());
  final fractionText = fraction.toString().padLeft(2, '0');
  final sign = negative && magnitude != 0 ? '-' : '';

  return '${sign}Bs. $wholeText.$fractionText';
}

String _groupThousands(String digits) {
  final groups = <String>[];
  for (var end = digits.length; end > 0;) {
    final start = end > 3 ? end - 3 : 0;
    groups.add(digits.substring(start, end));
    end = start;
  }
  return groups.reversed.join(',');
}

String formatBolivianos(int cents) => formatCents(cents);
