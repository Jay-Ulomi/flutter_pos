import 'package:flutter/material.dart';

import '../../widgets/aduinola/ui.dart';

/// Shown while the stored session is checked; the router moves on as soon as
/// the auth state is known.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            Center(
              child: Image.asset(
                'assets/brand/aduinola_mark.png',
                height: 96,
                errorBuilder: (_, _, _) => const SizedBox(height: 96),
              ),
            ),
            const SizedBox(height: 20),
            const BrandWordmark(height: 44),
            const SizedBox(height: 10),
            Text(
              'Sell. Track. Grow.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const Spacer(flex: 3),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
