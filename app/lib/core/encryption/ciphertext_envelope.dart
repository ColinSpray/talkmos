/// The key id carried alongside a ciphertext.
///
/// Without it a rotation is a data loss event: every message already on disk
/// was written under the old key, and nothing in `nonce:mac:cipher` says
/// which one. The id is a prefix rather than a new field so it travels
/// through the wire format, the sqlite column and the offline queue without
/// any of them needing to know about it.
///
/// `k<id>.nonce:mac:cipher` — anything without the prefix predates this and is
/// read with the legacy key.
class CiphertextEnvelope {
  final int keyId;
  final String payload;

  const CiphertextEnvelope({required this.keyId, required this.payload});

  static const int legacyKeyId = 0;
  static const String _separator = '.';

  static final RegExp _prefix = RegExp(r'^k(\d+)\.');

  static String wrap({required int keyId, required String payload}) {
    if (keyId == legacyKeyId) return payload;
    return 'k$keyId$_separator$payload';
  }

  /// Splits a stored value. An unprefixed value is legacy, not corrupt.
  static CiphertextEnvelope parse(String stored) {
    final match = _prefix.firstMatch(stored);
    if (match == null) {
      return CiphertextEnvelope(keyId: legacyKeyId, payload: stored);
    }
    return CiphertextEnvelope(
      keyId: int.parse(match.group(1)!),
      payload: stored.substring(match.end),
    );
  }
}
