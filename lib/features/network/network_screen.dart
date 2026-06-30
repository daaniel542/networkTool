import 'package:flutter/material.dart';

import '../../shared/utils/clipboard_helper.dart';
import 'dns_service.dart';
import 'network_controller.dart';
import 'ping_service.dart';

const _background = Color(0xFFF8FAFC);
const _surface = Colors.white;
const _primary = Color(0xFF2563EB);
const _text = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _label = Color(0xFF334155);
const _border = Color(0xFFE2E8F0);
const _controlBorder = Color(0xFFCBD5E1);
const _successBg = Color(0xFFDCFCE7);
const _successText = Color(0xFF166534);
const _terminal = Color(0xFF020617);
const _terminalMuted = Color(0xFF94A3B8);
const _terminalText = Color(0xFFE2E8F0);

enum _NetworkMode { ping, dns }

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  late final NetworkController _controller;
  late final TextEditingController _pingHostController;
  late final TextEditingController _dnsDomainController;
  _NetworkMode _mode = _NetworkMode.ping;

  @override
  void initState() {
    super.initState();
    _controller = NetworkController(
      pingService: PingService(),
      dnsService: DnsService(),
    );
    _pingHostController = TextEditingController(text: _controller.pingHost);
    _dnsDomainController = TextEditingController(text: _controller.dnsDomain);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pingHostController.dispose();
    _dnsDomainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return _ToolPage(
          title: 'Network Tools',
          subtitle: 'Run basic internet diagnostics from one simple place.',
          badge: 'Local Tools',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final controls = _ControlsCard(
                controller: _controller,
                mode: _mode,
                pingHostController: _pingHostController,
                dnsDomainController: _dnsDomainController,
                onModeChanged: (mode) => setState(() => _mode = mode),
              );
              final output = _OutputCard(mode: _mode, controller: _controller);

              if (!isWide) {
                return Column(
                  children: [controls, const SizedBox(height: 20), output],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 420, child: controls),
                  const SizedBox(width: 32),
                  Expanded(child: output),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ControlsCard extends StatelessWidget {
  const _ControlsCard({
    required this.controller,
    required this.mode,
    required this.pingHostController,
    required this.dnsDomainController,
    required this.onModeChanged,
  });

  final NetworkController controller;
  final _NetworkMode mode;
  final TextEditingController pingHostController;
  final TextEditingController dnsDomainController;
  final ValueChanged<_NetworkMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final isPing = mode == _NetworkMode.ping;
    final textController = isPing ? pingHostController : dnsDomainController;

    return _Card(
      minHeight: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Network Tools'),
          const SizedBox(height: 6),
          const _BodyText('Check host reachability and resolve DNS records.'),
          const SizedBox(height: 28),
          _SegmentedControl(mode: mode, onChanged: onModeChanged),
          const SizedBox(height: 30),
          _FieldLabel(isPing ? 'Host or IP Address' : 'Domain Name'),
          const SizedBox(height: 8),
          _TextInput(
            controller: textController,
            hintText: 'google.com',
            enabled: !controller.isPinging && !controller.isDnsLoading,
            onChanged: (value) {
              if (isPing) {
                controller.pingHost = value;
              } else {
                controller.dnsDomain = value;
              }
            },
          ),
          const SizedBox(height: 22),
          if (isPing) ...[
            const _FieldLabel('Ping Count'),
            const SizedBox(height: 8),
            _Dropdown<int>(
              width: 160,
              value: controller.pingCount,
              values: const [4, 5, 10, 20],
              labelFor: (value) => value.toString(),
              enabled: !controller.isPinging,
              onChanged: (value) {
                if (value != null) {
                  controller.pingCount = value;
                }
              },
            ),
            const SizedBox(height: 36),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PrimaryButton(
                  label: controller.isPinging ? 'Pinging...' : 'Start Ping',
                  width: 160,
                  isLoading: controller.isPinging,
                  onPressed: controller.isPinging
                      ? null
                      : () {
                          controller.pingHost = pingHostController.text;
                          controller.startPing();
                        },
                ),
                _SecondaryButton(
                  label: 'Stop',
                  width: 112,
                  onPressed: controller.isPinging ? controller.stopPing : null,
                ),
              ],
            ),
          ] else ...[
            const _FieldLabel('Record Type'),
            const SizedBox(height: 8),
            _Dropdown<DnsRecordType>(
              width: 180,
              value: controller.dnsRecordType,
              values: DnsRecordType.values,
              labelFor: (value) => value.name.toUpperCase(),
              enabled: !controller.isDnsLoading,
              onChanged: (value) {
                if (value != null) {
                  controller.dnsRecordType = value;
                }
              },
            ),
            const SizedBox(height: 36),
            _PrimaryButton(
              label: controller.isDnsLoading ? 'Looking up...' : 'Lookup DNS',
              width: 160,
              isLoading: controller.isDnsLoading,
              onPressed: controller.isDnsLoading
                  ? null
                  : () {
                      controller.dnsDomain = dnsDomainController.text;
                      controller.lookupDns();
                    },
            ),
          ],
          const SizedBox(height: 40),
          const _Caption(
            'Ping support is the v1 network diagnostic priority. DNS uses Cloudflare DNS-over-HTTPS.',
          ),
        ],
      ),
    );
  }
}

