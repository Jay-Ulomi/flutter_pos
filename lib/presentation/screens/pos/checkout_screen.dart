import 'package:flutter/material.dart';

import '../../widgets/checkout_panel.dart';

/// Full-page checkout used on mobile (narrow) screens.
/// On desktop, checkout is shown inline via [CheckoutPanel] in the POS screen.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CheckoutPanel(
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
