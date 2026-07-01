import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../shared/utils/clipboard_helper.dart';
import '../../shared/widgets/terminal_output.dart';
import 'dns_service.dart';
import 'network_controller.dart';

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

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  final TextEditingController _pingHostController = TextEditingController();
  final TextEditingController _dnsDomainController = TextEditingController();
  final TextEditingController _traceHostController = TextEditingController();
  NetworkController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<NetworkController>();
    if (_controller == controller) return;

    _controller = controller;
    _pingHostController.text = controller.pingHost;
    _dnsDomainController.text = controller.dnsDomain;
    _traceHostController.text = controller.traceHost;
  }

  @override
  void dispose() {
    _pingHostController.dispose();
    _dnsDomainController.dispose();
    _traceHostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NetworkController>();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return _ToolPage(
          title: 'Network Tools',
          subtitle: 'Run basic internet diagnostics from one simple place.',
          badge: 'Local Tools',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final controls = _ControlsCard(
                controller: controller,
                pingHostController: _pingHostController,
                dnsDomainController: _dnsDomainController,
                traceHostController: _traceHostController,
              );
              final output = _OutputCard(controller: controller);

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
    required this.pingHostController,
    required this.dnsDomainController,
    required this.traceHostController,
  });

  final NetworkController controller;
  final TextEditingController pingHostController;
  final TextEditingController dnsDomainController;
  final TextEditingController traceHostController;

  @override
  Widget build(BuildContext context) {
    final isPing = controller.activeMode == NetworkToolMode.ping;
    final isDns = controller.activeMode == NetworkToolMode.dns;
    final isTrace = controller.activeMode == NetworkToolMode.trace;
    final textController = isPing
        ? pingHostController
        : isDns
        ? dnsDomainController
        : traceHostController;

    return _Card(
      minHeight: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Network Tools'),
          const SizedBox(height: 6),
          const _BodyText('Check host reachability and resolve DNS records.'),
          const SizedBox(height: 28),
          _SegmentedControl(
            mode: controller.activeMode,
            onChanged: controller.setActiveMode,
          ),
          const SizedBox(height: 30),
          _FieldLabel(isDns ? 'Domain Name' : 'Host or IP Address'),
          const SizedBox(height: 8),
          _TextInput(
            controller: textController,
            hintText: 'google.com',
            enabled: !controller.isBusy,
            onChanged: (value) {
              if (isPing) {
                controller.setPingHost(value);
              } else if (isDns) {
                controller.setDnsDomain(value);
              } else {
                controller.setTraceHost(value);
              }
            },
          ),
          const SizedBox(height: 22),
          if (isPing) ...[
            const _FieldLabel('Ping Count'),
            const SizedBox(height: 8),
            _PingCountInput(
              value: controller.pingCount,
              enabled: !controller.isPinging,
              onChanged: controller.setPingCount,
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
                          controller.setPingHost(pingHostController.text);
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
          ] else if (isDns) ...[
            const _FieldLabel('Record Type'),
            const SizedBox(height: 8),
            _DnsRecordSelector(
              value: controller.dnsRecordType,
              enabled: !controller.isDnsLoading,
              onChanged: controller.setDnsRecordType,
            ),
            const SizedBox(height: 36),
            _PrimaryButton(
              label: controller.isDnsLoading ? 'Looking up...' : 'Lookup DNS',
              width: 160,
              isLoading: controller.isDnsLoading,
              onPressed: controller.isDnsLoading
                  ? null
                  : () {
                      controller.setDnsDomain(dnsDomainController.text);
                      controller.lookupDns();
                    },
            ),
          ] else if (isTrace) ...[
            const _BodyText(
              'Trace the route by probing each hop with increasing TTL values.',
            ),
            const SizedBox(height: 36),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _PrimaryButton(
                  label: controller.isTracing ? 'Tracing...' : 'Start Trace',
                  width: 160,
                  isLoading: controller.isTracing,
                  onPressed: controller.isTracing
                      ? null
                      : () {
                          controller.setTraceHost(traceHostController.text);
                          controller.startTraceroute(traceHostController.text);
                        },
                ),
                _SecondaryButton(
                  label: 'Stop',
                  width: 112,
                  onPressed: controller.isTracing
                      ? () => controller.stopTraceroute()
                      : null,
                ),
              ],
            ),
          ],
          const SizedBox(height: 40),
          const _Caption(
            'Ping and Trace use local ICMP probes. DNS uses Cloudflare DNS-over-HTTPS.',
          ),
        ],
      ),
    );
  }
}

class _OutputCard extends StatelessWidget {
  const _OutputCard({required this.controller});

  final NetworkController controller;

