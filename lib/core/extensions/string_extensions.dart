/// Helpful string manipulation extensions for student names, headers, and labels.
extension StringExtensions on String {
  /// Returns the capitalized version of the string (first letter uppercase).
  String get capitalizeFirst {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Returns up to 2 uppercase initials from a name (e.g. "Naitik Patil" -> "NP").
  String get initials {
    final trimmed = trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
      final second = parts[1].isNotEmpty ? parts[1][0].toUpperCase() : '';
      return '$first$second';
    }
    return trimmed[0].toUpperCase();
  }
}
