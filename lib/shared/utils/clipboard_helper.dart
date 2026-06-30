import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Write-only clipboard helper (PRD §11 — iOS clipboard-guarding).
///
/// All copies are initiated solely by explicit user interaction. Reading from
/// the clipboard is intentionally absent to avoid the iOS paste banner.
abstract final class ClipboardHelper {
  /// Copy [text] to the clipboard and show a success [SnackBar] on [context].
  ///
  /// The SnackBar is only shown when [context] is still mounted. Returns
  /// `true` on success, `false` if the platform call throws.
  static Future<bool> copyWithFeedback(
    BuildContext context,
    String text,
  ) async {
    final success = await _write(text);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
    return success;
  }

  /// Copy [text] to the clipboard silently (no UI feedback).
  static Future<bool> copy(String text) => _write(text);

  static Future<bool> _write(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (_) {
      return false;
    }
  }
}
