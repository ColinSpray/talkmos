import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/services/http_service.dart';
import '../../../core/services/app_permissions.dart';

/// What the user can do with a phone-book contact.
enum ContactAction {
  /// On Talkmos with a public account — tapping opens a chat straight away.
  chat,

  /// On Talkmos but private, and not yet a friend.
  addFriend,

  /// A friend request is already outstanding.
  requestSent,

  /// Incoming request waiting on the user.
  requestReceived,

  /// Already friends — chatting is fine.
  friends,

  /// Not on Talkmos.
  invite,
}

/// A phone-book entry, optionally resolved to a Talkmos account.
@immutable
class PhoneContact {
  /// Name as it appears in the device's phone book.
  final String displayName;
  final String phone;

  /// Null when this contact has no Talkmos account.
  final String? userId;
  final String? username;
  final String? avatarUrl;
  final bool isPublic;
  final bool isVerified;

  /// `none` | `friends` | `request_sent` | `request_received`
  final String friendship;

  const PhoneContact({
    required this.displayName,
    required this.phone,
    this.userId,
    this.username,
    this.avatarUrl,
    this.isPublic = false,
    this.isVerified = false,
    this.friendship = 'none',
  });

  bool get isOnTalkmos => userId != null;

  ContactAction get action {
    if (!isOnTalkmos) return ContactAction.invite;
    switch (friendship) {
      case 'friends':
        return ContactAction.friends;
      case 'request_sent':
        return ContactAction.requestSent;
      case 'request_received':
        return ContactAction.requestReceived;
      default:
        // A public account is reachable without being friends first; a private
        // one has to be asked.
        return isPublic ? ContactAction.chat : ContactAction.addFriend;
    }
  }

  PhoneContact copyWith({String? friendship}) => PhoneContact(
    displayName: displayName,
    phone: phone,
    userId: userId,
    username: username,
    avatarUrl: avatarUrl,
    isPublic: isPublic,
    isVerified: isVerified,
    friendship: friendship ?? this.friendship,
  );
}

/// Result of loading the phone book, distinguishing "denied" from "empty" so
/// the UI can offer the right next step.
class PhoneContactsResult {
  final List<PhoneContact> contacts;
  final bool permissionDenied;

  const PhoneContactsResult({
    this.contacts = const [],
    this.permissionDenied = false,
  });
}

/// Reads the device phone book and asks the server which numbers belong to
/// Talkmos accounts.
class PhoneContactsService {
  const PhoneContactsService._();

  /// Reads contacts (requesting permission if needed) and resolves them
  /// against Talkmos. Unmatched numbers come back as invitable.
  static Future<PhoneContactsResult> load() async {
    if (!await AppPermissions.ensureContacts()) {
      return const PhoneContactsResult(permissionDenied: true);
    }

    // Only the numbers — photos are fetched lazily, pulling every thumbnail up
    // front is slow on large phone books and we show initials anyway.
    final raw = await FlutterContacts.getAll(
      properties: {ContactProperty.phone},
    );

    // One row per number, de-duplicated — a contact with three numbers should
    // be matchable on any of them.
    final seen = <String>{};
    final entries = <PhoneContact>[];
    for (final c in raw) {
      final name = _sanitizeText(c.displayName ?? '').trim();
      for (final p in c.phones) {
        final number = p.number.trim();
        if (!isDiallableNumber(number)) continue;
        final key = _digits(number);
        if (!seen.add(key)) continue;
        entries.add(
          PhoneContact(
            displayName: name.isEmpty ? number : name,
            phone: number,
          ),
        );
      }
    }
    if (entries.isEmpty) return const PhoneContactsResult();

    final matches = await _match(entries.map((e) => e.phone).toList());
    final bySuffix = {
      for (final m in matches) _suffix(m['phone']?.toString() ?? ''): m,
    };

    final resolved = entries.map((e) {
      final m = bySuffix[_suffix(e.phone)];
      if (m == null) return e;
      return PhoneContact(
        displayName: e.displayName,
        phone: e.phone,
        userId: m['_id']?.toString(),
        username: m['username']?.toString(),
        avatarUrl: m['avatarUrl']?.toString(),
        isPublic: m['isPublic'] == true,
        isVerified: m['isVerified'] == true,
        friendship: m['friendship']?.toString() ?? 'none',
      );
    }).toList();

    // Talkmos users first, then the rest — alphabetical within each group.
    resolved.sort((a, b) {
      if (a.isOnTalkmos != b.isOnTalkmos) return a.isOnTalkmos ? -1 : 1;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return PhoneContactsResult(contacts: resolved);
  }

  static Future<List<Map<String, dynamic>>> _match(List<String> phones) async {
    try {
      final response = await HttpService.post(
        ApiEndpoints.matchContacts,
        body: {'phones': phones},
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && body['success'] == true) {
        return List<Map<String, dynamic>>.from(
          (body['data'] as List).map((e) => Map<String, dynamic>.from(e)),
        );
      }
    } catch (e) {
      // A failed match still leaves a usable screen — every contact simply
      // shows as invitable rather than the list failing to load.
      debugPrint('[PhoneContacts] match failed: $e');
    }
    return const [];
  }

  static const int _minDigits = 10;

  /// E.164 caps a full international number at 15 digits.
  static const int _maxDigits = 15;

  /// India's country calling code.
  static const String _indiaCode = '91';

  static bool isDiallableNumber(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return false;

    // USSD / service codes are dialled, never messaged.
    if (value.contains('*') || value.contains('#')) return false;

    final digits = _digits(value);
    if (digits.length < _minDigits || digits.length > _maxDigits) return false;

    // 0000000000 / 1111111111 and similar placeholders.
    if (digits.split('').toSet().length == 1) return false;

    final national = _indianNationalNumber(value, digits);
    if (national == null) return false;

    // Indian mobile ranges start with 6-9; everything below is a landline.
    return RegExp(r'^[6-9]').hasMatch(national);
  }

  static String? _indianNationalNumber(String value, String digits) {
    // An explicit country code that isn't India's rules the number out.
    if (value.startsWith('+')) {
      if (!digits.startsWith(_indiaCode)) return null;
      final national = digits.substring(_indiaCode.length);
      return national.length == 10 ? national : null;
    }

    if (digits.length == 10) return digits;
    if (digits.length == 11 && digits.startsWith('0')) {
      return digits.substring(1);
    }
    if (digits.length == 12 && digits.startsWith(_indiaCode)) {
      return digits.substring(2);
    }
    return null;
  }

  static String _digits(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  static String _sanitizeText(String value) {
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      final unit = value.codeUnitAt(i);
      final isHighSurrogate = unit >= 0xD800 && unit <= 0xDBFF;
      final isLowSurrogate = unit >= 0xDC00 && unit <= 0xDFFF;
      if (isHighSurrogate) {
        final hasPair =
            i + 1 < value.length &&
            value.codeUnitAt(i + 1) >= 0xDC00 &&
            value.codeUnitAt(i + 1) <= 0xDFFF;
        if (hasPair) {
          buffer.writeCharCode(unit);
          buffer.writeCharCode(value.codeUnitAt(i + 1));
          i++;
        }
      } else if (!isLowSurrogate) {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }

  /// Last 10 digits, mirroring the server's matching rule.
  static String _suffix(String value) {
    final d = _digits(value);
    return d.length > 10 ? d.substring(d.length - 10) : d;
  }
}
