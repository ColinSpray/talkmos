import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  List<Map<String, String>> _faqs(AppLocalizations l10n) => [
    {
      'question': l10n.helpSupportScreenFaq1Question,
      'answer': l10n.helpSupportScreenFaq1Answer,
    },
    {
      'question': l10n.helpSupportScreenFaq2Question,
      'answer': l10n.helpSupportScreenFaq2Answer,
    },
    {
      'question': l10n.helpSupportScreenFaq3Question,
      'answer': l10n.helpSupportScreenFaq3Answer,
    },
    {
      'question': l10n.helpSupportScreenFaq4Question,
      'answer': l10n.helpSupportScreenFaq4Answer,
    },
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitSupportTicket() {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);

    setState(() {
      _isSubmitting = true;
    });

    // Simulate network latency
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      _subjectController.clear();
      _messageController.clear();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.greenAccent,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.helpSupportScreenTicketSubmittedTitle)),
            ],
          ),
          content: Text(
            l10n.helpSupportScreenTicketSubmittedBody,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.commonClose,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surface = isDark ? AppTheme.darkBg : const Color(0xFFFAF9FF);
    final cardBgColor = isDark ? AppTheme.darkCard : Colors.white;
    final cardBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFFE3E3EF);
    final titleColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final bodyTextColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final faqs = _faqs(l10n);

    BoxDecoration cardDecoration() => BoxDecoration(
      color: cardBgColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: cardBorderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );

    Widget sectionHeading(IconData icon, String text) => Row(
      children: [
        Icon(icon, size: 18, color: theme.primaryColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.helpSupportScreenTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FAQs Heading
              sectionHeading(
                Icons.help_outline_rounded,
                l10n.helpSupportScreenFaqHeading,
              ),
              const SizedBox(height: 12),

              // FAQs List
              Container(
                decoration: cardDecoration(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: faqs.map((faq) {
                        final index = faqs.indexOf(faq);
                        final isLast = index == faqs.length - 1;
                        return Column(
                          children: [
                            ExpansionTile(
                              title: Text(
                                faq['question'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                ),
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                16,
                              ),
                              expandedAlignment: Alignment.topLeft,
                              collapsedIconColor: bodyTextColor,
                              iconColor: theme.primaryColor,
                              children: [
                                Text(
                                  faq['answer'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: bodyTextColor,
                                  ),
                                ),
                              ],
                            ),
                            if (!isLast)
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Divider(
                                  height: 1,
                                  color: cardBorderColor,
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Support Form Heading
              sectionHeading(
                Icons.edit_note_rounded,
                l10n.helpSupportScreenSubmitTicketHeading,
              ),
              const SizedBox(height: 12),

              // Contact Form Card
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: cardDecoration(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Subject Field
                      TextFormField(
                        controller: _subjectController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.helpSupportScreenSubjectLabel,
                          hintText: l10n.helpSupportScreenSubjectHint,
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkBg
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.helpSupportScreenSubjectRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description Field
                      TextFormField(
                        controller: _messageController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: l10n.helpSupportScreenDescriptionLabel,
                          hintText: l10n.helpSupportScreenDescriptionHint,
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkBg
                              : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.helpSupportScreenDescriptionRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitSupportTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.helpSupportScreenSubmitButton,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
