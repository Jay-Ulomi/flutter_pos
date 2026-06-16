import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/receipt_panel.dart';

/// Full-page receipt used when navigating directly to /receipt on mobile.
/// On desktop, the receipt is shown inline via [ReceiptPanel] in the POS screen.
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ReceiptPanel(
          // ReceiptPanel already fires SaleCleared before calling this
          onNewSale: () => context.go('/pos'),
        ),
      ),
    );
  }
}
