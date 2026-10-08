class ContactSearch {
  const ContactSearch._();

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  /// True when [query] matches any of the supplied fields.
  static bool matches({
    required String query,
    required String name,
    String? username,
    String? phone,
    String? email,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    if (name.toLowerCase().contains(q)) return true;
    if ((username ?? '').toLowerCase().contains(q)) return true;
    if ((email ?? '').toLowerCase().contains(q)) return true;

    // Only attempt a phone match once the query actually contains digits,
    // so a name search like "an" doesn't scan numbers pointlessly.
    final queryDigits = _digitsOnly(q);
    if (queryDigits.isEmpty) return false;

    final phoneDigits = _digitsOnly(phone ?? '');
    return phoneDigits.isNotEmpty && phoneDigits.contains(queryDigits);
  }
}
