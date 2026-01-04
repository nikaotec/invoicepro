import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart'; // For previewing/printing
import 'package:pdf/widgets.dart' as pw;
import 'package:signature/signature.dart';
import '../../providers/business_profile_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/invoice_model.dart' as ui_model;
import '../../../data/models/client_model.dart';
import '../../../domain/entities/invoice.dart' as domain;
import '../../services/invoice_pdf_service.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/invoice_repository_provider.dart';

enum DocumentStyle {
  minimalist,
  modernCorporate,
  elegantDark,
  cleanBlue,
  compact,
  modernStriped,
  simpleGrey,
}

class InvoicePreviewScreen extends ConsumerStatefulWidget {
  final String invoiceNumber;
  final Client? client;
  final List<ui_model.InvoiceItem> items;
  final double subtotal;
  final double tax;
  final double total;

  const InvoicePreviewScreen({
    super.key,
    required this.invoiceNumber,
    this.client,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  @override
  ConsumerState<InvoicePreviewScreen> createState() =>
      _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends ConsumerState<InvoicePreviewScreen> {
  DocumentStyle _selectedStyle = DocumentStyle.minimalist;
  bool _isSaved = false;
  Uint8List? _signatureBytes;

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _saveInvoice() async {
    if (_isSaved) return;

    final clientId = widget.client?.id ?? '';
    if (clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client is required')),
      );
      return;
    }

    final now = DateTime.now();
    
    // Convert UI items to domain items
    final domainItems = widget.items.map((item) {
      return domain.InvoiceItem(
        id: item.id,
        description: item.name,
        quantity: item.quantity.toDouble(),
        unitPrice: item.unitPrice,
        total: item.total,
      );
    }).toList();

    // Create domain invoice
    final domainInvoice = domain.Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clientId: clientId,
      invoiceNumber: widget.invoiceNumber,
      date: now,
      dueDate: now.add(const Duration(days: 30)),
      status: domain.InvoiceStatus.draft,
      items: domainItems,
      subtotal: widget.subtotal,
      taxRate: widget.tax / widget.subtotal, // Calculate tax rate
      taxAmount: widget.tax,
      discountAmount: 0.0,
      total: widget.total,
      currency: 'USD',
      notes: null,
      createdAt: now,
      updatedAt: now,
    );

    // Save to database using repository
    final repository = ref.read(invoiceRepositoryProvider);
    final result = await repository.createInvoice(domainInvoice);

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result.error!.message}')),
      );
      return;
    }

    // Refresh invoice list
    await ref.read(invoiceProvider.notifier).loadInvoices();

    _isSaved = true;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice saved successfully')),
      );
    }
  }

  Future<void> _printPdf() async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preparing PDF...')));

      // Save invoice first
      await _saveInvoice();

      final pdf = await _generatePdf();

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: '${widget.invoiceNumber}.pdf',
      );
    } catch (e) {
      print('Error printing PDF: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error printing PDF: $e')));
    }
  }

  Future<void> _sharePdf() async {
    // Save invoice first
    await _saveInvoice();

    final pdf = await _generatePdf();
    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${widget.invoiceNumber}.pdf',
    );
  }

  Future<void> _showSignatureDialog() async {
    _signatureController.clear();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Draw Signature'),
        content: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          width: 300,
          height: 200,
          child: Signature(
            controller: _signatureController,
            backgroundColor: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _signatureController.clear();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_signatureController.isNotEmpty) {
                final signature = await _signatureController.toPngBytes();
                setState(() {
                  _signatureBytes = signature;
                });
              }
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<pw.Document> _generatePdf() async {
    print('🎨 Generating PDF with style: $_selectedStyle');
    final businessProfile = ref.read(businessProfileProvider);

    switch (_selectedStyle) {
      case DocumentStyle.minimalist:
        print('✅ Using Minimalist template');
        return InvoicePdfService.generateMinimalistPdf(
          invoiceNumber: widget.invoiceNumber,
          client: widget.client,
          items: widget.items,
          subtotal: widget.subtotal,
          tax: widget.tax,
          total: widget.total,
          signatureImage: _signatureBytes,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case DocumentStyle.modernCorporate:
        print('✅ Using Modern Corporate template');
        return InvoicePdfService.generateModernCorporatePdf(
          invoiceNumber: widget.invoiceNumber,
          client: widget.client,
          items: widget.items,
          subtotal: widget.subtotal,
          tax: widget.tax,
          total: widget.total,
          signatureImage: _signatureBytes,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case DocumentStyle.elegantDark:
        print('✅ Using Elegant Dark template');
        return InvoicePdfService.generateElegantDarkPdf(
          invoiceNumber: widget.invoiceNumber,
          client: widget.client,
          items: widget.items,
          subtotal: widget.subtotal,
          tax: widget.tax,
          total: widget.total,
          signatureImage: _signatureBytes,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case DocumentStyle.cleanBlue:
        print('✅ Using Clean Blue template');
        return InvoicePdfService.generateCleanBluePdf(
          invoiceNumber: widget.invoiceNumber,
          client: widget.client,
          items: widget.items,
          subtotal: widget.subtotal,
          tax: widget.tax,
          total: widget.total,
          signatureImage: _signatureBytes,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case DocumentStyle.compact:
        print('✅ Using Compact template');
        return InvoicePdfService.generateCompactPdf(
          invoiceNumber: widget.invoiceNumber,
          client: widget.client,
          items: widget.items,
          subtotal: widget.subtotal,
          tax: widget.tax,
          total: widget.total,
          signatureImage: _signatureBytes,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case DocumentStyle.modernStriped:
        print('✅ Using Modern Striped template');
        return InvoicePdfService.generateModernStripedPdf(
          invoiceNumber: widget.invoiceNumber,
          client: widget.client,
          items: widget.items,
          subtotal: widget.subtotal,
          tax: widget.tax,
          total: widget.total,
          signatureImage: _signatureBytes,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case DocumentStyle.simpleGrey:
        print('✅ Using Simple Grey template');
        return InvoicePdfService.generateSimpleGreyPdf(
          invoiceNumber: widget.invoiceNumber,
          client: widget.client,
          items: widget.items,
          subtotal: widget.subtotal,
          tax: widget.tax,
          total: widget.total,
          signatureImage: _signatureBytes,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.background;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark),

            // Main Content - Document Preview
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
                child: Center(child: _buildDocumentPreview(isDark)),
              ),
            ),

            // Footer - Fixed Bottom
            _buildFooter(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor(isDark).withOpacity(0.9),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),

          // Title
          Text(
            'Preview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),

          // Edit Button
          InkWell(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Text(
                'Edit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview(bool isDark) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -5,
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 210 / 297, // A4 ratio
        child: _buildDocumentContent(),
      ),
    );
  }

  Widget _buildDocumentContent() {
    switch (_selectedStyle) {
      case DocumentStyle.minimalist:
        return _buildMinimalistDocument();
      case DocumentStyle.modernCorporate:
        return _buildModernCorporateDocument();
      case DocumentStyle.elegantDark:
        return _buildElegantDarkDocument();
      case DocumentStyle.cleanBlue:
        return _buildCleanBlueDocument();
      case DocumentStyle.compact:
        return _buildCompactDocument();
      case DocumentStyle.modernStriped:
        return _buildModernStripedDocument();
      case DocumentStyle.simpleGrey:
        return _buildSimpleGreyDocument();
    }
  }

  Widget _buildSignaturePreview(Color textColor) {
    return InkWell(
      onTap: _showSignatureDialog,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 120, // Reduced from 200 to fit scale
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_signatureBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Image.memory(
                        _signatureBytes!,
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                    )
                  else
                    const SizedBox(height: 30),
                  Divider(color: textColor, thickness: 1),
                  const SizedBox(height: 4),
                  Text(
                    'Signature (Tap to Sign)',
                    style: TextStyle(
                      fontSize: 7,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalistDocument() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INVOICE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
          const Divider(thickness: 0.5),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bill To:',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.client?.name ?? 'N/A',
                    style: const TextStyle(fontSize: 8),
                  ),
                ],
              ),
              Text(widget.invoiceNumber, style: const TextStyle(fontSize: 7)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(8),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Description',
                  style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Amount',
                  style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ...widget.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.name, style: const TextStyle(fontSize: 7)),
                  Text(
                    '\$${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 7),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: \$${widget.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          _buildSignaturePreview(Colors.black),
        ],
      ),
    );
  }

  Widget _buildModernCorporateDocument() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF1e293b),
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'INVOICE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '#${widget.invoiceNumber}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Client Details',
                  style: TextStyle(fontSize: 8, color: Colors.grey),
                ),
                Text(
                  widget.client?.name ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  color: const Color(0xFF334155),
                  padding: const EdgeInsets.all(6),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Item',
                          style: TextStyle(
                            fontSize: 7,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          'Qty',
                          style: TextStyle(
                            fontSize: 7,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          'Total',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 7,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...widget.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontSize: 7),
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(fontSize: 7),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '\$${item.total.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Grand Total: \$${widget.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildSignaturePreview(const Color(0xFF1e293b)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantDarkDocument() {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFfacc15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PREMIUM SERVICES',
                  style: TextStyle(
                    fontSize: 6,
                    letterSpacing: 2,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Invoice',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CLIENT',
                            style: TextStyle(
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.client?.name ?? 'N/A',
                            style: const TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'INVOICE NO',
                            style: TextStyle(
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.invoiceNumber,
                            style: const TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...widget.items.map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.name, style: const TextStyle(fontSize: 8)),
                        Text(
                          '\$${item.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL DUE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${widget.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF854d0e),
                      ),
                    ),
                  ],
                ),
                _buildSignaturePreview(const Color(0xFF854d0e)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanBlueDocument() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'INV',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invoice',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    '#${widget.invoiceNumber}',
                    style: const TextStyle(fontSize: 7),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BILL TO',
                      style: TextStyle(
                        fontSize: 6,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.client?.name ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'AMOUNT DUE',
                      style: TextStyle(
                        fontSize: 6,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${widget.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.blue, width: 2)),
            ),
            padding: const EdgeInsets.only(bottom: 4),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...widget.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.name, style: const TextStyle(fontSize: 7)),
                  Text(
                    '\$${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 7),
                  ),
                ],
              ),
            ),
          ),
          _buildSignaturePreview(const Color(0xFF1e3a8a)), // Dark Blue
        ],
      ),
    );
  }

  Widget _buildCompactDocument() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INVOICE ${widget.invoiceNumber}',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateTime.now().toString().split(' ')[0],
                style: const TextStyle(fontSize: 6),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'To: ${widget.client?.name ?? 'N/A'}',
            style: const TextStyle(fontSize: 6),
          ),
          const Divider(thickness: 0.5),
          ...widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text('${index + 1}.', style: const TextStyle(fontSize: 6)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(item.name, style: const TextStyle(fontSize: 6)),
                  ),
                  Text(
                    '\$${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 6),
                  ),
                ],
              ),
            );
          }),
          const Spacer(),
          const Divider(thickness: 0.5),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'TOTAL: \$${widget.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
            ),
          ),
          _buildSignaturePreview(Colors.black),
        ],
      ),
    );
  }

  Widget _buildModernStripedDocument() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INVOICE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4f46e5),
                    ),
                  ),
                  Text(
                    'No: ${widget.invoiceNumber}',
                    style: const TextStyle(fontSize: 7),
                  ),
                ],
              ),
              Container(
                height: 30,
                width: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF4f46e5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'LOGO',
                    style: TextStyle(color: Colors.white, fontSize: 5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            color: const Color(0xFF4f46e5),
            padding: const EdgeInsets.all(6),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 7,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 20,
                  child: Text(
                    'Qty',
                    style: TextStyle(
                      fontSize: 7,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    'Total',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 7,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              color: index % 2 == 1 ? Colors.grey[100] : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item.name, style: const TextStyle(fontSize: 7)),
                  ),
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontSize: 7),
                    ),
                  ),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '\$${item.total.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 7),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Spacer(),
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes:',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Thank you!',
                      style: TextStyle(
                        fontSize: 6,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${widget.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          _buildSignaturePreview(const Color(0xFF4f46e5)),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Style Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Document Style',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                'View all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Style Options
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStyleOption(
                  DocumentStyle.minimalist,
                  'Minimalist',
                  Icons.space_bar,
                  isDark,
                ),
                const SizedBox(width: 12),
                _buildStyleOption(
                  DocumentStyle.modernCorporate,
                  'Modern Corp',
                  Icons.corporate_fare,
                  isDark,
                ),
                const SizedBox(width: 12),
                _buildStyleOption(
                  DocumentStyle.elegantDark,
                  'Elegant Dark',
                  Icons.diamond,
                  isDark,
                ),
                const SizedBox(width: 12),
                _buildStyleOption(
                  DocumentStyle.cleanBlue,
                  'Clean Blue',
                  Icons.water_drop,
                  isDark,
                ),
                const SizedBox(width: 12),
                _buildStyleOption(
                  DocumentStyle.compact,
                  'Compact',
                  Icons.compress,
                  isDark,
                ),
                const SizedBox(width: 12),
                _buildStyleOption(
                  DocumentStyle.modernStriped,
                  'Modern Striped',
                  Icons.view_headline,
                  isDark,
                ),
                const SizedBox(width: 12),
                _buildStyleOption(
                  DocumentStyle.simpleGrey,
                  'Simple Grey',
                  Icons.article,
                  isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _sharePdf,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[200]!,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.share, size: 20),
                  label: const Text(
                    'Share',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _printPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.primary.withOpacity(0.3),
                  ),
                  icon: const Icon(Icons.print, size: 20),
                  label: const Text(
                    'Print PDF',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStyleOption(
    DocumentStyle style,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _selectedStyle == style;

    return GestureDetector(
      onTap: () {
        print('👆 User selected template: $style');
        setState(() {
          _selectedStyle = style;
        });
        print('✅ Template changed to: $_selectedStyle');
      },
      child: Column(
        children: [
          Container(
            width: 100,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50]),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey[200]!),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                // Style-specific thumbnail preview
                _buildStyleThumbnail(style, isDark),
                if (isSelected)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Color backgroundColor(bool isDark) {
    return isDark ? AppColors.backgroundDark : AppColors.background;
  }

  Widget _buildSimpleGreyDocument() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFFf3f4f6),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '<Your Company Name>',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 8,
                      ),
                    ),
                    Text('<Your address>', style: TextStyle(fontSize: 6)),
                    Text(
                      '<Your contact details>',
                      style: TextStyle(fontSize: 6),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'INVOICE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4b5563),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4b5563),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'LOGO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Info Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INVOICE NO.',
                      style: TextStyle(
                        fontSize: 6,
                        color: Color(0xFF9ca3af),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'DATE: ${DateTime.now().toIso8601String().split('T')[0]}',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '<Payment terms (due on receipt)>',
                      style: TextStyle(
                        fontSize: 6,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF9ca3af),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Bill To / Ship To
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BILL TO',
                        style: TextStyle(
                          fontSize: 6,
                          color: Color(0xFF4b5563),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(color: Color(0xFF9ca3af), thickness: 0.5),
                      Text(
                        widget.client?.name ?? '<Contact Name>',
                        style: const TextStyle(fontSize: 6),
                      ),
                      const Text(
                        '<Client Company Name>',
                        style: TextStyle(fontSize: 6),
                      ),
                      const Text('<Address>', style: TextStyle(fontSize: 6)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SHIP TO',
                        style: TextStyle(
                          fontSize: 6,
                          color: Color(0xFF4b5563),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(color: Color(0xFF9ca3af), thickness: 0.5),
                      Text('<Name / Dept>', style: TextStyle(fontSize: 6)),
                      Text(
                        '<Client Company Name>',
                        style: TextStyle(fontSize: 6),
                      ),
                      Text('<Address>', style: TextStyle(fontSize: 6)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Table
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF9ca3af), width: 0.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    color: const Color(0xFF9ca3af),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'DESCRIPTION',
                            style: TextStyle(
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'QTY',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'UNIT PRICE',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'TOTAL',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...widget.items.map(
                    (item) => Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFF9ca3af), width: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              item.name,
                              style: const TextStyle(fontSize: 6),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${item.quantity}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 6),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.unitPrice.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 6),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.total.toStringAsFixed(2),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Totals
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 120,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SUBTOTAL', style: TextStyle(fontSize: 6)),
                          Text(
                            widget.subtotal.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 6),
                          ),
                        ],
                      ),
                      const Divider(thickness: 0.5, color: Color(0xFF9ca3af)),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('DISCOUNT', style: TextStyle(fontSize: 6)),
                          Text('0.00', style: TextStyle(fontSize: 6)),
                        ],
                      ),
                      const Divider(thickness: 0.5, color: Color(0xFF9ca3af)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TAX', style: TextStyle(fontSize: 6)),
                          Text(
                            widget.tax.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 6),
                          ),
                        ],
                      ),
                      const Divider(thickness: 0.5, color: Color(0xFF9ca3af)),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SHIPPING/HANDLING',
                            style: TextStyle(fontSize: 6),
                          ),
                          Text('0.00', style: TextStyle(fontSize: 6)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 4,
                        ),
                        color: const Color(0xFF4b5563),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Balance Due',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 6,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${widget.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _buildSignaturePreview(const Color(0xFF4b5563)),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Remarks / Payment Instructions:',
                  style: TextStyle(fontSize: 6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleThumbnail(DocumentStyle style, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;

    switch (style) {
      case DocumentStyle.simpleGrey:
        return Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 10,
                color: Colors.grey[200],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(width: 20, height: 2, color: Colors.grey[400]),
                  const Spacer(),
                  Container(width: 20, height: 2, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                width: double.infinity,
                height: 4,
                color: Colors.grey[300],
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Container(width: 40, height: 6, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      case DocumentStyle.minimalist:
        return Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 3,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: double.infinity,
                height: 0.5,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 3),
              Container(
                width: double.infinity,
                height: 6,
                color: Colors.grey[100],
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Container(width: 25, height: 2, color: Colors.grey[700]),
              ),
            ],
          ),
        );

      case DocumentStyle.modernCorporate:
        return Column(
          children: [
            Container(
              width: double.infinity,
              height: 12,
              color: const Color(0xFF1e293b),
              child: Center(
                child: Container(width: 30, height: 2, color: Colors.white),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 4,
                      color: const Color(0xFF334155),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 30,
                        height: 2,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      case DocumentStyle.elegantDark:
        return Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 25,
                height: 25,
                decoration: const BoxDecoration(
                  color: Color(0xFFfacc15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 30, height: 2, color: Colors.grey[400]),
                  const Spacer(),
                  Container(
                    width: 25,
                    height: 3,
                    color: const Color(0xFF854d0e),
                  ),
                ],
              ),
            ),
          ],
        );

      case DocumentStyle.cleanBlue:
        return Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(width: 20, height: 2, color: Colors.blue),
                ],
              ),
              const SizedBox(height: 3),
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Spacer(),
              Container(width: double.infinity, height: 1, color: Colors.blue),
            ],
          ),
        );

      case DocumentStyle.compact:
        return Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 35, height: 2, color: Colors.grey[700]),
              const SizedBox(height: 2),
              Container(
                width: double.infinity,
                height: 0.5,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 2),
              ...List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.grey[200],
                  ),
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Container(width: 25, height: 2, color: Colors.grey[700]),
              ),
            ],
          ),
        );

      case DocumentStyle.modernStriped:
        return Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 30,
                    height: 2,
                    color: const Color(0xFF4f46e5),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4f46e5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                width: double.infinity,
                height: 4,
                color: const Color(0xFF4f46e5),
              ),
              const SizedBox(height: 1),
              Container(
                width: double.infinity,
                height: 2,
                color: Colors.grey[100],
              ),
              const SizedBox(height: 1),
              Container(width: double.infinity, height: 2, color: Colors.white),
              const Spacer(),
              Container(width: 25, height: 2, color: Colors.grey[700]),
            ],
          ),
        );
    }
  }
}
