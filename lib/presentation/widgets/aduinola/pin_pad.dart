import 'package:flutter/material.dart';

/// Dots + numeric keypad for PIN entry. Calls [onCompleted] once [length]
/// digits are in (or when the tick is pressed, for variable-length PINs).
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.onCompleted,
    this.minLength = 4,
    this.maxLength = 6,
    this.enabled = true,
  });

  final ValueChanged<String> onCompleted;
  final int minLength;
  final int maxLength;
  final bool enabled;

  @override
  State<PinPad> createState() => PinPadState();
}

class PinPadState extends State<PinPad> {
  String _pin = '';

  void clear() => setState(() => _pin = '');

  void _tap(String digit) {
    if (!widget.enabled || _pin.length >= widget.maxLength) return;
    setState(() => _pin += digit);
    if (_pin.length == widget.maxLength) _submit();
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _submit() {
    if (_pin.length < widget.minLength) return;
    final pin = _pin;
    widget.onCompleted(pin);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget key(String label, {VoidCallback? onTap, Widget? child, String? semantics}) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Semantics(
          button: true,
          label: semantics ?? label,
          child: Material(
            color: child == null ? cs.surface : Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              key: ValueKey('pin-key-$label'),
              customBorder: const CircleBorder(),
              onTap: widget.enabled ? onTap : null,
              child: SizedBox(
                width: 68,
                height: 68,
                child: Center(
                  child: child ??
                      Text(label, style: Theme.of(context).textTheme.headlineSmall),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.maxLength, (i) {
            final filled = i < _pin.length;
            final optional = i >= widget.minLength;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              margin: const EdgeInsets.symmetric(horizontal: 7),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? cs.primary : Colors.transparent,
                border: Border.all(
                  color: filled
                      ? cs.primary
                      : cs.outline.withValues(alpha: optional ? 0.4 : 1),
                  width: 1.6,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 28),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (final d in row) key(d, onTap: () => _tap(d))],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            key('back', onTap: _backspace, semantics: 'Delete',
                child: Icon(Icons.backspace_outlined, color: cs.onSurfaceVariant)),
            key('0', onTap: () => _tap('0')),
            key('ok',
                onTap: _pin.length >= widget.minLength ? _submit : null,
                semantics: 'Submit',
                child: Icon(Icons.check_circle_rounded,
                    size: 36,
                    color: _pin.length >= widget.minLength
                        ? cs.primary
                        : cs.outline.withValues(alpha: 0.5))),
          ],
        ),
      ],
    );
  }
}
