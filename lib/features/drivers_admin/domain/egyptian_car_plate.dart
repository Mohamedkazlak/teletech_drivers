/// Egyptian private-vehicle plate: 1–3 traffic letters and 1–4 digits.
///
/// The stored form separates letters with spaces, then the number: "ط ع ب 9295".
abstract final class EgyptianCarPlate {
  static const allowedLetters = 'أبجدرسصطعفقلمنهوي';

  static final RegExp _plate = RegExp(
    '^([$allowedLetters]{1,3})(\\d{1,4})\$',
  );

  static const _alefVariants = {'إ', 'آ', 'ا', 'ٱ'};

  static const _digits = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
    '۰': '0',
    '۱': '1',
    '۲': '2',
    '۳': '3',
    '۴': '4',
    '۵': '5',
    '۶': '6',
    '۷': '7',
    '۸': '8',
    '۹': '9',
  };

  /// Up to three allowed letters, shown with a space between each.
  static String lettersField(String raw) => _collectLetters(raw).join(' ');

  /// Up to four western digits.
  static String numbersField(String raw) {
    final buffer = StringBuffer();
    for (final char in raw.split('')) {
      final mapped = _digits[char] ?? char;
      final code = mapped.codeUnitAt(0);
      if (mapped.length == 1 && code >= 48 && code <= 57) {
        buffer.write(mapped);
        if (buffer.length == 4) break;
      }
    }
    return buffer.toString();
  }

  /// Canonical plate from the two form parts, or null when either part is empty.
  static String? fromParts(String letters, String numbers) {
    final letterList = _collectLetters(letters);
    final number = numbersField(numbers);
    if (letterList.isEmpty || number.isEmpty) return null;
    return '${letterList.join(' ')} $number';
  }

  /// Canonical plate for a stored or pasted value, or null when it is not a plate.
  static String? canonical(String raw) {
    final match = _plate.firstMatch(_compact(raw));
    if (match == null) return null;
    final letters = match.group(1)!;
    final numbers = match.group(2)!;
    return '${letters.split('').join(' ')} $numbers';
  }

  /// Splits a stored plate into the letters field and the numbers field.
  static ({String letters, String numbers})? parts(String raw) {
    final value = canonical(raw);
    if (value == null) return null;
    final pieces = value.split(' ');
    final numbers = pieces.removeLast();
    return (letters: pieces.join(' '), numbers: numbers);
  }

  static List<String> _collectLetters(String raw) {
    final letters = <String>[];
    for (final char in raw.split('')) {
      if (char == '\u0640') continue;
      final normalized = _alefVariants.contains(char) ? 'أ' : char;
      if (!allowedLetters.contains(normalized)) continue;
      letters.add(normalized);
      if (letters.length == 3) break;
    }
    return letters;
  }

  static String _compact(String raw) {
    final buffer = StringBuffer();
    for (final char in raw.split('')) {
      if (char.trim().isEmpty || char == '\u0640') continue;
      if (_alefVariants.contains(char)) {
        buffer.write('أ');
        continue;
      }
      buffer.write(_digits[char] ?? char);
    }
    return buffer.toString();
  }
}
