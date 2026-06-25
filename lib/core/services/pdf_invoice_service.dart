import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/order_model.dart';

class PdfInvoiceService {
  static pw.MemoryImage? _logoImage;
  static pw.MemoryImage? _malayalamImage;
  static Future<void>? _warmFuture;

  static const _malayalamDisclaimer =
      'ഇവിടെ നൽകിയിരിക്കുന്ന തുക റഫറൻസിനായി മാത്രമാണ്. '
      'അന്തിമ ബിൽ തയ്യാറാക്കിയ ശേഷം മാത്രമേ '
      'യഥാർത്ഥ തുക സ്ഥിരീകരിക്കുകയുള്ളു.';

  static Future<void> _doWarm() async {
    await Future.wait([_loadLogo(), _renderMalayalamImage()]);
  }

  static Future<void> _loadLogo() async {
    if (_logoImage != null) return;
    try {
      final data = await rootBundle.load('assets/images/logo_bg_removed.png');
      _logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}
  }

  /// Renders the Malayalam disclaimer using the browser's native canvas,
  /// which has full complex-script / font-fallback support.
  static Future<void> _renderMalayalamImage() async {
    if (_malayalamImage != null) return;
    try {
      const double canvasW = 1400;
      const double fontSize = 26;
      const double lineHeight = 38;

      // Measure pass — get actual line wraps
      final measureCanvas = web.HTMLCanvasElement()
        ..width = 1
        ..height = 1;
      final mCtx =
          measureCanvas.getContext('2d') as web.CanvasRenderingContext2D
            ..font = '${fontSize}px sans-serif';
      final lines = _wrapLines(mCtx, _malayalamDisclaimer, canvasW - 40);

      final canvasH = (lines.length * lineHeight + 24).ceil();

      // Render pass
      final canvas = web.HTMLCanvasElement()
        ..width = canvasW.toInt()
        ..height = canvasH;
      final ctx =
          canvas.getContext('2d') as web.CanvasRenderingContext2D
            ..fillStyle = '#ffffff'.toJS
            ..fillRect(0, 0, canvasW, canvasH.toDouble())
            ..fillStyle = '#888888'.toJS
            ..font = '${fontSize}px sans-serif'
            ..textAlign = 'center';

      var y = fontSize + 4;
      for (final line in lines) {
        ctx.fillText(line, canvasW / 2, y);
        y += lineHeight;
      }

      final dataUrl = canvas.toDataURL('image/png');
      final bytes = base64Decode(dataUrl.split(',').last);
      _malayalamImage = pw.MemoryImage(bytes);
    } catch (_) {}
  }

  static List<String> _wrapLines(
    web.CanvasRenderingContext2D ctx,
    String text,
    double maxWidth,
  ) {
    final words = text.split(' ');
    final lines = <String>[];
    var current = '';
    for (final word in words) {
      final test = current.isEmpty ? word : '$current $word';
      final w = ctx.measureText(test).width;
      if (w > maxWidth && current.isNotEmpty) {
        lines.add(current);
        current = word;
      } else {
        current = test;
      }
    }
    if (current.isNotEmpty) lines.add(current);
    return lines;
  }

  static void preWarm() {
    _warmFuture ??= _doWarm();
  }

  static Future<Uint8List> generateInvoice(OrderModel order) async {
    _warmFuture ??= _doWarm();
    await _warmFuture;

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
          p.productName.replaceAll('–', '-').replaceAll('—', '-'),
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
        pw.SizedBox(height: 10),
        if (_malayalamImage != null)
          pw.Image(_malayalamImage!, width: 480),
        pw.SizedBox(height: 4),
        pw.Text(
          'This invoice is generated for reference purposes only. The displayed amount is not the final payable amount. The final invoice may differ after verification and billing adjustments.',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}
