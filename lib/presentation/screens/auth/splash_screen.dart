import 'package:flutter/material.dart';

/// Shown while the stored session is checked; the router moves on as soon as
/// the auth state is known. Solid brand green with the emblem, as in the design.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFF0E5023),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            Center(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Image.asset(
                  'assets/brand/aduinola_mark.png',
                  height: 84,
                  errorBuilder: (_, _, _) => Icon(Icons.storefront_rounded, size: 84, color: cs.primary),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'ADUINOLA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'POINT OF SALE',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
                letterSpacing: 2.5,
              ),
            ),
            const Spacer(flex: 3),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
