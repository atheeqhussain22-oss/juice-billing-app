import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfInvoiceService {
  static Future<void> generateAndShareInvoice({
    required int billId,
    required String customerName,
    required String dateTime,
    required String paymentMode,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    final pdf = pw.Document();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(dateTime));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'WHOLESALE JUICE DISTRIBUTOR',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                      ),
                      pw.Text('Main Market Yard'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Bill #: $billId'),
                      pw.Text('Date: $formattedDate'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.Text('Customer: $customerName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Payment Mode: $paymentMode'),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: ['#', 'Product', 'Rate (Rs)', 'Qty', 'Total (Rs)'],
                data: List<List<dynamic>>.generate(items.length, (index) {
                  final item = items[index];
                  return [
                    '${index + 1}',
                    item['item_name'] ?? item['name'],
                    (item['unit_price'] ?? item['price']).toStringAsFixed(2),
                    '${item['quantity'] ?? item['qty']}',
                    (item['subtotal'] ?? (item['qty'] * item['price'])).toStringAsFixed(2),
                  ];
                }),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerRight,
                },
                cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Grand Total: Rs. ${totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                ),
              ),
            ],
          );
        },
      ),
    );

    final outputDir = await getTemporaryDirectory();
    final file = File('${outputDir.path}/Invoice_$billId.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Invoice #$billId for $customerName. Total: Rs. ${totalAmount.toStringAsFixed(2)}',
    );
  }
}