  @override
  Widget build(BuildContext context) {
    final lines = controller.activeOutputLines;
    final outputText = controller.activeOutputText;

    return _Card(
      minHeight: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle('Diagnostic Output'),
          const SizedBox(height: 6),
          const _BodyText('Live results stream into a copy-friendly terminal.'),
          const SizedBox(height: 28),
          TerminalOutput(lines: lines, minHeight: 342),
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

  final NetworkToolMode mode;
  final ValueChanged<NetworkToolMode> onChanged;

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
            selected: mode == NetworkToolMode.ping,
            onTap: () => onChanged(NetworkToolMode.ping),
          ),
          _SegmentButton(
            label: 'DNS',
            selected: mode == NetworkToolMode.dns,
            onTap: () => onChanged(NetworkToolMode.dns),
          ),
          _SegmentButton(
            label: 'Trace',
            selected: mode == NetworkToolMode.trace,
            onTap: () => onChanged(NetworkToolMode.trace),
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

class _PingCountInput extends StatefulWidget {
  const _PingCountInput({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final int value;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  State<_PingCountInput> createState() => _PingCountInputState();
}

class _PingCountInputState extends State<_PingCountInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _PingCountInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      _setText(widget.value.toString());
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _commit();
    }
  }

  void _step(int delta) {
    if (!widget.enabled) return;
    final next = (widget.value + delta).clamp(1, 20);
    widget.onChanged(next);
    _setText(next.toString());
  }

  void _handleChanged(String rawValue) {
    final value = int.tryParse(rawValue);
    if (value == null) return;
    widget.onChanged(value.clamp(1, 20));
  }

  void _commit() {
    final value = int.tryParse(_controller.text);
    final normalized = (value ?? widget.value).clamp(1, 20);
    widget.onChanged(normalized);
    _setText(normalized.toString());
  }

  void _setText(String value) {
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 46,
      child: Row(
        children: [
          _StepButton(
            icon: Icons.remove,
            enabled: widget.enabled && widget.value > 1,
            onPressed: () => _step(-1),
          ),
          SizedBox(
            width: 68,
            height: 46,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              cursorColor: _primary,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onChanged: _handleChanged,
              onEditingComplete: _commit,
              style: const TextStyle(
                color: _text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
              decoration: _inputDecoration().copyWith(
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            enabled: widget.enabled && widget.value < 20,
            onPressed: () => _step(1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 46,
      child: OutlinedButton(
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: _label,
          disabledForegroundColor: _muted.withValues(alpha: 0.45),
          side: BorderSide(
            color: enabled
                ? _controlBorder
                : _controlBorder.withValues(alpha: 0.55),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _DnsRecordSelector extends StatefulWidget {
  const _DnsRecordSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final DnsRecordType value;
  final bool enabled;
  final ValueChanged<DnsRecordType> onChanged;

  @override
  State<_DnsRecordSelector> createState() => _DnsRecordSelectorState();
}

class _DnsRecordSelectorState extends State<_DnsRecordSelector> {
  bool _isOpen = false;

  void _select(DnsRecordType value) {
    widget.onChanged(value);
    setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return _InlineSelector<DnsRecordType>(
      width: 180,
      panelWidth: 260,
      label: widget.value.name.toUpperCase(),
      values: DnsRecordType.values,
      selectedValue: widget.value,
      isOpen: _isOpen,
      enabled: widget.enabled,
      labelFor: (value) => value.name.toUpperCase(),
      onToggle: () => setState(() => _isOpen = !_isOpen),
      onSelected: _select,
    );
  }
}

class _InlineSelector<T> extends StatelessWidget {
  const _InlineSelector({
    required this.width,
    required this.panelWidth,
    required this.label,
    required this.values,
    required this.selectedValue,
    required this.isOpen,
    required this.enabled,
    required this.labelFor,
    required this.onToggle,
    required this.onSelected,
  });

  final double width;
  final double panelWidth;
  final String label;
  final List<T> values;
  final T selectedValue;
  final bool isOpen;
  final bool enabled;
  final String Function(T value) labelFor;
  final VoidCallback onToggle;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InlineSelectorButton(
          width: width,
          label: label,
          enabled: enabled,
          isOpen: isOpen,
          onTap: enabled ? onToggle : null,
        ),
        if (isOpen) ...[
          const SizedBox(height: 8),
          Container(
            width: panelWidth,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in values)
                  _InlineOptionButton(
                    label: labelFor(value),
                    selected: value == selectedValue,
                    onTap: () => onSelected(value),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InlineSelectorButton extends StatelessWidget {
  const _InlineSelectorButton({
    required this.width,
    required this.label,
    required this.enabled,
    required this.isOpen,
    required this.onTap,
  });

  final double width;
  final String label;
  final bool enabled;
  final bool isOpen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: width,
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: !enabled
                ? _controlBorder.withValues(alpha: 0.55)
                : isOpen
                ? _primary
                : _controlBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: enabled ? _text : _muted.withValues(alpha: 0.45),
                  fontSize: 14,
                  letterSpacing: 0,
                ),
              ),
            ),
            Icon(
              isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: enabled ? _muted : _muted.withValues(alpha: 0.45),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineOptionButton extends StatelessWidget {
  const _InlineOptionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? _surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _controlBorder : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? _primary : _label,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, color: _primary, size: 15),
            ],
          ],
        ),
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
