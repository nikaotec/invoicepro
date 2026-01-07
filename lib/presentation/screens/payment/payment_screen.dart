import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/invoice_repository_provider.dart';
import '../../providers/payment_provider.dart';
import '../../../domain/entities/payment_intent.dart';
import '../../../domain/entities/payment.dart' as payment_entity;
import '../../../data/services/payment_service.dart';

/// Public payment screen for customers to pay invoices online
class PaymentScreen extends ConsumerStatefulWidget {
  final String invoiceId;
  final String? token; // Optional security token

  const PaymentScreen({
    super.key,
    required this.invoiceId,
    this.token,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentGateway? _selectedGateway;
  bool _isProcessing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Load invoice
    final invoiceAsync = ref.watch(_invoiceProvider(widget.invoiceId));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          color: isDark ? Colors.white : Colors.black87,
        ),
        title: Text(
          'Pay Invoice',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: invoiceAsync.when(
        data: (invoice) {
          if (invoice == null) {
            return Center(
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
                    'Invoice not found',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          // Check if already paid
          final paymentState = ref.watch(paymentProvider(widget.invoiceId));
          final totalPaid = paymentState.totalPaid;
          final pendingAmount = invoice.total - totalPaid;

          if (pendingAmount <= 0) {
            return _buildAlreadyPaidView(context, isDark, invoice);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice Summary Card
                _buildInvoiceSummaryCard(context, isDark, invoice, totalPaid, pendingAmount),

                const SizedBox(height: 32),

                // Payment Method Selection
                Text(
                  'Choose Payment Method',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Stripe Option
                _buildPaymentMethodOption(
                  context,
                  isDark,
                  gateway: PaymentGateway.stripe,
                  title: 'Pay with Card',
                  subtitle: 'Visa, Mastercard, Amex, Apple Pay, Google Pay',
                  icon: Icons.credit_card,
                  iconColor: const Color(0xFF635BFF),
                  isSelected: _selectedGateway == PaymentGateway.stripe,
                  onTap: () {
                    setState(() {
                      _selectedGateway = PaymentGateway.stripe;
                      _error = null;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // PayPal Option
                _buildPaymentMethodOption(
                  context,
                  isDark,
                  gateway: PaymentGateway.paypal,
                  title: 'Pay with PayPal',
                  subtitle: 'Pay with your PayPal account or card',
                  icon: Icons.account_balance_wallet,
                  iconColor: const Color(0xFF0070BA),
                  isSelected: _selectedGateway == PaymentGateway.paypal,
                  onTap: () {
                    setState(() {
                      _selectedGateway = PaymentGateway.paypal;
                      _error = null;
                    });
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Pay Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedGateway == null || _isProcessing
                        ? null
                        : () => _processPayment(context, invoice, pendingAmount),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF135BEC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Pay \$${pendingAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
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
                'Error loading invoice',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceSummaryCard(
    BuildContext context,
    bool isDark,
    dynamic invoice,
    double totalPaid,
    double pendingAmount,
  ) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice #${invoice.invoiceNumber}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Text(
                NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                    .format(invoice.total),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          if (totalPaid > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Already Paid',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                      .format(totalPaid),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount Due',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                    .format(pendingAmount),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    BuildContext context,
    bool isDark, {
    required PaymentGateway gateway,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? iconColor
                : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
            width: isSelected ? 2 : 1,
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
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: iconColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyPaidView(
    BuildContext context,
    bool isDark,
    dynamic invoice,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Invoice Already Paid',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This invoice has been fully paid.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(
    BuildContext context,
    dynamic invoice,
    double amount,
  ) async {
    if (_selectedGateway == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      PaymentService paymentService;
      if (_selectedGateway == PaymentGateway.stripe) {
        paymentService = StripePaymentService(
          backendUrl: null, // TODO: Configure your backend URL
        );
      } else {
        paymentService = PayPalPaymentService(
          backendUrl: null, // TODO: Configure your backend URL
        );
      }

      // Create payment intent
      final createResult = await paymentService.createPaymentIntent(
        invoiceId: widget.invoiceId,
        amount: amount,
        currency: invoice.currency ?? 'USD',
        description: 'Invoice ${invoice.invoiceNumber}',
      );

      if (createResult.error != null) {
        setState(() {
          _error = createResult.error!.message;
          _isProcessing = false;
        });
        return;
      }

      final paymentIntent = createResult.paymentIntent;
      if (paymentIntent == null) {
        setState(() {
          _error = 'Failed to create payment intent';
          _isProcessing = false;
        });
        return;
      }

      // For Stripe, we would use the Stripe SDK here
      // For PayPal, open the approval URL
      if (_selectedGateway == PaymentGateway.paypal && paymentIntent.approvalUrl != null) {
        final uri = Uri.parse(paymentIntent.approvalUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          
          // TODO: Handle PayPal callback and confirm payment
          // This would typically involve:
          // 1. Waiting for user to approve in PayPal
          // 2. PayPal redirects back with approval token
          // 3. Confirm payment with backend
          // 4. Update invoice status
          
          // For now, show a message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please complete payment in PayPal and return to the app',
                ),
              ),
            );
          }
        }
      } else {
        // Stripe payment would be processed here using flutter_stripe
        // TODO: Implement Stripe payment confirmation
        
        // Mock confirmation for now
        await Future.delayed(const Duration(seconds: 2));
        
        // Record payment
        final paymentNotifier = ref.read(paymentProvider(widget.invoiceId).notifier);
        final success = await paymentNotifier.recordPayment(
          amount: amount,
          method: _selectedGateway == PaymentGateway.stripe
              ? payment_entity.PaymentMethod.creditCard
              : payment_entity.PaymentMethod.paypal,
          date: DateTime.now(),
          notes: 'Online payment via ${_selectedGateway!.displayName}',
        );

        if (success && mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment processed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Payment processing failed: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }
}

/// Provider to load invoice by ID
final _invoiceProvider = FutureProvider.family((ref, String invoiceId) async {
  final repository = ref.read(invoiceRepositoryProvider);
  final result = await repository.getInvoiceById(invoiceId);
  if (result.error != null) {
    throw Exception(result.error!.message);
  }
  return result.data;
});

