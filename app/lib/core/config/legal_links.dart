import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public-facing legal documents. Kept in one place so the sign-up screen and
/// the privacy settings screen can't drift apart.
class LegalLinks {
  const LegalLinks._();

  static final Uri terms = Uri.parse('https://talkmos.com/terms');
  static final Uri privacyPolicy = Uri.parse('https://talkmos.com/privacy');

  static Future<bool> open(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[LegalLinks] failed to open $url: $e');
      return false;
    }
  }
}
