const int maxRecordMinor = 999999999999;
final BigInt _maxInt64 = (BigInt.one << 63) - BigInt.one;
final BigInt _minInt64 = -(BigInt.one << 63);

/// Parses a decimal amount without ever passing through a binary float.
int parseMoneyMinor(String input, {bool allowZero = true}) {
  final value = input.trim();
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) {
    throw const FormatException(
      'Use a nonnegative amount with at most 2 decimals.',
    );
  }
  final parts = value.split('.');
  final minor =
      BigInt.parse(parts.first) * BigInt.from(100) +
      BigInt.parse(parts.length == 1 ? '0' : parts[1].padRight(2, '0'));
  if (minor > BigInt.from(maxRecordMinor) ||
      (!allowZero && minor == BigInt.zero)) {
    throw const FormatException('Amount is outside the allowed range.');
  }
  return minor.toInt();
}

int checkedSumMinor(Iterable<int> amounts) {
  var result = BigInt.zero;
  for (final amount in amounts) {
    result += BigInt.from(amount);
  }
  if (result < _minInt64 || result > _maxInt64) {
    throw RangeError(
      'The total cannot be represented as a signed 64-bit integer.',
    );
  }
  return result.toInt();
}

String formatMoneyMinor(int amount, {bool grouped = true}) {
  final absolute = BigInt.from(amount).abs();
  var whole = (absolute ~/ BigInt.from(100)).toString();
  if (grouped) {
    whole = whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  }
  final fraction = (absolute % BigInt.from(100)).toString().padLeft(2, '0');
  return '${amount < 0 ? '-' : ''}$whole.$fraction';
}
