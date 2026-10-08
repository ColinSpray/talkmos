/// Mirrors the server's cap in `chats/messageLimits.js`. Enforced here too so
/// a long message is stopped at the composer instead of coming back as a 400.
const int maxMessageChars = 4096;

/// Where the composer starts showing the remaining count.
const int messageCounterThreshold = 200;
