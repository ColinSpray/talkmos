String toTitleCase(String name) {
  return name
      .trim()
      .split(RegExp(r'\s+')) // handles multiple/irregular spaces
      .where((word) => word.isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}
