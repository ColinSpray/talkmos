import 'package:flutter/material.dart';
import '../../../models/chat_message_model.dart';

class WhatsAppWallpaperPainter extends CustomPainter {
  final Color color;

  const WhatsAppWallpaperPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const int stepX = 100;
    const int stepY = 120;

    for (double x = 40; x < size.width; x += stepX) {
      for (double y = 40; y < size.height; y += stepY) {
        final int type = ((x / stepX).floor() + (y / stepY).floor()) % 4;

        switch (type) {
          case 0:
            // Smiley
            canvas.drawCircle(Offset(x, y), 8, paint);
            canvas.drawArc(
              Rect.fromCircle(center: Offset(x, y + 1), radius: 4),
              0,
              3.14,
              false,
              paint,
            );
          case 1:
            // Heart
            final path = Path()
              ..moveTo(x, y - 5)
              ..cubicTo(x - 6, y - 11, x - 12, y - 5, x, y + 5)
              ..cubicTo(x + 12, y - 5, x + 6, y - 11, x, y - 5);
            canvas.drawPath(path, paint);
          case 2:
            // Sparkle
            canvas.drawLine(Offset(x, y - 6), Offset(x, y + 6), paint);
            canvas.drawLine(Offset(x - 6, y), Offset(x + 6, y), paint);
          case 3:
            // Chat bubble doodle
            canvas.drawRRect(
              RRect.fromRectXY(
                Rect.fromCenter(center: Offset(x, y), width: 14, height: 10),
                3,
                3,
              ),
              paint,
            );
            canvas.drawLine(Offset(x - 3, y + 5), Offset(x - 6, y + 8), paint);
            canvas.drawLine(Offset(x - 6, y + 8), Offset(x - 1, y + 5), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant WhatsAppWallpaperPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Flat list entry used by the chat message list builder to interleave date
/// separators and message bubbles without requiring two separate lists.
class ChatListEntry {
  final DateTime? date;
  final ChatMessageModel? message;

  const ChatListEntry.date(DateTime this.date) : message = null;
  const ChatListEntry.message(ChatMessageModel this.message) : date = null;
}

/// The chat's rows, newest first — the order a reversed ListView wants, where
/// index 0 sits at the bottom. Each day's separator lands just above that
/// day's first message once the list flips it back.
List<ChatListEntry> buildChatListEntries(List<ChatMessageModel> messages) {
  final items = <ChatListEntry>[];
  DateTime? lastDay;
  for (final m in messages) {
    final day = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
    if (lastDay == null || day != lastDay) {
      items.add(ChatListEntry.date(day));
      lastDay = day;
    }
    items.add(ChatListEntry.message(m));
  }
  return items.reversed.toList();
}
