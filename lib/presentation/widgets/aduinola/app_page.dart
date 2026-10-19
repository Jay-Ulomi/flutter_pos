import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../responsive_shell.dart';
import 'ui.dart';

/// Breakpoints shared by every in-app page.
class AppBreakpoints {
  AppBreakpoints._();

  /// Phone below this.
  static const tablet = 600.0;

  /// Desktop at and above this.
  static const desktop = 1024.0;

  /// Forms switch to two columns at this content width.
  static const formTwoColumns = 900.0;

  /// Lists/grids may add columns at this width.
  static const wide = 1280.0;

  /// Page gutter: 16 on phones, 24 on tablets, 32 on desktop.
  static double gutter(double width) => width < tablet ? 16 : (width < desktop ? 24 : 32);
}

/// The standard in-app page: the navigation shell, one header style (round
/// back button, title, actions), the brand background, full-width content
/// with the shared gutter, and an optional bottom [actionBar].
///
/// Pre-till screens (splash, login, pickers, lock) don't use this; they keep
/// their centred cards.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.actionBar,
    this.floatingActionButton,
    this.showBack,
    this.onBack,
    this.padBody = true,
    this.showBottomNav = true,
    this.titleWidget,
  });

  final String title;

  /// Replaces the title text (e.g. the brand wordmark on Home).
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final Widget? actionBar;
  final Widget? floatingActionButton;

  /// Back button; defaults to "the router can pop".
  final bool? showBack;
  final VoidCallback? onBack;

  /// Wrap [body] in the page gutter. Lists that scroll edge to edge pass
  /// false and use [AppPage.insets] for their own padding.
  final bool padBody;
  final bool showBottomNav;

  /// Content padding for this width (gutter on the sides, 8 on top).
  static EdgeInsets insets(BuildContext context, {double top = 8, double bottom = 24}) {
    final g = AppBreakpoints.gutter(MediaQuery.sizeOf(context).width);
    return EdgeInsets.fromLTRB(g, top, g, bottom);
  }

  static double gutterOf(BuildContext context) => AppBreakpoints.gutter(MediaQuery.sizeOf(context).width);

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    final canPop = showBack ?? (router?.canPop() ?? Navigator.of(context).canPop());
    final g = gutterOf(context);
    return ResponsiveShell(
      showBottomNav: showBottomNav,
      actionBar: actionBar,
      floatingActionButton: floatingActionButton,
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: canPop ? 4 : g,
        leadingWidth: canPop ? g + 44 : null,
        leading: canPop
            ? Padding(
                padding: EdgeInsets.only(left: g),
                child: Center(
                  child: RoundIconButton(
                    key: const ValueKey('page-back'),
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    size: 40,
                    onPressed: onBack ?? () => router != null ? router.pop() : Navigator.of(context).maybePop(),
                  ),
                ),
              )
            : null,
        automaticallyImplyLeading: false,
        title: titleWidget ?? Text(title),
        actions: [...?actions, SizedBox(width: g - 8)],
      ),
      child: padBody ? Padding(padding: insets(context, bottom: 0), child: body) : body,
    );
  }
}

/// Lays form fields out in a full-width grid: two columns at
/// [AppBreakpoints.formTwoColumns] and wider, one column below. Wrap a child
/// in [FormSpan] to make it take the full row.
class FormGrid extends StatelessWidget {
  const FormGrid({super.key, required this.children, this.spacing = 16, this.runSpacing = 4});

  final List<Widget> children;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final two = c.maxWidth >= AppBreakpoints.formTwoColumns;
      final half = two ? (c.maxWidth - spacing) / 2 : c.maxWidth;
      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: [
          for (final child in children)
            SizedBox(
              width: child is FormSpan ? c.maxWidth : half,
              child: child,
            ),
        ],
      );
    });
  }
}

/// A [FormGrid] child that spans both columns.
class FormSpan extends StatelessWidget {
  const FormSpan({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Label above a field, the form style used across the app.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
        child,
      ],
    );
  }
}

/// Grid column count for card lists: 1 on phones, 2 from 900, 3 from 1280.
int responsiveColumns(double width, {int max = 3}) {
  final n = width >= AppBreakpoints.wide ? 3 : (width >= AppBreakpoints.formTwoColumns ? 2 : 1);
  return n > max ? max : n;
}

/// Full-width white rounded card used for forms and sections.
class PageCard extends StatelessWidget {
  const PageCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return SoftCard(
      padding: padding ?? EdgeInsets.all(w < AppBreakpoints.tablet ? 16 : 24),
      child: child,
    );
  }
}

/// Cancel / Save pair used as the [AppPage.actionBar] of every form.
class FormActions extends StatelessWidget {
  const FormActions({
    super.key,
    required this.onSave,
    required this.onCancel,
    this.saving = false,
    this.saveLabel,
    this.saveKey = const ValueKey('form-save'),
  });

  final VoidCallback? onSave;
  final VoidCallback onCancel;
  final bool saving;
  final String? saveLabel;
  final Key saveKey;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= AppBreakpoints.formTwoColumns;
    final cancel = OutlinedButton(onPressed: onCancel, child: Text(context.tr('common.cancel')));
    final save = FilledButton(
      key: saveKey,
      onPressed: saving ? null : onSave,
      child: saving
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Text(saveLabel ?? context.tr('common.save')),
    );
    // Phones: two equal halves. Wide: the buttons sit at the right of the bar.
    if (!wide) {
      return Row(children: [Expanded(child: cancel), const SizedBox(width: 12), Expanded(child: save)]);
    }
    return Row(children: [
      const Spacer(),
      SizedBox(width: 180, child: cancel),
      const SizedBox(width: 12),
      SizedBox(width: 220, child: save),
    ]);
  }
}

/// Marks the start of a section inside [PageSections].
class PageSectionTitle extends StatelessWidget {
  const PageSectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

/// A scrolling page of sections laid out full width: each [PageSectionTitle]
/// or [SectionLabel] starts a section, and sections flow in one column on
/// phones and two from 900 px (three from 1280 when [maxColumns] allows).
/// Bare spacer `SizedBox`es between sections are dropped.
class PageSections extends StatelessWidget {
  const PageSections({super.key, required this.children, this.maxColumns = 2, this.footer});

  final List<Widget> children;
  final int maxColumns;

  /// Full-width widgets after the sections.
  final List<Widget>? footer;

  @override
  Widget build(BuildContext context) {
    final sections = <List<Widget>>[];
    for (final w in children) {
      if (w is SizedBox && w.child == null) continue;
      if (w is PageSectionTitle || w is SectionLabel || sections.isEmpty) sections.add([]);
      sections.last.add(w);
    }
    return ListView(
      padding: AppPage.insets(context),
      children: [
        LayoutBuilder(builder: (context, c) {
          final cols = responsiveColumns(c.maxWidth, max: maxColumns);
          final width = (c.maxWidth - 16 * (cols - 1)) / cols;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final s in sections)
                SizedBox(
                  width: width,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: s),
                ),
            ],
          );
        }),
        ...?footer,
      ],
    );
  }
}
