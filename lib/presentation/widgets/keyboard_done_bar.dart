import 'package:flutter/material.dart';

import '../../core/theme/brand_colors.dart';

/// An iOS-style input-accessory toolbar that sits flush on top of the soft
/// keyboard, giving numeric keypads (which have no return/Done key) a way to
/// dismiss. Styled to match the keyboard's grey backdrop so it reads as part of
/// the keyboard rather than a floating strip.
class KeyboardDoneBar extends StatelessWidget {
  const KeyboardDoneBar({super.key});

  /// Height of the bar — callers inflate the scroll view's bottom inset by this
  /// so a focused field scrolls above the bar instead of behind it.
  static const double height = 44;

  @override
  Widget build(BuildContext context) {
    return Material(
      // Matches the light iOS keyboard backdrop so the bar blends with it.
      color: const Color(0xFFD1D4DB),
      child: Container(
        height: height,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFAEB2BA), width: 0.5),
          ),
        ),
        child: TextButton(
          onPressed: () => FocusScope.of(context).unfocus(),
          style: TextButton.styleFrom(
            foregroundColor: BrandColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Done',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
