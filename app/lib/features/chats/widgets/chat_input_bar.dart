import 'dart:math' as math;

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:talkmos/core/utils/emoji_picker_config.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../models/chat_message_model.dart';
import '../message_limits.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isTextEmpty;
  final bool isDark;
  final VoidCallback onSend;
  final VoidCallback onAttachment;
  final VoidCallback camera;
  final ChatMessageModel? replyingToMessage;
  final VoidCallback? onCancelReply;
  final ChatMessageModel? editingMessage;
  final VoidCallback? onCancelEdit;
  final bool isRecording;
  final String recordingDuration;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final VoidCallback? onCancelRecording;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isTextEmpty,
    required this.isDark,
    required this.onSend,
    required this.onAttachment,
    required this.camera,
    this.replyingToMessage,
    this.onCancelReply,
    this.editingMessage,
    this.onCancelEdit,
    this.isRecording = false,
    this.recordingDuration = '0:00',
    this.onStartRecording,
    this.onStopRecording,
    this.onCancelRecording,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _showEmojiPicker = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      setState(() => _showEmojiPicker = true);
    }
  }

  static const double _maxTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final l10n = AppLocalizations.of(context);
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, _maxTextScale);
    final showCamera = widget.isTextEmpty && textScale < 1.15;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxTextScale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Edit preview
          if (widget.editingMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF000814) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.chatInputBarEditMessage,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onCancelEdit,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Reply preview
          if (widget.replyingToMessage != null && widget.editingMessage == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF000814) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          toTitleCase(widget.replyingToMessage!.senderName),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.replyingToMessage!.content,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onCancelReply,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2C34) : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: widget.isRecording
                        ? Row(
                            children: [
                              const SizedBox(width: 16),
                              const _PulsingRedDot(),
                              const SizedBox(width: 12),
                              Text(
                                widget.recordingDuration,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: widget.onCancelRecording,
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                label: Text(
                                  l10n.commonCancel,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _showEmojiPicker
                                      ? Icons.keyboard_rounded
                                      : Icons.emoji_emotions_outlined,
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                                onPressed: _toggleEmojiPicker,
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    ConstrainedBox(
                                      // Grows with the font so the same ~4 lines
                                      // stay reachable before it starts scrolling.
                                      constraints: BoxConstraints(
                                        maxHeight: 120 * textScale,
                                      ),
                                      child: Scrollbar(
                                        child: TextField(
                                          controller: widget.controller,
                                          focusNode: _focusNode,
                                          onTap: () {
                                            if (_showEmojiPicker) {
                                              setState(
                                                () => _showEmojiPicker = false,
                                              );
                                            }
                                          },
                                          minLines: 1,
                                          maxLines: null,
                                          keyboardType: TextInputType.multiline,
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: l10n.chatInputBarHint,
                                            hintMaxLines: 1,
                                            hintStyle: TextStyle(
                                              color: isDark
                                                  ? Colors.white30
                                                  : Colors.grey,
                                            ),
                                            fillColor: isDark
                                                ? const Color(0xFF1F2C34)
                                                : Colors.white,
                                            border: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                          ),
                                          textInputAction:
                                              TextInputAction.newline,
                                          inputFormatters: const [
                                            _MessageLengthFormatter(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    _RemainingCounter(
                                      controller: widget.controller,
                                      isDark: isDark,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.attach_file_rounded,
                                  color: isDark ? Colors.white54 : Colors.grey,
                                ),
                                onPressed: widget.onAttachment,
                              ),
                              ClipRect(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  width: showCamera ? 48.0 : 0.0,
                                  child: AnimatedScale(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    scale: showCamera ? 1.0 : 0.0,
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      curve: Curves.easeInOut,
                                      opacity: showCamera ? 1.0 : 0.0,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.camera_alt_rounded,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.grey,
                                        ),
                                        onPressed: widget.camera,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: widget.isRecording
                      ? widget.onStopRecording
                      : (widget.isTextEmpty
                            ? widget.onStartRecording
                            : widget.onSend),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: widget.isRecording
                        ? Colors.redAccent
                        : Theme.of(context).primaryColor,
                    child: Icon(
                      widget.isRecording
                          ? Icons.send_rounded
                          : (widget.isTextEmpty
                                ? Icons.mic_rounded
                                : (widget.editingMessage != null
                                      ? Icons.check_rounded
                                      : Icons.send_rounded)),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Emoji picker panel
          Offstage(
            offstage: !_showEmojiPicker,
            child: SizedBox(
              height: 280,
              child: EmojiPicker(
                onEmojiSelected: (_, emoji) {
                  widget.controller.text += emoji.emoji;
                  widget.controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: widget.controller.text.length),
                  );
                },
                onBackspacePressed: () {
                  final text = widget.controller.text;
                  if (text.isEmpty) return;
                  widget.controller.text = text.characters
                      .skipLast(1)
                      .toString();
                  widget.controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: widget.controller.text.length),
                  );
                },
                config: buildTalkmosEmojiConfig(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingRedDot extends StatefulWidget {
  const _PulsingRedDot();

  @override
  State<_PulsingRedDot> createState() => _PulsingRedDotState();
}

class _PulsingRedDotState extends State<_PulsingRedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Caps the composer at [maxMessageChars] UTF-16 units — the unit the server's
/// ciphertext budget was sized from. Cuts on a grapheme boundary so an emoji
/// never ends up split in half.
class _MessageLengthFormatter extends TextInputFormatter {
  const _MessageLengthFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length <= maxMessageChars) return newValue;
    if (oldValue.text.length >= maxMessageChars) return oldValue;

    final kept = StringBuffer();
    for (final grapheme in newValue.text.characters) {
      if (kept.length + grapheme.length > maxMessageChars) break;
      kept.write(grapheme);
    }

    final text = kept.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: math.min(newValue.selection.end, text.length),
      ),
    );
  }
}

/// Appears only once the limit is close, so the usual short message keeps a
/// clean composer.
class _RemainingCounter extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;

  const _RemainingCounter({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final remaining = maxMessageChars - value.text.length;
        if (remaining > messageCounterThreshold) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 6),
          child: Text(
            '$remaining',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: remaining <= 0
                  ? Colors.redAccent
                  : (isDark ? Colors.white38 : Colors.black38),
            ),
          ),
        );
      },
    );
  }
}
