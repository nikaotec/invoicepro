import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../providers/invoice_repository_provider.dart';
import '../../providers/client_repository_provider.dart';
import '../../providers/business_profile_provider.dart';
import '../../../domain/entities/invoice.dart' as domain;
import '../../../domain/entities/client.dart' as domain_client;
import '../../../data/models/invoice_model.dart' as ui_model;
import '../../../data/models/client_model.dart' as ui_client;
import '../../services/invoice_pdf_service.dart';

enum InvoiceTemplate {
  minimalist,
  modernCorporate,
  elegantDark,
  cleanBlue,
  compact,
  modernStriped,
  simpleGrey,
}

class InvoicePdfPreviewScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoicePdfPreviewScreen({
    super.key,
    required this.invoiceId,
  });

  @override
  ConsumerState<InvoicePdfPreviewScreen> createState() =>
      _InvoicePdfPreviewScreenState();
}

class _InvoicePdfPreviewScreenState
    extends ConsumerState<InvoicePdfPreviewScreen> {
  domain.Invoice? _invoice;
  domain_client.Client? _client;
  bool _isLoading = true;
  String? _error;
  InvoiceTemplate _selectedTemplate = InvoiceTemplate.modernCorporate;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(invoiceRepositoryProvider);
      final result = await repository.getInvoiceById(widget.invoiceId);

      if (result.error != null) {
        setState(() {
          _error = result.error!.message;
          _isLoading = false;
        });
        return;
      }

      if (result.data == null) {
        setState(() {
          _error = 'Invoice not found';
          _isLoading = false;
        });
        return;
      }

      _invoice = result.data;

      // Load client details
      if (_invoice != null) {
        final clientRepository = ref.read(clientRepositoryProvider);
        final clientResult =
            await clientRepository.getClientById(_invoice!.clientId);

        if (clientResult.data != null) {
          _client = clientResult.data;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _decreaseZoom() {
    setState(() {
      _zoomLevel = (_zoomLevel - 0.1).clamp(0.5, 2.0);
    });
  }

  void _increaseZoom() {
    setState(() {
      _zoomLevel = (_zoomLevel + 0.1).clamp(0.5, 2.0);
    });
  }

  String _getDueStatusText() {
    if (_invoice == null) return '';
    final now = DateTime.now();
    final dueDate = _invoice!.dueDate;
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return 'Overdue by ${-difference} days';
    } else if (difference == 0) {
      return 'Due today';
    } else {
      return 'Due in $difference days';
    }
  }

  Color _getDueStatusColor(bool isDark) {
    if (_invoice == null) return Colors.orange;
    final now = DateTime.now();
    final dueDate = _invoice!.dueDate;
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return Colors.red;
    } else if (difference <= 3) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _invoice == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text(
            _error ?? 'Invoice not found',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    final businessProfile = ref.watch(businessProfileProvider);
    final businessName = businessProfile.name;
    final businessAddress = businessProfile.address;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C111A) : const Color(0xFFF5F5F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark, businessName),

            // Status & Zoom Controls
            _buildStatusAndZoomBar(context, isDark),

            // Main Content - Preview Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // PDF Preview
                    _buildPdfPreview(context, isDark, businessName, businessAddress),
                  ],
                ),
              ),
            ),

            // Template Carousel - Fixed at bottom
            _buildTemplateCarousel(context, isDark),

            // Bottom Actions
            _buildBottomActions(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, String businessName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? Colors.grey[200] : Colors.grey[800],
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Column(
            children: [
              Text(
                'Invoice #${_invoice!.invoiceNumber}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                businessName,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              // TODO: Navigate to edit screen
              Navigator.of(context).pop();
            },
            child: Text(
              'Edit',
              style: TextStyle(
                color: const Color(0xFF135BEC),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAndZoomBar(BuildContext context, bool isDark) {
    final statusColor = _getDueStatusColor(isDark);
    final statusText = _getDueStatusText();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(isDark ? 0.3 : 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.pending_actions,
                  size: 14,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Zoom Controls
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.remove,
                    size: 20,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                  ),
                  onPressed: _decreaseZoom,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                Container(
                  width: 48,
                  alignment: Alignment.center,
                  child: Text(
                    '${(_zoomLevel * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    size: 20,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                  ),
                  onPressed: _increaseZoom,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPreview(
    BuildContext context,
    bool isDark,
    String businessName,
    String businessAddress,
  ) {
    if (_invoice == null || _client == null) {
      return const SizedBox.shrink();
    }

    // Convert domain models to UI models for PDF service
    final uiClient = ui_client.Client(
      id: _client!.id,
      name: _client!.name,
      company: (_client!.address != null && _client!.address!.isNotEmpty) 
          ? _client!.address! 
          : _client!.name,
      email: _client!.email,
      status: ui_client.ClientStatus.active,
      totalBilled: 0.0,
      lastActivityOrInvoice: '',
      initials: _client!.name.isNotEmpty
          ? _client!.name.split(' ').map((w) => w[0]).take(2).join().toUpperCase()
          : '??',
      avatarGradient: [const Color(0xFFE0E7FF), const Color(0xFFDBEAFE)],
    );

    final uiItems = _invoice!.items.map((item) {
      return ui_model.InvoiceItem(
        id: item.id,
        name: item.description,
        quantity: item.quantity.toInt(),
        unitPrice: item.unitPrice,
      );
    }).toList();

    final businessProfile = ref.read(businessProfileProvider);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: PdfPreview(
          build: (format) async {
            final pdf = await _generatePdfDocument(
              uiClient: uiClient,
              uiItems: uiItems,
              businessProfile: businessProfile,
            );
            return pdf.save();
          },
          allowPrinting: false,
          allowSharing: false,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          initialPageFormat: PdfPageFormat.a4,
          maxPageWidth: 340 * _zoomLevel,
        ),
      ),
    );
  }

  Future<pw.Document> _generatePdfDocument({
    required ui_client.Client uiClient,
    required List<ui_model.InvoiceItem> uiItems,
    required dynamic businessProfile,
  }) async {
    switch (_selectedTemplate) {
      case InvoiceTemplate.minimalist:
        return InvoicePdfService.generateMinimalistPdf(
          invoiceNumber: _invoice!.invoiceNumber,
          client: uiClient,
          items: uiItems,
          subtotal: _invoice!.subtotal,
          tax: _invoice!.taxAmount,
          total: _invoice!.total,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case InvoiceTemplate.modernCorporate:
        return InvoicePdfService.generateModernCorporatePdf(
          invoiceNumber: _invoice!.invoiceNumber,
          client: uiClient,
          items: uiItems,
          subtotal: _invoice!.subtotal,
          tax: _invoice!.taxAmount,
          total: _invoice!.total,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case InvoiceTemplate.elegantDark:
        return InvoicePdfService.generateElegantDarkPdf(
          invoiceNumber: _invoice!.invoiceNumber,
          client: uiClient,
          items: uiItems,
          subtotal: _invoice!.subtotal,
          tax: _invoice!.taxAmount,
          total: _invoice!.total,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case InvoiceTemplate.cleanBlue:
        return InvoicePdfService.generateCleanBluePdf(
          invoiceNumber: _invoice!.invoiceNumber,
          client: uiClient,
          items: uiItems,
          subtotal: _invoice!.subtotal,
          tax: _invoice!.taxAmount,
          total: _invoice!.total,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case InvoiceTemplate.compact:
        return InvoicePdfService.generateCompactPdf(
          invoiceNumber: _invoice!.invoiceNumber,
          client: uiClient,
          items: uiItems,
          subtotal: _invoice!.subtotal,
          tax: _invoice!.taxAmount,
          total: _invoice!.total,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case InvoiceTemplate.modernStriped:
        return InvoicePdfService.generateModernStripedPdf(
          invoiceNumber: _invoice!.invoiceNumber,
          client: uiClient,
          items: uiItems,
          subtotal: _invoice!.subtotal,
          tax: _invoice!.taxAmount,
          total: _invoice!.total,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case InvoiceTemplate.simpleGrey:
        return InvoicePdfService.generateSimpleGreyPdf(
          invoiceNumber: _invoice!.invoiceNumber,
          client: uiClient,
          items: uiItems,
          subtotal: _invoice!.subtotal,
          tax: _invoice!.taxAmount,
          total: _invoice!.total,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
    }
  }

  Widget _buildTemplateCarousel(BuildContext context, bool isDark) {
    final templates = InvoiceTemplate.values;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Templates',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.builder(
              controller: ScrollController(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                final isSelected = template == _selectedTemplate;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTemplate = template;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF135BEC).withOpacity(0.1)
                            : (isDark ? Colors.grey[800] : Colors.grey[50]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF135BEC)
                              : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Thumbnail Preview
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(11),
                              ),
                              child: _buildTemplateThumbnail(
                                template,
                                isSelected,
                                isDark,
                              ),
                            ),
                          ),
                          // Template Name
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 6,
                            ),
                            child: Text(
                              _getTemplateName(template),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF135BEC)
                                    : (isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[700]),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateThumbnail(
    InvoiceTemplate template,
    bool isSelected,
    bool isDark,
  ) {
    if (_invoice == null || _client == null) {
      return Container(
        color: isDark ? Colors.grey[900]! : Colors.grey[100]!,
        child: Center(
          child: Icon(
            _getTemplateIcon(template),
            color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
            size: 24,
          ),
        ),
      );
    }

    // Convert domain models to UI models for PDF service
    final uiClient = ui_client.Client(
      id: _client!.id,
      name: _client!.name,
      company: (_client!.address != null && _client!.address!.isNotEmpty)
          ? _client!.address!
          : _client!.name,
      email: _client!.email,
      status: ui_client.ClientStatus.active,
      totalBilled: 0.0,
      lastActivityOrInvoice: '',
      initials: _client!.name.isNotEmpty
          ? _client!.name
              .split(' ')
              .map((w) => w[0])
              .take(2)
              .join()
              .toUpperCase()
          : '??',
      avatarGradient: [const Color(0xFFE0E7FF), const Color(0xFFDBEAFE)],
    );

    final uiItems = _invoice!.items.map((item) {
      return ui_model.InvoiceItem(
        id: item.id,
        name: item.description,
        quantity: item.quantity.toInt(),
        unitPrice: item.unitPrice,
      );
    }).toList();

    final businessProfile = ref.read(businessProfileProvider);

    // Generate thumbnail PDF for this template
    return FutureBuilder<pw.Document>(
      future: _generateThumbnailPdf(
        template: template,
        uiClient: uiClient,
        uiItems: uiItems,
        businessProfile: businessProfile,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSelected
                        ? const Color(0xFF135BEC)
                        : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            color: isDark ? Colors.grey[900]! : Colors.grey[100]!,
            child: Center(
              child: Icon(
                _getTemplateIcon(template),
                color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                size: 24,
              ),
            ),
          );
        }

        return Container(
          color: Colors.white,
          child: PdfPreview(
            build: (format) async => snapshot.data!.save(),
            allowPrinting: false,
            allowSharing: false,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            initialPageFormat: PdfPageFormat.a4,
            maxPageWidth: 100,
            padding: EdgeInsets.zero,
          ),
        );
      },
    );
  }

  Future<pw.Document> _generateThumbnailPdf({
    required InvoiceTemplate template,
    required ui_client.Client uiClient,
    required List<ui_model.InvoiceItem> uiItems,
    required dynamic businessProfile,
  }) async {
    switch (template) {
      case InvoiceTemplate.minimalist:
        return InvoicePdfService.generateMinimalistPdf(
          invoiceNumber: _invoice!.invoiceNumber,
          client: uiClient,
          items: uiItems,
          subtotal: _invoice!.subtotal,
          tax: _invoice!.taxAmount,
          total: _invoice!.total,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case InvoiceTemplate.modernCorporate:
        return InvoicePdfService.generateModernCorporatePdf(
          invoiceNumber: _invoice!.invoiceNumber,
          client: uiClient,
          items: uiItems,
          subtotal: _invoice!.subtotal,
          tax: _invoice!.taxAmount,
          total: _invoice!.total,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case InvoiceTemplate.elegantDark:
        return InvoicePdfService.generateElegantDarkPdf(
          invoiceNumber: _invoice!.invoiceNumber,
          client: uiClient,
          items: uiItems,
          subtotal: _invoice!.subtotal,
          tax: _invoice!.taxAmount,
          total: _invoice!.total,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case InvoiceTemplate.cleanBlue:
        return InvoicePdfService.generateCleanBluePdf(
          invoiceNumber: _invoice!.invoiceNumber,
          client: uiClient,
          items: uiItems,
          subtotal: _invoice!.subtotal,
          tax: _invoice!.taxAmount,
          total: _invoice!.total,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case InvoiceTemplate.compact:
        return InvoicePdfService.generateCompactPdf(
          invoiceNumber: _invoice!.invoiceNumber,
          client: uiClient,
          items: uiItems,
          subtotal: _invoice!.subtotal,
          tax: _invoice!.taxAmount,
          total: _invoice!.total,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case InvoiceTemplate.modernStriped:
        return InvoicePdfService.generateModernStripedPdf(
          invoiceNumber: _invoice!.invoiceNumber,
          client: uiClient,
          items: uiItems,
          subtotal: _invoice!.subtotal,
          tax: _invoice!.taxAmount,
          total: _invoice!.total,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
      case InvoiceTemplate.simpleGrey:
        return InvoicePdfService.generateSimpleGreyPdf(
          invoiceNumber: _invoice!.invoiceNumber,
          client: uiClient,
          items: uiItems,
          subtotal: _invoice!.subtotal,
          tax: _invoice!.taxAmount,
          total: _invoice!.total,
          companyName: businessProfile.name,
          companyAddress: businessProfile.address,
          companyPhone: businessProfile.phone,
          companyEmail: businessProfile.email,
          companyLogo: businessProfile.logoBytes,
        );
    }
  }

  IconData _getTemplateIcon(InvoiceTemplate template) {
    switch (template) {
      case InvoiceTemplate.minimalist:
        return Icons.auto_awesome;
      case InvoiceTemplate.modernCorporate:
        return Icons.business;
      case InvoiceTemplate.elegantDark:
        return Icons.star;
      case InvoiceTemplate.cleanBlue:
        return Icons.cleaning_services;
      case InvoiceTemplate.compact:
        return Icons.compress;
      case InvoiceTemplate.modernStriped:
        return Icons.design_services;
      case InvoiceTemplate.simpleGrey:
        return Icons.format_color_fill;
    }
  }

  String _getTemplateName(InvoiceTemplate template) {
    switch (template) {
      case InvoiceTemplate.minimalist:
        return 'Minimalist';
      case InvoiceTemplate.modernCorporate:
        return 'Modern Corporate';
      case InvoiceTemplate.elegantDark:
        return 'Elegant Dark';
      case InvoiceTemplate.cleanBlue:
        return 'Clean Blue';
      case InvoiceTemplate.compact:
        return 'Compact';
      case InvoiceTemplate.modernStriped:
        return 'Modern Striped';
      case InvoiceTemplate.simpleGrey:
        return 'Simple Grey';
    }
  }

  Widget _buildBottomActions(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101622) : Colors.white,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (isDark ? const Color(0xFF101622) : Colors.white).withOpacity(0.95),
            (isDark ? const Color(0xFF101622) : Colors.white),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                onSelected: (value) {
                  switch (value) {
                    case 'download':
                      _downloadPdf(context);
                      break;
                    case 'print':
                      _printPdf(context);
                      break;
                    case 'email':
                      _sendPdfByEmail(context);
                      break;
                    case 'whatsapp':
                      _sendPdfByWhatsApp(context);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(
                          Icons.download,
                          size: 20,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Download PDF',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'print',
                    child: Row(
                      children: [
                        Icon(
                          Icons.print,
                          size: 20,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Print',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'email',
                    child: Row(
                      children: [
                        Icon(
                          Icons.email,
                          size: 20,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Send by Email',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'whatsapp',
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat,
                          size: 20,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Send by WhatsApp',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download,
                        size: 20,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Download',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _showSendOptions(context, isDark),
                icon: const Icon(Icons.send, size: 20),
                label: const Text(
                  'Send Invoice',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF135BEC).withOpacity(0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generate PDF bytes for sharing/downloading
  Future<Uint8List> _generatePdfBytes() async {
    if (_invoice == null || _client == null) {
      throw Exception('Invoice or client data is missing');
    }

    // Convert domain models to UI models for PDF service
    final uiClient = ui_client.Client(
      id: _client!.id,
      name: _client!.name,
      company: (_client!.address != null && _client!.address!.isNotEmpty)
          ? _client!.address!
          : _client!.name,
      email: _client!.email,
      status: ui_client.ClientStatus.active,
      totalBilled: 0.0,
      lastActivityOrInvoice: '',
      initials: _client!.name.isNotEmpty
          ? _client!.name
              .split(' ')
              .map((w) => w[0])
              .take(2)
              .join()
              .toUpperCase()
          : '??',
      avatarGradient: [const Color(0xFFE0E7FF), const Color(0xFFDBEAFE)],
    );

    final uiItems = _invoice!.items.map((item) {
      return ui_model.InvoiceItem(
        id: item.id,
        name: item.description,
        quantity: item.quantity.toInt(),
        unitPrice: item.unitPrice,
      );
    }).toList();

    final businessProfile = ref.read(businessProfileProvider);

    final pdf = await _generatePdfDocument(
      uiClient: uiClient,
      uiItems: uiItems,
      businessProfile: businessProfile,
    );

    return pdf.save();
  }

  // Download PDF to device storage
  Future<void> _downloadPdf(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Generating PDF...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final pdfBytes = await _generatePdfBytes();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'Invoice_${_invoice!.invoiceNumber}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: ${directory.path}/$fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                // Share the file to open it
                Share.shareXFiles(
                  [XFile(file.path)],
                  text: 'Invoice PDF',
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Print PDF
  Future<void> _printPdf(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Preparing PDF for printing...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final pdfBytes = await _generatePdfBytes();
      final fileName = 'Invoice_${_invoice!.invoiceNumber}.pdf';

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Print dialog opened'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Send PDF by Email
  Future<void> _sendPdfByEmail(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Preparing email...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final pdfBytes = await _generatePdfBytes();
      final directory = await getTemporaryDirectory();
      final fileName = 'Invoice_${_invoice!.invoiceNumber}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      final businessProfile = ref.read(businessProfileProvider);
      final clientEmail = _client?.email ?? '';
      
      final subject = Uri.encodeComponent('Invoice #${_invoice!.invoiceNumber} from ${businessProfile.name}');
      final body = Uri.encodeComponent(
        'Dear ${_client?.name ?? 'Client'},\n\n'
        'Please find attached the invoice #${_invoice!.invoiceNumber}.\n\n'
        'Invoice Date: ${DateFormat('MMMM dd, yyyy').format(_invoice!.date)}\n'
        'Due Date: ${DateFormat('MMMM dd, yyyy').format(_invoice!.dueDate)}\n'
        'Total Amount: \$${_invoice!.total.toStringAsFixed(2)}\n\n'
        'Thank you for your business!\n\n'
        'Best regards,\n'
        '${businessProfile.name}',
      );

      final emailUri = Uri.parse(
        'mailto:$clientEmail?subject=$subject&body=$body',
      );

      if (await canLaunchUrl(emailUri)) {
        // Share the file with email app
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Invoice #${_invoice!.invoiceNumber}',
          text: 'Please find attached the invoice.',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email app opened'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Fallback: use share to let user choose email app
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Invoice #${_invoice!.invoiceNumber}',
          text: 'Invoice #${_invoice!.invoiceNumber}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Share dialog opened'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Send PDF by WhatsApp
  Future<void> _sendPdfByWhatsApp(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Preparing WhatsApp...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final pdfBytes = await _generatePdfBytes();
      final directory = await getTemporaryDirectory();
      final fileName = 'Invoice_${_invoice!.invoiceNumber}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      final clientPhone = _client?.phone ?? '';
      final phoneNumber = clientPhone.replaceAll(RegExp(r'[^\d]'), ''); // Remove non-digits
      
      String whatsappUrl;
      if (phoneNumber.isNotEmpty) {
        // Try to open WhatsApp with specific number
        whatsappUrl = 'https://wa.me/$phoneNumber';
      } else {
        // Open WhatsApp without number
        whatsappUrl = 'https://wa.me/';
      }

      final uri = Uri.parse(whatsappUrl);
      
      if (await canLaunchUrl(uri)) {
        // First open WhatsApp, then share the file
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Wait a bit for WhatsApp to open, then share file
        await Future.delayed(const Duration(seconds: 1));
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Invoice #${_invoice!.invoiceNumber} from ${ref.read(businessProfileProvider).name}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp opened. Please attach the PDF from share menu.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Fallback: use share to let user choose WhatsApp
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Invoice #${_invoice!.invoiceNumber}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Share dialog opened. Select WhatsApp to send.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending via WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show send options dialog
  void _showSendOptions(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Send Invoice',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF135BEC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.email,
                  color: Color(0xFF135BEC),
                ),
              ),
              title: Text(
                'Send by Email',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                _client?.email ?? 'No email available',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _sendPdfByEmail(context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chat,
                  color: Colors.green,
                ),
              ),
              title: Text(
                'Send by WhatsApp',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                _client?.phone ?? 'No phone available',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _sendPdfByWhatsApp(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

