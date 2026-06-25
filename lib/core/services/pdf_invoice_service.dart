import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/order_model.dart';

class PdfInvoiceService {
  static Future<Uint8List> generateInvoice(OrderModel order) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular().timeout(
      const Duration(seconds: 5),
    );
    final fontBold = await PdfGoogleFonts.robotoBold().timeout(
      const Duration(seconds: 5),
    );

    final theme = pw.ThemeData.withFont(base: font, bold: fontBold);

    final productTable = await _buildProductTable(order);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: theme,
        build: (pw.Context context) {
          return [
            _buildHeader(order),
            pw.SizedBox(height: 20),
            _buildCustomerDetails(order),
            pw.SizedBox(height: 20),
            productTable,
            pw.SizedBox(height: 20),
            _buildSummary(order),
            pw.SizedBox(height: 40),
            _buildFooter(),
          ];
        },
      ),
    );

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
                  style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700),
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
        pw.Text('Phone Number: ${order.phone}'),
        if (order.address.isNotEmpty) pw.Text('Address: ${order.address}'),
        if (order.city.isNotEmpty ||
            order.state.isNotEmpty ||
            order.pincode.isNotEmpty)
          pw.Text('${order.city}, ${order.state} - ${order.pincode}'),
      ],
    );
  }

  static Future<pw.Widget> _buildProductTable(OrderModel order) async {
    final Map<String, pw.ImageProvider> imageMap = {};
    for (final p in order.products) {
      if (p.imageUrl.isNotEmpty && !imageMap.containsKey(p.imageUrl)) {
        try {
          final img = await networkImage(
            p.imageUrl,
          ).timeout(const Duration(seconds: 5));
          imageMap[p.imageUrl] = img;
        } catch (e) {}
      }
    }

    return pw.TableHelper.fromTextArray(
      headers: [
        'Image',
        'Product Name',
        'Product ID',
        'Qty',
        'Unit Price',
        'Total',
      ],
      data: List<List<dynamic>>.generate(order.products.length, (index) {
        final p = order.products[index];
        return [
          p.imageUrl,
          p.productName,
          p.productId,
          p.quantity.toString(),
          '₹${p.unitPrice.toStringAsFixed(2)}',
          '₹${p.totalPrice.toStringAsFixed(2)}',
        ];
      }),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellHeight: 50,
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
      },
      cellBuilder: (int columnIndex, dynamic cellValue, int rowIndex) {
        if (columnIndex == 0 && rowIndex > 0) {
          final imageUrl = cellValue as String;
          if (imageUrl.isNotEmpty && imageMap.containsKey(imageUrl)) {
            return pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.all(2),
              child: pw.Image(imageMap[imageUrl]!, width: 40, height: 40),
            );
          } else {
            return pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Text('No Image', style: pw.TextStyle(fontSize: 8)),
            );
          }
        }
        return null;
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
                _buildSummaryRow('Subtotal', order.subtotal),
                _buildSummaryRow('Discount', order.discount),
                _buildSummaryRow('Delivery Charge', order.deliveryCharge),
                _buildSummaryRow('Tax', order.tax),
                pw.Divider(),
                _buildSummaryRow(
                  'Grand Total',
                  order.grandTotal,
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String title,
    double value, {
    bool isTotal = false,
  }) {
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
            '₹${value.toStringAsFixed(2)}',
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
      ],
    );
  }
}
