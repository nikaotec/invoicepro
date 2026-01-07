import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/invoice_repository_provider.dart';
import '../../providers/client_repository_provider.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/invoice/record_payment_dialog.dart';
import '../payment/payment_screen.dart';
import '../../../domain/entities/invoice.dart' as domain;
import '../../../domain/entities/client.dart' as domain_client;
import '../../../domain/entities/payment.dart' as payment_entity;
import 'invoice_pdf_preview_screen.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
  });

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  domain.Invoice? _invoice;
  domain_client.Client? _client;
  bool _isLoading = true;
  String? _error;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
          elevation: 0,
        ),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Invoice not found',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Hero Card
                    _buildHeroCard(context, isDark),

                    const SizedBox(height: 16),

                    // Payment Summary Card
                    _buildPaymentSummaryCard(context, isDark),

                    const SizedBox(height: 16),

                    // Payment History Card
                    _buildPaymentHistoryCard(context, isDark),

                    const SizedBox(height: 16),

                    // Payment Link Card
                    _buildPaymentLinkCard(context, isDark),

                    const SizedBox(height: 16),

                    // Invoice Details Card
                    _buildInvoiceDetailsCard(context, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Sticky Footer
      bottomNavigationBar: _buildFooter(context, isDark),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8))
            .withOpacity(0.95),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            color: isDark ? Colors.white : Colors.black87,
          ),
          Text(
            'Invoice #${_invoice!.invoiceNumber}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showMenu(context, isDark);
            },
            color: isDark ? Colors.white : Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, bool isDark) {
    final isPaid = _invoice!.status == domain.InvoiceStatus.paid;
    final isOverdue = _invoice!.status == domain.InvoiceStatus.overdue;

    Color statusColor;
    Color statusBgColor;
    String statusLabel;

    if (isPaid) {
      statusColor = isDark ? Colors.green[400]! : Colors.green[600]!;
      statusBgColor = isDark
          ? Colors.green[900]!.withOpacity(0.3)
          : Colors.green[50]!;
      statusLabel = 'Paid';
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusBgColor = isDark
          ? Colors.red[900]!.withOpacity(0.3)
          : Colors.red[50]!;
      statusLabel = 'Overdue';
    } else {
      statusColor = isDark ? Colors.orange[400]! : Colors.orange[600]!;
      statusBgColor = isDark
          ? Colors.orange[900]!.withOpacity(0.3)
          : Colors.orange[50]!;
      statusLabel = 'Outstanding';
    }

    final now = DateTime.now();
    final daysUntilDue = _invoice!.dueDate.difference(now).inDays;
    String dueText;
    if (isPaid) {
      dueText = 'Paid on ${DateFormat('MMM d').format(_invoice!.date)}';
    } else if (daysUntilDue < 0) {
      dueText = 'Overdue ${daysUntilDue.abs()} days ago';
    } else if (daysUntilDue == 0) {
      dueText = 'Due today';
    } else {
      dueText = 'Due in $daysUntilDue days (${DateFormat('MMM d').format(_invoice!.dueDate)})';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Amount
          Text(
            NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                .format(_invoice!.total),
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          // Due Date
          Text(
            dueText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),

          const SizedBox(height: 24),

          // Divider
          Divider(
            color: isDark ? Colors.grey[700] : Colors.grey[200],
            height: 1,
          ),

          const SizedBox(height: 24),

          // Timeline
          _buildTimeline(context, isDark),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, bool isDark) {
    final isPaid = _invoice!.status == domain.InvoiceStatus.paid;
    final isSent = _invoice!.status == domain.InvoiceStatus.sent ||
        _invoice!.status == domain.InvoiceStatus.paid;

    return Column(
      children: [
        // Step 1: Sent
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF135BEC).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF135BEC),
                    size: 20,
                  ),
                ),
                if (isSent)
                  Container(
                    width: 2,
                    height: 24,
                    color: const Color(0xFF135BEC),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invoice Sent',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, yyyy h:mm a').format(_invoice!.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (isSent) ...[
          const SizedBox(height: 16),
          // Step 2: Viewed
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF135BEC).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.visibility,
                      color: Color(0xFF135BEC),
                      size: 20,
                    ),
                  ),
                  if (isPaid)
                    Container(
                      width: 2,
                      height: 24,
                      color: isDark ? Colors.grey[700] : Colors.grey[200],
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Viewed by Client',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy h:mm a')
                          .format(_invoice!.date.add(const Duration(hours: 1, minutes: 30))),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],

        if (isSent) ...[
          const SizedBox(height: 16),
          // Step 3: Paid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.attach_money,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Received',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPaid ? 'Paid' : 'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentSummaryCard(BuildContext context, bool isDark) {
    if (_invoice == null) return const SizedBox.shrink();

    final paymentState = ref.watch(paymentProvider(widget.invoiceId));
    final totalPaid = paymentState.totalPaid;
    final pendingAmount = _invoice!.total - totalPaid;
    final paymentProgress = _invoice!.total > 0 ? totalPaid / _invoice!.total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PAYMENT SUMMARY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              if (pendingAmount > 0)
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await RecordPaymentDialog.show(
                      context,
                      invoice: _invoice!,
                      totalPaid: totalPaid,
                      pendingAmount: pendingAmount,
                    );
                    if (result == true && mounted) {
                      ref.read(paymentProvider(widget.invoiceId).notifier).refresh();
                      _loadInvoice(); // Reload invoice to update status
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Registrar Pagamento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135BEC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: paymentProgress,
              minHeight: 8,
              backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                paymentProgress >= 1.0 ? Colors.green : const Color(0xFF135BEC),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Summary Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pago',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                          .format(totalPaid),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Pendente',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                          .format(pendingAmount),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: pendingAmount > 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryCard(BuildContext context, bool isDark) {
    if (_invoice == null) return const SizedBox.shrink();

    final paymentState = ref.watch(paymentProvider(widget.invoiceId));
    final payments = paymentState.payments;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PAYMENT HISTORY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                if (payments.isNotEmpty)
                  Text(
                    '${payments.length} ${payments.length == 1 ? 'payment' : 'payments'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),

          // Payments List
          if (paymentState.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (payments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.payment_outlined,
                      size: 48,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No payments recorded',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              separatorBuilder: (context, index) => Divider(
                color: isDark ? Colors.grey[700] : Colors.grey[200],
                height: 24,
              ),
              itemBuilder: (context, index) {
                final payment = payments[index];
                return _buildPaymentItem(context, isDark, payment);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(
    BuildContext context,
    bool isDark,
    payment_entity.Payment payment,
  ) {
    IconData methodIcon;
    Color methodColor;

    switch (payment.method) {
      case payment_entity.PaymentMethod.cash:
        methodIcon = Icons.money;
        methodColor = Colors.green;
        break;
      case payment_entity.PaymentMethod.bankTransfer:
        methodIcon = Icons.account_balance;
        methodColor = const Color(0xFF135BEC);
        break;
      case payment_entity.PaymentMethod.creditCard:
        methodIcon = Icons.credit_card;
        methodColor = Colors.purple;
        break;
      case payment_entity.PaymentMethod.debitCard:
        methodIcon = Icons.credit_card;
        methodColor = Colors.blue;
        break;
      case payment_entity.PaymentMethod.check:
        methodIcon = Icons.receipt;
        methodColor = Colors.orange;
        break;
      case payment_entity.PaymentMethod.paypal:
        methodIcon = Icons.account_balance_wallet;
        methodColor = Colors.blue;
        break;
      default:
        methodIcon = Icons.payment;
        methodColor = Colors.grey;
    }

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: methodColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            methodIcon,
            color: methodColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment.method.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM d, yyyy').format(payment.date),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  payment.notes!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        Text(
          NumberFormat.currency(symbol: '\$', decimalDigits: 2)
              .format(payment.amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentLinkCard(BuildContext context, bool isDark) {
    final paymentState = ref.watch(paymentProvider(widget.invoiceId));
    final totalPaid = paymentState.totalPaid;
    final pendingAmount = _invoice!.total - totalPaid;
    final paymentLink = 'invoicepro.app/pay/${widget.invoiceId}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PAYMENT LINK',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              if (pendingAmount > 0)
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentScreen(invoiceId: widget.invoiceId),
                      ),
                    ).then((result) {
                      if (result == true && mounted) {
                        ref.read(paymentProvider(widget.invoiceId).notifier).refresh();
                        _loadInvoice();
                      }
                    });
                  },
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('Pay Online'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF135BEC),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    paymentLink,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.content_copy, size: 20),
                  color: const Color(0xFF135BEC),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: paymentLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment link copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Share this link with your client to allow them to pay online via Stripe or PayPal',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetailsCard(BuildContext context, bool isDark) {
    final clientName = _client?.name ?? _invoice!.clientId;
    final clientAddress = _client?.address ?? '';

    final initials = _getInitials(clientName);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: Text(
              'Invoice Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Billed To
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Billed to',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            clientName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (clientAddress.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              clientAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Issue Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Issue Date',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(_invoice!.date),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Services
                Divider(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  height: 1,
                ),

                const SizedBox(height: 12),

                Text(
                  'Services',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),

                const SizedBox(height: 12),

                // Items
                ..._invoice!.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                              .format(item.total),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                // Totals
                const SizedBox(height: 12),
                Divider(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  height: 1,
                ),
                const SizedBox(height: 12),

                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                          .format(_invoice!.subtotal),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),

                if (_invoice!.taxAmount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tax (${(_invoice!.taxRate * 100).toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      Text(
                        NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                            .format(_invoice!.taxAmount),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                Divider(
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  height: 1,
                ),
                const SizedBox(height: 12),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                          .format(_invoice!.total),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _invoice == null
                    ? null
                    : () async {
                        final paymentState = ref.read(paymentProvider(widget.invoiceId));
                        final totalPaid = paymentState.totalPaid;
                        final pendingAmount = _invoice!.total - totalPaid;
                        
                        if (pendingAmount > 0) {
                          final result = await RecordPaymentDialog.show(
                            context,
                            invoice: _invoice!,
                            totalPaid: totalPaid,
                            pendingAmount: pendingAmount,
                          );
                          if (result == true && mounted) {
                            ref.read(paymentProvider(widget.invoiceId).notifier).refresh();
                            _loadInvoice(); // Reload invoice to update status
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invoice is already fully paid'),
                            ),
                          );
                        }
                      },
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
                child: const Text(
                  'Registrar Pagamento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InvoicePdfPreviewScreen(
                        invoiceId: widget.invoiceId,
                      ),
                    ),
                  );
                },
                color: isDark ? Colors.grey[200] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey[800] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Invoice'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Invoice'),
              textColor: Colors.red,
              iconColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, isDark);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
        title: const Text('Delete Invoice'),
        content: const Text('Are you sure you want to delete this invoice? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement delete
              if (mounted) {
                Navigator.pop(context); // Go back to list
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}

