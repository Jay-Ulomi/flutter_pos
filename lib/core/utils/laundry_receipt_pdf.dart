import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/laundry_models.dart';
import 'formatters.dart';

Future<Uint8List> buildLaundryReceiptPdf(
  LaundryOrder order, {
  String? businessName,
  String? branchName,
  String? businessAddress,
  String? businessPhone,
  String? tinNumber,
  String? cashierName,
  String currencySymbol = 'TZS',
  String? footerNote,
}) async {
  final doc = pw.Document();

  const pageFormat = PdfPageFormat(
    226.77,
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
      build: (_) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Center(
              child: pw.Text(
                (businessName ?? 'Laundry Receipt').toUpperCase(),
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
            _metaRow('Ticket', order.ticketNumber, boldStyle, baseStyle),
            if (order.createdAt != null)
              _metaRow(
                'Date',
                Formatters.dateTime(order.createdAt!),
                boldStyle,
                baseStyle,
              ),
            if (cashierName != null && cashierName.isNotEmpty)
              _metaRow('Cashier', cashierName, boldStyle, baseStyle),
            _metaRow(
              'Status',
              order.status.name.toUpperCase(),
              boldStyle,
              baseStyle,
            ),
            if ((order.customerName ?? '').isNotEmpty)
              _metaRow('Customer', order.customerName!, boldStyle, baseStyle),
            if ((order.customerPhone ?? '').isNotEmpty)
              _metaRow('Phone', order.customerPhone!, boldStyle, baseStyle),
            if (order.dueDate != null)
              _metaRow(
                'Due Date',
                Formatters.date(order.dueDate!),
                boldStyle,
                baseStyle,
              ),
            pw.SizedBox(height: 4),
            _divider(),
            pw.SizedBox(height: 4),
            for (final item in order.items) ...[
              pw.Text(item.itemName, style: boldStyle),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${Formatters.quantity(item.quantity)} x ${money(item.unitPrice)}',
                    style: smallStyle,
                  ),
                  pw.Text(money(item.lineTotal), style: baseStyle),
                ],
              ),
              pw.SizedBox(height: 3),
            ],
            _divider(),
            pw.SizedBox(height: 4),
            _totalRow(
              'TOTAL',
              money(order.totalAmount),
              totalStyle,
              totalStyle,
            ),
            _totalRow('PAID', money(order.paidAmount), baseStyle, baseStyle),
            _totalRow(
              'BALANCE',
              money(order.balanceAmount),
              baseStyle,
              baseStyle,
            ),
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
