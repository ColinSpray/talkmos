String callTitleFor(Iterable<String> remoteNames, {String? fallback}) {
  final names =
      remoteNames.map((n) => n.trim()).where((n) => n.isNotEmpty).toList()
        // Sorted so the title doesn't reshuffle on every rebuild — LiveKit's
        // participant map has no meaningful order.
        ..sort();

  if (names.isEmpty) return fallback?.trim() ?? '';
  return names.join(', ');
}
