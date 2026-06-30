import 'package:flutter/material.dart';
import '../utils/clipboard_helper.dart';

/// A styled, selectable text container for displaying operation results.
///
/// Shows [text] in a monospaced font inside a bordered container. When text
/// is present a copy button appears; it delegates to [ClipboardHelper] so
/// the SnackBar feedback is shown automatically.
class OutputBox extends StatelessWidget {
  const OutputBox({
    super.key,
    required this.text,
    this.placeholder = 'Output will appear here…',
  });

  final String text;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = text.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SelectableText(
              isEmpty ? placeholder : text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
                color: isEmpty
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (!isEmpty)
            IconButton(
              tooltip: 'Copy to clipboard',
              icon: const Icon(Icons.copy_outlined, size: 18),
              onPressed: () => ClipboardHelper.copyWithFeedback(context, text),
            ),
        ],
      ),
    );
  }
}
