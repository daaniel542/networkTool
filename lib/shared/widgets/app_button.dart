import 'package:flutter/material.dart';

/// A reusable elevated button that supports disabled/loading states.
///
/// While [isLoading] is true the button is visually disabled and shows a
/// small [CircularProgressIndicator] in place of the icon. Passing
/// [onPressed] as null renders the button in Flutter's standard disabled style.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? Theme.of(context).colorScheme.primary;

    return ElevatedButton(
      onPressed: (isLoading || onPressed == null) ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: bgColor.withValues(alpha: 0.4),
        disabledForegroundColor: Colors.white54,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white54,
              ),
            )
          else if (icon != null)
            Icon(icon, size: 18),
          if (isLoading || icon != null) const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
