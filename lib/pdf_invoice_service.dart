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
    required String customerPhone,
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
              // Header / Shop Name
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ZeeSip Juice Center',
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange800),
                      ),
                      pw.Text('Wholesale & Retail Juice Distributors'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Invoice #: $billId'),
                      pw.Text('Date: $formattedDate'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),

              // Customer Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Billed To: $customerName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      if (customerPhone.isNotEmpty) pw.Text('Phone: $customerPhone'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Payment Mode: $paymentMode', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Status: Confirmed'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Line Items Table
              pw.TableHelper.fromTextArray(
                headers: ['#', 'Item Description', 'Rate (Rs)', 'Qty', 'Total (Rs)'],
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
                headerDecoration: const pw.BoxDecoration(color: PdfColors.deepOrange800),
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

              // Grand Total
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Grand Total: Rs. ${totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                ),
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text('Thank you for choosing ZeeSip Juice Center!', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF
    final outputDir = await getTemporaryDirectory();
    final file = File('${outputDir.path}/ZeeSip_Bill_$billId.pdf');
    await file.writeAsBytes(await pdf.save());

    // Share directly via WhatsApp
    final shareMessage = 'Hello $customerName, here is your bill #$billId from *ZeeSip Juice Center* for Rs. ${totalAmount.toStringAsFixed(2)}.';
    await Share.shareXFiles(
      [XFile(file.path)],
      text: shareMessage,
      subject: 'ZeeSip Invoice #$billId',
    );
  }
}
