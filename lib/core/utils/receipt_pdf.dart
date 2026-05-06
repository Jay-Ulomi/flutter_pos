import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/sale_models.dart';
import 'formatters.dart';

/// Builds a compact, thermal-receipt-style PDF (80mm wide) for a completed
/// sale. The document is a single-page roll — the page height grows with
/// content so nothing gets clipped on long receipts.
Future<Uint8List> buildReceiptPdf(
  Sale sale, {
  String? businessName,
  String? branchName,
  String? businessAddress,
  String? businessPhone,
  String? tinNumber,
  String? cashierName,
  String? customerName,
  int? loyaltyPointsEarned,
  String currencySymbol = 'TZS',
  String? footerNote,
}) async {
  final doc = pw.Document();

  // 80mm roll paper is ~227pt wide; we give a comfortable height budget and
  // the engine shrinks to content height using `build` below.
  const pageFormat = PdfPageFormat(
    226.77, // 80mm
    double.infinity,
    marginTop: 12,
    marginBottom: 12,
    marginLeft: 10,
    marginRight: 10,
  );

  final baseStyle = pw.TextStyle(fontSize: 9);
  final boldStyle = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
  final smallStyle = pw.TextStyle(fontSize: 8, color: PdfColors.grey700);
  final totalStyle = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);

  String money(double v) => Formatters.currency(v, symbol: currencySymbol);

  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            // Header
            pw.Center(
              child: pw.Text(
                (businessName ?? 'Receipt').toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            if (branchName != null && branchName.isNotEmpty)
              pw.Center(child: pw.Text(branchName, style: baseStyle)),
            if (businessAddress != null && businessAddress.isNotEmpty)
              pw.Center(child: pw.Text(businessAddress, style: smallStyle)),
            if (businessPhone != null && businessPhone.isNotEmpty)
              pw.Center(
                child: pw.Text('Tel: $businessPhone', style: smallStyle),
              ),
            if (tinNumber != null && tinNumber.isNotEmpty)
              pw.Center(child: pw.Text('TIN: $tinNumber', style: smallStyle)),
            pw.SizedBox(height: 6),
            _divider(),
            pw.SizedBox(height: 4),

            // Meta
            _metaRow(
              'Sale #',
              Formatters.saleNumber(sale.saleNumber),
              boldStyle,
              baseStyle,
            ),
            if (sale.createdAt != null)
              _metaRow(
                'Date',
                Formatters.dateTime(sale.createdAt!),
                boldStyle,
                baseStyle,
              ),
            if (cashierName != null && cashierName.isNotEmpty)
              _metaRow('Cashier', cashierName, boldStyle, baseStyle),
            if (customerName != null && customerName.isNotEmpty)
              _metaRow('Customer', customerName, boldStyle, baseStyle),
            pw.SizedBox(height: 4),
            _divider(),

            // Items
            pw.SizedBox(height: 4),
            for (final item in sale.items) ...[
              pw.Text(item.productName, style: boldStyle),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${Formatters.quantity(item.quantity)} x ${money(item.unitPrice)}',
                    style: smallStyle,
                  ),
                  pw.Text(money(item.totalPrice), style: baseStyle),
                ],
              ),
              pw.SizedBox(height: 3),
            ],

            _divider(),
            pw.SizedBox(height: 4),

            // Totals
            _totalRow('Subtotal', money(sale.subtotal), baseStyle, baseStyle),
            if (sale.taxAmount != 0)
              _totalRow('Tax', money(sale.taxAmount), baseStyle, baseStyle),
            if (sale.discountAmount > 0)
              _totalRow(
                'Discount',
                '-${money(sale.discountAmount)}',
                baseStyle,
                baseStyle,
              ),
            pw.SizedBox(height: 2),
            _totalRow('TOTAL', money(sale.totalAmount), totalStyle, totalStyle),
            pw.SizedBox(height: 4),
            _divider(),
            pw.SizedBox(height: 4),

            // Payments
            if (sale.payments.isNotEmpty)
              for (final p in sale.payments)
                _totalRow(p.method, money(p.amount), baseStyle, baseStyle)
            else
              _totalRow('Paid', money(sale.paidAmount), baseStyle, baseStyle),
            if (sale.changeAmount > 0)
              _totalRow(
                'Change',
                money(sale.changeAmount),
                boldStyle,
                boldStyle,
              ),
            if (loyaltyPointsEarned != null && loyaltyPointsEarned > 0) ...[
              pw.SizedBox(height: 4),
              _divider(),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  'Loyalty points earned: +$loyaltyPointsEarned',
                  style: boldStyle,
                ),
              ),
            ],
            pw.SizedBox(height: 8),
            _divider(),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                footerNote ?? 'Thank you for your business!',
                style: smallStyle,
              ),
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

pw.Widget _divider() => pw.Container(height: 0.5, color: PdfColors.grey600);

pw.Widget _metaRow(
  String label,
  String value,
  pw.TextStyle labelStyle,
  pw.TextStyle valueStyle,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: labelStyle),
        pw.Expanded(
          child: pw.Text(
            value,
            style: valueStyle,
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _totalRow(
  String label,
  String value,
  pw.TextStyle labelStyle,
  pw.TextStyle valueStyle,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: labelStyle),
        pw.Text(value, style: valueStyle),
      ],
    ),
  );
}