class _OutputCard extends StatelessWidget {
  const _OutputCard({required this.mode, required this.controller});

  final _NetworkMode mode;
  final NetworkController controller;

  @override
  Widget build(BuildContext context) {
    final lines = mode == _NetworkMode.ping
        ? _pingLines(controller)
        : _dnsLines(controller);
    final outputText = lines.join('\n');

    return _Card(
      minHeight: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Diagnostic Output'),
          const SizedBox(height: 6),
          const _BodyText('Live results stream into a copy-friendly terminal.'),
          const SizedBox(height: 28),
          _Terminal(lines: lines),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _SecondaryButton(
              label: 'Copy Output',
              width: 144,
              onPressed: outputText.isEmpty
                  ? null
                  : () => ClipboardHelper.copyWithFeedback(context, outputText),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _pingLines(NetworkController controller) {
    final lines = <String>[];
    if (controller.pingOutput.isNotEmpty) {
      lines.addAll(controller.pingOutput.expand((line) => line.split('\n')));
    }
    if (controller.pingError != null) {
      lines.add('Error: ${controller.pingError}');
    }
    return lines;
  }

  List<String> _dnsLines(NetworkController controller) {
    if (controller.dnsError != null) {
      return ['Error: ${controller.dnsError}'];
    }
    if (controller.dnsResults.isEmpty) {
      return [];
    }
    return [
      'DNS results:',
      '',
      for (final record in controller.dnsResults)
        '${record.type.padRight(6)} ${record.value}  TTL ${record.ttl}',
    ];
  }
}

class _ToolPage extends StatelessWidget {
  const _ToolPage({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: const BoxDecoration(
              color: _surface,
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(label: badge),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1056),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.minHeight});

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.mode, required this.onChanged});

  final _NetworkMode mode;
  final ValueChanged<_NetworkMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _SegmentButton(
            label: 'Ping',
            selected: mode == _NetworkMode.ping,
            onTap: () => onChanged(_NetworkMode.ping),
          ),
          _SegmentButton(
            label: 'DNS Lookup',
            selected: mode == _NetworkMode.dns,
            onTap: () => onChanged(_NetworkMode.dns),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _primary : _muted,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _Terminal extends StatelessWidget {
  const _Terminal({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 342,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: _terminal,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Live Output',
            style: TextStyle(
              color: _terminalMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                lines.isEmpty
                    ? 'No results yet. Enter input and run the tool.'
                    : lines.join('\n'),
                style: TextStyle(
                  color: lines.isEmpty ? _terminalMuted : _terminalText,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.45,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _muted,
        fontSize: 14,
        height: 1.35,
        letterSpacing: 0,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _label,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _muted,
        fontSize: 13,
        height: 1.35,
        letterSpacing: 0,
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.hintText,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      cursorColor: _primary,
      style: const TextStyle(color: _text, fontSize: 14, letterSpacing: 0),
      decoration: _inputDecoration(hintText: hintText),
    );
  }
}

class _Dropdown<T> extends StatefulWidget {
  const _Dropdown({
    required this.width,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.enabled,
    required this.onChanged,
  });

  final double width;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final bool enabled;
  final ValueChanged<T?> onChanged;

  @override
  State<_Dropdown<T>> createState() => _DropdownState<T>();
}

class _DropdownState<T> extends State<_Dropdown<T>> {
  late T _value = widget.value;

  @override
  void didUpdateWidget(covariant _Dropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: 46,
      child: DropdownButtonFormField<T>(
        initialValue: _value,
        items: widget.values
            .map(
              (value) => DropdownMenuItem<T>(
                value: value,
                child: Text(widget.labelFor(value)),
              ),
            )
            .toList(),
        onChanged: widget.enabled
            ? (value) {
                if (value != null) {
                  setState(() => _value = value);
                }
                widget.onChanged(value);
              }
            : null,
        icon: const Icon(Icons.keyboard_arrow_down, color: _muted, size: 18),
        dropdownColor: _surface,
        style: const TextStyle(color: _text, fontSize: 14, letterSpacing: 0),
        decoration: _inputDecoration(),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _successBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _successText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.width,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 44,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: _primary,
          foregroundColor: _surface,
          disabledBackgroundColor: _primary.withValues(alpha: 0.42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _surface,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    required this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _label,
          disabledForegroundColor: _muted.withValues(alpha: 0.45),
          side: BorderSide(
            color: onPressed == null
                ? _controlBorder.withValues(alpha: 0.55)
                : _controlBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: _muted),
    filled: true,
    fillColor: _surface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _controlBorder),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: _controlBorder.withValues(alpha: 0.55)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _primary),
    ),
  );
}
