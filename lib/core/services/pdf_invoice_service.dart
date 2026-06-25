import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/order_model.dart';

class PdfInvoiceService {
  static pw.MemoryImage? _logoImage;

  static Future<void> _loadLogo() async {
    if (_logoImage != null) return;
    try {
      final data = await rootBundle.load('assets/images/logo_bg_removed.png');
      _logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}
  }

  /// Pre-cache the logo asset when the orders screen opens.
  static void preWarm() => _loadLogo();

  static Future<Uint8List> generateInvoice(OrderModel order) async {
    await _loadLogo();

    // Built-in PDF fonts — zero network cost, instant.
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) => [
          _buildHeader(order),
          pw.SizedBox(height: 20),
          _buildCustomerDetails(order),
          pw.SizedBox(height: 20),
          _buildProductTable(order),
          pw.SizedBox(height: 20),
          _buildSummary(order),
          pw.SizedBox(height: 40),
          _buildFooter(),
        ],
      ),
    );

    // Yield so Flutter's frame pipeline can finish before the heavy save().
    await Future.delayed(Duration.zero);
    return pdf.save();
  }

  static pw.Widget _buildHeader(OrderModel order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                if (_logoImage != null) ...[
                  pw.Image(_logoImage!, height: 50),
                  pw.SizedBox(width: 12),
                ],
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Sun Associates',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Order Invoice',
                      style: pw.TextStyle(
                        fontSize: 18,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Order ID: ${order.orderId}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt)}',
                ),
              ],
            ),
          ],
        ),
        pw.Divider(color: PdfColors.grey400),
      ],
    );
  }

  static pw.Widget _buildCustomerDetails(OrderModel order) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Customer Details',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Name: ${order.customerName}'),
        pw.Text('Phone: ${order.phone}'),
        if (order.address.isNotEmpty) pw.Text('Address: ${order.address}'),
        if (order.city.isNotEmpty ||
            order.state.isNotEmpty ||
            order.pincode.isNotEmpty)
          pw.Text('${order.city}, ${order.state} - ${order.pincode}'),
      ],
    );
  }

  static pw.Widget _buildProductTable(OrderModel order) {
    return pw.TableHelper.fromTextArray(
      headers: ['#', 'Product Name', 'Item Code', 'Qty', 'Price', 'Total'],
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(80),
        5: const pw.FixedColumnWidth(80),
      },
      data: List<List<dynamic>>.generate(order.products.length, (i) {
        final p = order.products[i];
        return [
          '${i + 1}',
          p.productName,
          p.itemCode.isNotEmpty ? p.itemCode : '-',
          '${p.quantity}',
          'Rs.${p.unitPrice.toStringAsFixed(2)}',
          'Rs.${p.totalPrice.toStringAsFixed(2)}',
        ];
      }),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildSummary(OrderModel order) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Spacer(flex: 6),
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _summaryRow('Subtotal', order.subtotal),
                _summaryRow('Discount', order.discount),
                _summaryRow('Delivery Charge', order.deliveryCharge),
                _summaryRow('Tax', order.tax),
                pw.Divider(),
                _summaryRow('Grand Total', order.grandTotal, isTotal: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow(String title, double value,
      {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
          pw.Text(
            'Rs.${value.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 8),
        pw.Text(
          'Thank you for shopping with Sun Associates.',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Phone: 9846203815 | Website: https://sunassociates.web.app',
          style: pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'This invoice is for reference only. The final payable amount may differ after verification.',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}
