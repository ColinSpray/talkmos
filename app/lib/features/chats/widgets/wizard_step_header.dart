import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

/// "Step N of M" caption with a segmented progress bar beneath it — one
/// rounded bar per step, lit up through the current step and dim beyond it.
class WizardStepHeader extends StatelessWidget {
  /// Zero-based index of the step being shown.
  final int currentStep;
  final int totalSteps;
  final bool isDark;

  const WizardStepHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final idle = isDark ? const Color(0xFF243044) : const Color(0xFFE3E6EF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(
            context,
          ).wizardStepHeaderStepOf(currentStep + 1, totalSteps),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < totalSteps; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 5,
                  decoration: BoxDecoration(
                    color: i <= currentStep ? primary : idle,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Full-width primary action used at the bottom of each wizard step.
class WizardPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? trailingIcon;
  final bool busy;
  final VoidCallback? onPressed;

  const WizardPrimaryButton({
    super.key,
    required this.label,
    this.trailingIcon = Icons.chevron_right_rounded,
    this.busy = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 6),
                    Icon(trailingIcon, size: 22),
                  ],
                ],
              ),
      ),
    );
  }
}
