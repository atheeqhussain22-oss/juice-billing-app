import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfInvoiceService {
  static String convertToWords(int n) {
    if (n == 0) return "Zero";
    final units = [
      "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
      "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
      "Seventeen", "Eighteen", "Nineteen"
    ];
    final tens = [
      "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
    ];

    String formatChunk(int num) {
      String out = "";
      if (num >= 100) {
        out += "${units[num ~/ 100]} Hundred ";
        num %= 100;
      }
      if (num >= 20) {
        out += "${tens[num ~/ 10]} ";
        num %= 10;
      }
      if (num > 0) {
        out += "${units[num]} ";
      }
      return out.trim();
    }

    String words = "";
    if ((n ~/ 10000000) > 0) {
      words += "${formatChunk(n ~/ 10000000)} Crore ";
      n %= 10000000;
    }
    if ((n ~/ 100000) > 0) {
      words += "${formatChunk(n ~/ 100000)} Lakh ";
      n %= 100000;
    }
    if ((n ~/ 1000) > 0) {
      words += "${formatChunk(n ~/ 1000)} Thousand ";
      n %= 1000;
    }
    if (n > 0) {
      words += formatChunk(n);
    }
    return "${words.trim()} Only";
  }

  static Future<void> generateAndShareInvoice({
    required int billId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required String dateTime,
    required String paymentMode,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    List<List<double?>>? signaturePoints,
  }) async {
    final pdf = pw.Document();
    final formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.parse(dateTime));
    final formattedBillNo = billId.toString().padLeft(3, '0');
    final amountInWords = convertToWords(totalAmount.round());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue900, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Header: Logo, Author, Contact
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 48,
                          height: 48,
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue900,
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            'AE',
                            style: pw.TextStyle(color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Prop: MD SULTAN AHMED', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            pw.Text('WhatsApp: 90084 60450', style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue900)),
                          ],
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Mob: 99860 53878 / 99862 68994', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text('Email: smgzeesip@gmail.com', style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue900)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),

                // Center Company Banner
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'AMAFHH ENTERPRISES',
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.Text('RML Nagar, 2nd Cross, Shivamogga - 577 202', style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue900)),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue900,
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Text(
                          '$paymentMode BILL',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // Bill No & Date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('No. $formattedBillNo', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                    pw.Text('Date: $formattedDate', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  ],
                ),
                pw.Divider(color: PdfColors.blue900, thickness: 1),

                // Customer Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('To: $customerName', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          if (customerAddress.isNotEmpty)
                            pw.Text('Address: $customerAddress', style: const pw.TextStyle(fontSize: 10, color: PdfColors.blue900)),
                        ],
                      ),
                    ),
                    if (customerPhone.isNotEmpty)
                      pw.Text('Phone: $customerPhone', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Line Items Table
                pw.TableHelper.fromTextArray(
                  headers: ['Sl. No.', 'Particulars', 'Qty.', 'Rate (Rs.)', 'Amount (Rs.)'],
                  data: List<List<dynamic>>.generate(items.length, (index) {
                    final item = items[index];
                    return [
                      '${index + 1}',
                      item['item_name'] ?? item['name'],
                      '${item['quantity'] ?? item['qty']}',
                      (item['unit_price'] ?? item['price']).toStringAsFixed(2),
                      (item['subtotal'] ?? (item['qty'] * item['price'])).toStringAsFixed(2),
                    ];
                  }),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  cellStyle: const pw.TextStyle(fontSize: 10, color: PdfColors.blue900),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellAlignments: {
                    0: pw.Alignment.center,
                    2: pw.Alignment.center,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerRight,
                  },
                  cellPadding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
                ),

                pw.Spacer(),

                // Bottom: Amount In Words & Grand Total Box
                pw.Container(
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.blue900, width: 1)),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Rupees in words: $amountInWords', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                              pw.SizedBox(height: 4),
                              pw.Text('Terms & Conditions: Thanks for doing business with us.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue900)),
                            ],
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.all(8),
                          decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: PdfColors.blue900, width: 1))),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('Grand Total', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                              pw.Text('Rs. ${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // Digital Sign Input Rendering on PDF
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('For: AMAFHH ENTERPRISES', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        width: 130,
                        height: 45,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.blue300, width: 1),
                          color: PdfColors.grey100,
                        ),
                        child: (signaturePoints != null && signaturePoints.isNotEmpty)
                            ? pw.CustomPaint(
                                painter: (PdfGraphics canvas, PdfPoint size) {
                                  canvas.setColor(PdfColors.blue900);
                                  canvas.setLineWidth(1.5);
                                  for (int i = 0; i < signaturePoints.length - 1; i++) {
                                    final p1 = signaturePoints[i];
                                    final p2 = signaturePoints[i + 1];
                                    if (p1[0] != null && p2[0] != null) {
                                      // Scale to PDF box
                                      final x1 = (p1[0]! / 300.0) * size.x;
                                      final y1 = size.y - ((p1[1]! / 110.0) * size.y);
                                      final x2 = (p2[0]! / 300.0) * size.x;
                                      final y2 = size.y - ((p2[1]! / 110.0) * size.y);
                                      canvas.moveTo(x1, y1);
                                      canvas.lineTo(x2, y2);
                                      canvas.strokePath();
                                    }
                                  }
                                },
                              )
                            : pw.Center(
                                child: pw.Text('Digitally Signed by ASM', style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue900, fontStyle: pw.FontStyle.italic)),
                              ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue900)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(pdfBytes, mimeType: 'application/pdf', name: 'AMAFHH_Bill_$formattedBillNo.pdf')],
        text: 'Hello $customerName, here is your bill No. $formattedBillNo from AMAFHH ENTERPRISES for Rs. ${totalAmount.toStringAsFixed(2)}.',
      );
    } else {
      final outputDir = await getTemporaryDirectory();
      final file = File('${outputDir.path}/AMAFHH_Bill_$formattedBillNo.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Hello $customerName, here is your bill No. $formattedBillNo from AMAFHH ENTERPRISES for Rs. ${totalAmount.toStringAsFixed(2)}.',
        subject: 'AMAFHH Invoice #$formattedBillNo',
      );
    }
  }
}
