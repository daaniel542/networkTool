import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'password_controller.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/output_box.dart';

/// Password Generator screen.
///
/// Uses [Consumer<PasswordController>] to rebuild reactively whenever the
/// controller calls [notifyListeners]. All UI controls map directly to
/// controller setter/toggle methods — no local state needed.
class PasswordScreen extends StatelessWidget {
  const PasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PasswordController>(
      builder: (context, ctrl, _) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ---------------------------------------------------------------
            // Header
            // ---------------------------------------------------------------
            Text(
              'Password Generator',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 24),

            // ---------------------------------------------------------------
            // Length slider
            // ---------------------------------------------------------------
            _SectionLabel('Length: ${ctrl.length}'),
            Slider(
              value: ctrl.length.toDouble(),
              min: 4,
              max: 128,
              divisions: 124,
              label: ctrl.length.toString(),
              onChanged: (v) => ctrl.setLength(v.round()),
            ),
            const SizedBox(height: 16),

            // ---------------------------------------------------------------
            // Character type toggles
            // ---------------------------------------------------------------
            _SectionLabel('Character Types'),
            const SizedBox(height: 4),
            _ToggleRow(
              label: 'Uppercase (A-Z)',
              value: ctrl.useUppercase,
              onChanged: ctrl.toggleUppercase,
            ),
            _ToggleRow(
              label: 'Lowercase (a-z)',
              value: ctrl.useLowercase,
              onChanged: ctrl.toggleLowercase,
            ),
            _ToggleRow(
              label: 'Digits (0-9)',
              value: ctrl.useDigits,
              onChanged: ctrl.toggleDigits,
            ),
            _ToggleRow(
              label: 'Symbols (!@#\$%…)',
              value: ctrl.useSymbols,
              onChanged: ctrl.toggleSymbols,
            ),
            const SizedBox(height: 16),

            // ---------------------------------------------------------------
            // Excluded characters field
            // ---------------------------------------------------------------
            _SectionLabel('Excluded Characters'),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: ctrl.excludedChars),
              decoration: const InputDecoration(
                hintText: 'e.g.  l I O 0',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              onChanged: ctrl.setExcludedChars,
            ),
            const SizedBox(height: 24),

            // ---------------------------------------------------------------
            // Generate button
            // ---------------------------------------------------------------
            AppButton(
              label: 'Generate Password',
              icon: Icons.refresh,
              onPressed: ctrl.generate,
            ),
            const SizedBox(height: 20),

            // ---------------------------------------------------------------
            // Error display
            // ---------------------------------------------------------------
            if (ctrl.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ctrl.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ---------------------------------------------------------------
            // Output
            // ---------------------------------------------------------------
            if (ctrl.generatedPassword.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionLabel('Generated Password'),
              const SizedBox(height: 8),
              OutputBox(text: ctrl.generatedPassword),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Small private helper widgets
// ---------------------------------------------------------------------------

/// A thin label used to title each settings section.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
    );
  }
}

/// A row with a label on the left and a [Switch] on the right.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
