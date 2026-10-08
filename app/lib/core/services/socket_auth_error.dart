/// Whether a socket handshake was refused because the server rejected our
/// token, rather than failing for a reason a retry could fix. Matches what
/// the backend's socket auth middleware hands back.
bool isSocketAuthFailure(Object? error) {
  final text = error?.toString().toLowerCase() ?? '';
  return text.contains('authentication') ||
      text.contains('session revoked') ||
      text.contains('not authorized') ||
      text.contains('jwt');
}
