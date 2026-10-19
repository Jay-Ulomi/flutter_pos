import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_theme.dart';

/// Shared building blocks for the redesigned screens.

/// Paints the soft green-grey background gradient behind [child].
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.decor.background),
      child: child,
    );
  }
}

/// Scaffold with the gradient background and a transparent app bar.
class GradientScaffold extends StatelessWidget {
  const GradientScaffold({
    super.key,
    this.title,
    this.actions,
    this.leading,
    required this.body,
    this.bottomBar,
    this.floatingActionButton,
    this.automaticallyImplyLeading = true,
  });

  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget body;
  final Widget? bottomBar;
  final Widget? floatingActionButton;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: title == null && actions == null && leading == null
            ? null
            : AppBar(
                title: title == null ? null : Text(title!),
                actions: actions,
                leading: leading,
                automaticallyImplyLeading: automaticallyImplyLeading,
              ),
        body: body,
        bottomNavigationBar: bottomBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}

/// White circular icon button used in headers (back, bell, filter…).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.filled = false,
    this.size = 44,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  /// Primary-filled instead of white.
  final bool filled;
  final double size;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final button = Material(
      color: filled ? cs.primary : cs.surface,
      shape: CircleBorder(
        side: filled ? BorderSide.none : BorderSide(color: cs.outlineVariant),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: size * 0.48, color: filled ? cs.onPrimary : cs.onSurface),
        ),
      ),
    );
    final withBadge = badge == null
        ? button
        : Badge(label: Text(badge!), backgroundColor: cs.secondary, child: button);
    return tooltip == null ? withBadge : Tooltip(message: tooltip!, child: withBadge);
  }
}

/// Pill search field with a search icon and an optional mic button.
///
/// The mic is visual only — speech input is not wired yet (see README).
class SearchPill extends StatelessWidget {
  const SearchPill({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onMic,
    this.trailing,
    this.autofocus = false,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onMic;
  final Widget? trailing;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint ?? context.tr('common.search'),
        prefixIcon: const Icon(Icons.search_rounded),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        suffixIcon: trailing ??
            (onMic == null
                ? null
                : IconButton(
                    tooltip: 'Voice search',
                    icon: Icon(Icons.mic_none_rounded, color: cs.primary),
                    onPressed: onMic,
                  )),
      ),
    );
  }
}

/// Horizontal row of selectable pill chips (categories, filters).
class PillChips<T> extends StatelessWidget {
  const PillChips({
    super.key,
    required this.items,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<T> items;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          final isSelected = item == selected;
          return ChoiceChip(
            label: Text(labelOf(item)),
            selected: isSelected,
            onSelected: (_) => onSelected(item),
            labelStyle: TextStyle(
              color: isSelected ? cs.onPrimary : cs.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          );
        },
      ),
    );
  }
}

enum PillTone { paid, unpaid, partial, neutral }

/// Small rounded status label ("Paid", "Unpaid", "Partial").
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.tone = PillTone.neutral});
  final String label;
  final PillTone tone;

  static PillTone toneFor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'PAID':
      case 'COMPLETED':
      case 'SETTLED':
      case 'RECEIVED':
      case 'CONVERTED':
        return PillTone.paid;
      case 'UNPAID':
      case 'OVERDUE':
      case 'VOIDED':
      case 'CANCELLED':
      case 'REJECTED':
        return PillTone.unpaid;
      case 'PARTIAL':
      case 'PARTIALLY_PAID':
      case 'PENDING':
        return PillTone.partial;
      default:
        return PillTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.decor;
    final (bg, fg) = switch (tone) {
      PillTone.paid => (d.paidBg, d.paidFg),
      PillTone.unpaid => (d.unpaidBg, d.unpaidFg),
      PillTone.partial => (d.partialBg, d.partialFg),
      PillTone.neutral => (d.neutralBg, d.neutralFg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// White rounded card with padding — the main surface of the redesign.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Section title used above groups of cards.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Aduinola wordmark (falls back to text if the asset is missing).
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.height = 40});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/aduinola_wordmark.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Text(
        'Aduinola',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// Circular avatar showing the initials of [name].
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {super.key, this.radius = 22});
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: cs.primaryContainer,
      foregroundColor: cs.onPrimaryContainer,
      child: Text(initials, style: TextStyle(fontSize: radius * 0.7, fontWeight: FontWeight.w600)),
    );
  }
}

/// Centered message with an optional retry button.
class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.icon, required this.message, this.onRetry});
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: Text(context.tr('common.retry'))),
            ],
          ],
        ),
      ),
    );
  }
}

/// Title row at the top of every bottom sheet (below the drag handle).
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, this.icon, this.trailing, this.onClose});
  final String title;
  final IconData? icon;
  final Widget? trailing;

  /// Shows a round close button when set.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
      child: Row(
        children: [
          if (icon != null) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.primaryContainer,
              child: Icon(icon, size: 20, color: cs.primary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          ?trailing,
          if (onClose != null)
            RoundIconButton(icon: Icons.close_rounded, tooltip: 'Close', size: 38, onPressed: onClose),
        ],
      ),
    );
  }
}
