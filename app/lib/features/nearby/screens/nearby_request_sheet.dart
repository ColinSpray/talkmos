import 'package:flutter/material.dart';
import '../../../models/nearby_user_model.dart';

class NearbyRequestSheet extends StatefulWidget {
  final NearbyUserModel user;

  const NearbyRequestSheet({super.key, required this.user});

  static Future<String?> show(BuildContext context, NearbyUserModel user) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NearbyRequestSheet(user: user),
    );
  }

  @override
  State<NearbyRequestSheet> createState() => _NearbyRequestSheetState();
}

class _NearbyRequestSheetState extends State<NearbyRequestSheet> {
  static const int _maxLength = 200;
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final canSend = _controller.text.trim().isNotEmpty && !_sending;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Say hi to ${widget.user.name}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "You get one message. If they don't reply, you can't send another.",
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? const Color(0xFF8E8E93)
                    : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: _maxLength,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Say hi…',
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1C1C1E)
                    : const Color(0xFFF8FAFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canSend ? _send : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Send request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
