import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/invoice_model.dart';
import '../../../data/models/client_model.dart';

class InvoicePdfService {
  // Helper para criar o rodapé padrão
  static pw.Widget _buildFooter(PdfColor textColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: textColor, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'www.yourcompany.com',
            style: pw.TextStyle(fontSize: 8, color: textColor),
          ),
          pw.Text(
            'contact@yourcompany.com',
            style: pw.TextStyle(fontSize: 8, color: textColor),
          ),
          pw.Text(
            '+1 234 567 890',
            style: pw.TextStyle(fontSize: 8, color: textColor),
          ),
        ],
      ),
    );
  }

  // Helper para criar um logotipo genérico
  static pw.Widget _buildLogo(PdfColor color, {bool isDark = false}) {
    return pw.Container(
      width: 40,
      height: 40,
      decoration: pw.BoxDecoration(
        color: isDark ? PdfColors.white : color,
        borderRadius: pw.BorderRadius.circular(20), // Circle for this style
      ),
      alignment: pw.Alignment.center,
      child: pw.Text(
        'LOGO',
        style: pw.TextStyle(
          color: isDark ? color : PdfColors.white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  // Helper para criar o campo de assinatura
  static pw.Widget _buildSignature(
    PdfColor textColor, {
    Uint8List? signatureImage,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 30, right: 40),
      width: 200,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (signatureImage != null)
            pw.Container(
              height: 50,
              width: 100,
              margin: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Image(pw.MemoryImage(signatureImage)),
            )
          else
            pw.SizedBox(height: 50),
          pw.Divider(color: textColor, thickness: 1),
          pw.SizedBox(height: 5),
          pw.Text(
            'Signature',
            style: pw.TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 1. MINIMALIST
  static Future<pw.Document> generateMinimalistPdf({
    required String invoiceNumber,
    required Client? client,
    required List<InvoiceItem> items,
    required double subtotal,
    required double tax,
    required double total,
    Uint8List? signatureImage,
    required String companyName,
    required String companyAddress,
    required String companyPhone,
    required String companyEmail,
    Uint8List? companyLogo,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(50),
        build: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    _buildLogo(PdfColors.black),
                    pw.SizedBox(width: 10),
                    pw.Text('INVOICE', style: pw.TextStyle(fontSize: 30)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      '#$invoiceNumber',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'DATE: ${DateTime.now().toIso8601String().split('T')[0]}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.Text(
              companyName,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
            ),
            pw.Text(
              '$companyAddress | $companyPhone | $companyEmail',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 10),
            pw.SizedBox(height: 40),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BILL TO: ${client?.name ?? 'Client Name'}'),
                  pw.SizedBox(height: 20),
                  pw.TableHelper.fromTextArray(
                    border: const pw.TableBorder(
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black),
                      ),
                    ),
                    data: <List<String>>[
                      <String>['DESCRIPTION', 'QTY', 'AMOUNT'],
                      ...items.map(
                        (i) => [
                          i.name,
                          '${i.quantity}',
                          '\$${i.total.toStringAsFixed(2)}',
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'TOTAL: \$${total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: _buildSignature(
                PdfColors.black,
                signatureImage: signatureImage,
              ),
            ),
            pw.SizedBox(height: 20),
            _buildFooter(PdfColors.grey700),
          ],
        ),
      ),
    );
    return pdf;
  }

  // 2. MODERN CORPORATE
  static Future<pw.Document> generateModernCorporatePdf({
    required String invoiceNumber,
    required Client? client,
    required List<InvoiceItem> items,
    required double subtotal,
    required double tax,
    required double total,
    Uint8List? signatureImage,
    required String companyName,
    required String companyAddress,
    required String companyPhone,
    required String companyEmail,
    Uint8List? companyLogo,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Column(
          children: [
            pw.Container(
              height: 80,
              color: PdfColor.fromHex('#1a202c'),
              padding: const pw.EdgeInsets.symmetric(horizontal: 40),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      _buildLogo(PdfColor.fromHex('#1a202c'), isDark: true),
                      pw.SizedBox(width: 15),
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        '#$invoiceNumber',
                        style: pw.TextStyle(color: PdfColors.white),
                      ),
                      pw.Text(
                        'DATE: ${DateTime.now().toIso8601String().split('T')[0]}',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BILL TO',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(client?.name ?? 'Client Name'),
                    pw.SizedBox(height: 30),
                    pw.TableHelper.fromTextArray(
                      headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      data: <List<String>>[
                        <String>['ITEM', 'QTY', 'TOTAL'],
                        ...items.map(
                          (i) => [
                            i.name,
                            '${i.quantity}',
                            '\$${i.total.toStringAsFixed(2)}',
                          ],
                        ),
                      ],
                    ),
                    pw.Spacer(),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'TOTAL: \$${total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(
                children: [
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: _buildSignature(
                      PdfColors.black,
                      signatureImage: signatureImage,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  _buildFooter(PdfColors.grey700),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return pdf;
  }

  // 3. ELEGANT PREMIUM (Dark)
  static Future<pw.Document> generateElegantDarkPdf({
    required String invoiceNumber,
    required Client? client,
    required List<InvoiceItem> items,
    required double subtotal,
    required double tax,
    required double total,
    Uint8List? signatureImage,
    required String companyName,
    required String companyAddress,
    required String companyPhone,
    required String companyEmail,
    Uint8List? companyLogo,
  }) async {
    final pdf = pw.Document();
    final gold = PdfColor.fromHex('#d4af37');
    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Container(
          color: PdfColor.fromHex('#111111'),
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildLogo(gold),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          color: gold,
                          fontSize: 30,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.Text(
                        '#$invoiceNumber',
                        style: pw.TextStyle(color: gold, fontSize: 12),
                      ),
                      pw.Text(
                        'DATE: ${DateTime.now().toIso8601String().split('T')[0]}',
                        style: pw.TextStyle(color: gold, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BILL TO',
                      style: pw.TextStyle(
                        color: gold,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      client?.name ?? 'Client Name',
                      style: pw.TextStyle(color: PdfColors.white),
                    ),
                    pw.SizedBox(height: 30),
                    pw.TableHelper.fromTextArray(
                      border: null,
                      headerStyle: pw.TextStyle(
                        color: gold,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      cellStyle: const pw.TextStyle(color: PdfColors.white),
                      headerDecoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: gold)),
                      ),
                      data: <List<String>>[
                        <String>['DESCRIPTION', 'QTY', 'AMOUNT'],
                        ...items.map(
                          (i) => [
                            i.name,
                            '${i.quantity}',
                            '\$${i.total.toStringAsFixed(2)}',
                          ],
                        ),
                      ],
                    ),
                    pw.Spacer(),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'TOTAL: \$${total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSignature(gold, signatureImage: signatureImage),
              _buildFooter(gold),
            ],
          ),
        ),
      ),
    );
    return pdf;
  }

  // 4. CLEAN BLUE
  static Future<pw.Document> generateCleanBluePdf({
    required String invoiceNumber,
    required Client? client,
    required List<InvoiceItem> items,
    required double subtotal,
    required double tax,
    required double total,
    Uint8List? signatureImage,
    required String companyName,
    required String companyAddress,
    required String companyPhone,
    required String companyEmail,
    Uint8List? companyLogo,
  }) async {
    final pdf = pw.Document();
    final blue = PdfColor.fromHex('#0284c7');
    final lightBlue = PdfColor.fromHex('#e0f2fe');
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: lightBlue, width: 8),
            borderRadius: pw.BorderRadius.circular(20),
          ),
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          color: blue,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        companyAddress,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        '$companyPhone | $companyEmail',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  if (companyLogo != null)
                    pw.Container(
                      width: 50,
                      height: 50,
                      child: pw.Image(pw.MemoryImage(companyLogo)),
                    )
                  else
                    _buildLogo(blue),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: blue,
                ),
              ),
              pw.SizedBox(height: 30),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'BILL TO',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(client?.name ?? 'Client Name'),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('#$invoiceNumber'),
                            pw.Text(
                              'DATE: ${DateTime.now().toIso8601String().split('T')[0]}',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    pw.TableHelper.fromTextArray(
                      headerDecoration: pw.BoxDecoration(color: lightBlue),
                      data: <List<String>>[
                        <String>['ITEM', 'QTY', 'TOTAL'],
                        ...items.map(
                          (i) => [
                            i.name,
                            '${i.quantity}',
                            '\$${i.total.toStringAsFixed(2)}',
                          ],
                        ),
                      ],
                    ),
                    pw.Spacer(),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'TOTAL: \$${total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSignature(blue, signatureImage: signatureImage),
              pw.SizedBox(height: 20),
              _buildFooter(blue),
            ],
          ),
        ),
      ),
    );
    return pdf;
  }

  // 5. COMPACT
  static Future<pw.Document> generateCompactPdf({
    required String invoiceNumber,
    required Client? client,
    required List<InvoiceItem> items,
    required double subtotal,
    required double tax,
    required double total,
    Uint8List? signatureImage,
    required String companyName,
    required String companyAddress,
    required String companyPhone,
    required String companyEmail,
    Uint8List? companyLogo,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(30),
        build: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    pw.Text(
                      companyAddress,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      companyPhone,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      companyEmail,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                if (companyLogo != null)
                  pw.Container(
                    width: 50,
                    height: 50,
                    child: pw.Image(pw.MemoryImage(companyLogo)),
                  )
                else
                  _buildLogo(PdfColors.black),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'To: ${client?.name ?? 'Client Name'}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            '#$invoiceNumber',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          pw.Text(
                            'DATE: ${DateTime.now().toIso8601String().split('T')[0]}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Divider(),
                  pw.TableHelper.fromTextArray(
                    cellHeight: 20,
                    data: <List<String>>[
                      <String>['ITEM', 'QTY', 'TOTAL'],
                      ...items.map(
                        (i) => [
                          i.name,
                          '${i.quantity}',
                          '\$${i.total.toStringAsFixed(2)}',
                        ],
                      ),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'TOTAL: \$${total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildSignature(PdfColors.black, signatureImage: signatureImage),
            pw.SizedBox(height: 20),
            _buildFooter(PdfColors.black),
          ],
        ),
      ),
    );
    return pdf;
  }

  // 6. MODERN STRIPED
  static Future<pw.Document> generateModernStripedPdf({
    required String invoiceNumber,
    required Client? client,
    required List<InvoiceItem> items,
    required double subtotal,
    required double tax,
    required double total,
    Uint8List? signatureImage,
    required String companyName,
    required String companyAddress,
    required String companyPhone,
    required String companyEmail,
    Uint8List? companyLogo,
  }) async {
    final pdf = pw.Document();
    final darkBlue = PdfColor.fromHex('#1e3a8a');
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                        color: darkBlue,
                      ),
                    ),
                    pw.Text(
                      companyAddress,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      '$companyPhone | $companyEmail',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                if (companyLogo != null)
                  pw.Container(
                    width: 50,
                    height: 50,
                    child: pw.Image(pw.MemoryImage(companyLogo)),
                  )
                else
                  _buildLogo(darkBlue),
              ],
            ),
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 30,
                fontWeight: pw.FontWeight.bold,
                color: darkBlue,
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('BILL TO: ${client?.name ?? 'Client Name'}'),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '#$invoiceNumber',
                        style: pw.TextStyle(color: PdfColors.grey600),
                      ),
                      pw.Text(
                        'DATE: ${DateTime.now().toIso8601String().split('T')[0]}',
                        style: const pw.TextStyle(
                          color: PdfColors.grey600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.TableHelper.fromTextArray(
                    headerDecoration: pw.BoxDecoration(color: darkBlue),
                    headerStyle: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    oddRowDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    data: <List<String>>[
                      <String>['DESCRIPTION', 'QTY', 'TOTAL'],
                      ...items.map(
                        (i) => [
                          i.name,
                          '${i.quantity}',
                          '\$${i.total.toStringAsFixed(2)}',
                        ],
                      ),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      'TOTAL: \$${total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildSignature(darkBlue, signatureImage: signatureImage),
            pw.SizedBox(height: 20),
            _buildFooter(darkBlue),
          ],
        ),
      ),
    );
    return pdf;
  }

  // 7. SIMPLE GREY
  static Future<pw.Document> generateSimpleGreyPdf({
    required String invoiceNumber,
    required Client? client,
    required List<InvoiceItem> items,
    required double subtotal,
    required double tax,
    required double total,
    Uint8List? signatureImage,
    required String companyName,
    required String companyAddress,
    required String companyPhone,
    required String companyEmail,
    Uint8List? companyLogo,
  }) async {
    final pdf = pw.Document();
    final lightGrey = PdfColor.fromHex('#f3f4f6');
    final darkGrey = PdfColor.fromHex('#4b5563');
    final midGrey = PdfColor.fromHex('#9ca3af');

    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Column(
          children: [
            // Header
            pw.Container(
              color: lightGrey,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 30,
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      pw.Text(
                        companyAddress,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        '$companyPhone | $companyEmail',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: darkGrey,
                        ),
                      ),
                    ],
                  ),
                  if (companyLogo != null)
                    pw.Container(
                      width: 50,
                      height: 50,
                      child: pw.Image(pw.MemoryImage(companyLogo)),
                    )
                  else
                    _buildLogo(darkGrey),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Info Bar
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 40),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'INVOICE NO.',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: midGrey,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        invoiceNumber,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'DATE: ${DateTime.now().toIso8601String().split('T')[0]}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '<Payment terms (due on receipt, due in X days)>',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontStyle: pw.FontStyle.italic,
                          color: midGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Bill To / Ship To
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 40),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILL TO',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: darkGrey,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Divider(color: midGrey, thickness: 0.5),
                        pw.Text(
                          client?.name ?? '<Contact Name>',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          '<Client Company Name>',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          '<Address>',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          client?.email ?? '<Email>',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 40),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SHIP TO',
                          style: pw.TextStyle(
                            fontSize: 8,
                            color: darkGrey,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Divider(color: midGrey, thickness: 0.5),
                        pw.Text(
                          '<Name / Dept>',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          '<Client Company Name>',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          '<Address>',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Table
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 40),
              child: pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: midGrey, width: 0.5),
                headerDecoration: pw.BoxDecoration(color: midGrey),
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
                data: <List<String>>[
                  <String>['DESCRIPTION', 'QTY', 'UNIT PRICE', 'TOTAL'],
                  ...items.map(
                    (i) => [
                      i.name,
                      '${i.quantity}',
                      '\$${i.unitPrice.toStringAsFixed(2)}',
                      '\$${i.total.toStringAsFixed(2)}',
                    ],
                  ),
                  // Add empty rows if needed to match look, but for dynamic content, just listing items is better
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Totals
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 40),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 200,
                        child: pw.Column(
                          children: [
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'SUBTOTAL',
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                                pw.Text(
                                  subtotal.toStringAsFixed(2),
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ],
                            ),
                            pw.Divider(color: midGrey, thickness: 0.5),
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'DISCOUNT',
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                                pw.Text(
                                  '0.00',
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ],
                            ),
                            pw.Divider(color: midGrey, thickness: 0.5),
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'TAX',
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                                pw.Text(
                                  tax.toStringAsFixed(2),
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ],
                            ),
                            pw.Divider(color: midGrey, thickness: 0.5),
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'SHIPPING/HANDLING',
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                                pw.Text(
                                  '0.00',
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 5),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Container(
                        width: 200,
                        color: darkGrey,
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Balance Due',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              '\$${total.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: _buildSignature(darkGrey, signatureImage: signatureImage),
            ),

            // Remarks
            pw.Padding(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Row(
                children: [
                  pw.Text(
                    'Remarks / Payment Instructions:',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),

            // _buildFooter(darkGrey), // Footer is not in the design image, but usually allowed. I'll omit to match image exactly or keep it? The user said "exactly like the image". The image ends there. I will leave the standard footer for consistency or just small margin.
          ],
        ),
      ),
    );
    return pdf;
  }
}
