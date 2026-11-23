class MoneyFormatter {
  static String format(int kopecks) {
    return '${(kopecks / 100).toStringAsFixed(2)} грн';
  }

  static String formatShort(int kopecks) {
    return '${(kopecks / 100).toStringAsFixed(0)} грн';
  }

  static int parseToKopecks(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized) ?? 0.0;
    return (parsed * 100).round();
  }
}