import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Six digit boxes backed by one invisible text field, so paste, autofill
/// (SMS/one-time-code) and backspace all behave like a normal input.
class OtpBoxes extends StatefulWidget {
  const OtpBoxes({super.key, required this.onCompleted, this.onChanged, this.length = 6});

  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final int length;

  @override
  State<OtpBoxes> createState() => OtpBoxesState();
}

class OtpBoxesState extends State<OtpBoxes> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  String get value => _ctrl.text;

  void clear() {
    _ctrl.clear();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = _ctrl.text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focus.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.length, (i) {
              final active = _focus.hasFocus && i == text.length.clamp(0, widget.length - 1);
              return Container(
                key: ValueKey('otp-box-$i'),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 46,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active ? cs.primary : cs.outlineVariant,
                    width: active ? 1.8 : 1,
                  ),
                ),
                child: Text(
                  i < text.length ? text[i] : '',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              );
            }),
          ),
          // The real input: transparent, on top so it receives taps & paste.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                key: const ValueKey('otp-input'),
                controller: _ctrl,
                focusNode: _focus,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                showCursor: false,
                enableInteractiveSelection: false,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  counterText: '',
                ),
                onChanged: (v) {
                  setState(() {});
                  widget.onChanged?.call(v);
                  if (v.length == widget.length) widget.onCompleted(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
