String humanizeError(
  Object error, {
  String fallback = 'Something went wrong.',
}) {
  final raw = error.toString().trim();
  if (raw.isEmpty) return fallback;

  final lower = raw.toLowerCase();
  if (lower.contains('networkexception') ||
      lower.contains('socketexception') ||
      lower.contains('connection error') ||
      lower.contains('failed host lookup')) {
    return 'No internet connection.';
  }

  if (lower.contains('serverexception')) {
    final idx = raw.indexOf(':');
    if (idx >= 0 && idx + 1 < raw.length) {
      final trimmed = raw.substring(idx + 1).trim();
      final statusIdx = trimmed.lastIndexOf('(status:');
      if (statusIdx > 0) {
        return trimmed.substring(0, statusIdx).trim();
      }
      return trimmed;
    }
  }

  if (lower.contains('bad state:')) {
    return raw.replaceFirst(RegExp('bad state:\\s*', caseSensitive: false), '');
  }

  return raw;
}
