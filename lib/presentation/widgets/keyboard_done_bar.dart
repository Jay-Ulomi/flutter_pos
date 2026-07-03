import 'package:flutter/material.dart';

import '../../core/theme/brand_colors.dart';

/// A clean app toolbar that sits on top of the soft keyboard, giving numeric
/// keypads (which have no return/Done key) a way to dismiss. It's an app-drawn
/// control (an app can't render inside the system keyboard), so it's styled as
/// an intentional white bar with a soft shadow rather than faking the keyboard.
class KeyboardDoneBar extends StatelessWidget {
  const KeyboardDoneBar({super.key});

  /// Height of the bar — callers inflate the scroll view's bottom inset by this
  /// so a focused field scrolls above the bar instead of behind it.
  static const double height = 46;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        child: SizedBox(
          height: height,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: TextButton(
                onPressed: () => FocusScope.of(context).unfocus(),
                style: TextButton.styleFrom(
                  foregroundColor: BrandColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
