import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/payment_intent.dart';
import '../../core/errors/failures.dart';

/// Abstract payment service interface
abstract class PaymentService {
  /// Initialize payment service
  Future<({bool success, Failure? error})> initialize();

  /// Create a payment intent for an invoice
  Future<({PaymentIntent? paymentIntent, Failure? error})> createPaymentIntent({
    required String invoiceId,
    required double amount,
    required String currency,
    String? description,
  });

  /// Confirm/process the payment
  Future<({bool success, Failure? error})> confirmPayment({
    required PaymentIntent paymentIntent,
  });

  /// Check payment status
  Future<({PaymentIntentStatus? status, Failure? error})> checkPaymentStatus({
    required String gatewayPaymentId,
  });
}

/// Stripe Payment Service
/// 
/// NOTE: This is a simplified implementation. In production, you should:
/// 1. Use a backend server to create Payment Intents (never use secret keys in the app)
/// 2. Use Stripe's backend API with your secret key
/// 3. Return client_secret to the app
/// 
/// For now, this uses a mock/placeholder implementation
class StripePaymentService implements PaymentService {
  final String? publishableKey;
  final String? backendUrl; // Your backend URL for creating payment intents

  StripePaymentService({
    this.publishableKey,
    this.backendUrl,
  });

  @override
  Future<({bool success, Failure? error})> initialize() async {
    // Initialize Stripe SDK
    // await Stripe.publishableKey = publishableKey ?? '';
    // await Stripe.instance.applySettings();
    return (success: true, error: null);
  }

  @override
  Future<({PaymentIntent? paymentIntent, Failure? error})> createPaymentIntent({
    required String invoiceId,
    required double amount,
    required String currency,
    String? description,
  }) async {
    try {
      // In production, call your backend API
      if (backendUrl != null) {
        final response = await http.post(
          Uri.parse('$backendUrl/create-payment-intent'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'invoiceId': invoiceId,
            'amount': (amount * 100).toInt(), // Convert to cents
            'currency': currency.toLowerCase(),
            'description': description ?? 'Invoice $invoiceId',
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final paymentIntent = PaymentIntent(
            id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            invoiceId: invoiceId,
            gateway: PaymentGateway.stripe,
            gatewayPaymentId: data['paymentIntentId'],
            amount: amount,
            currency: currency,
            status: PaymentIntentStatus.created,
            clientSecret: data['clientSecret'],
            createdAt: DateTime.now(),
          );
          return (paymentIntent: paymentIntent, error: null);
        } else {
          return (
            paymentIntent: null,
            error: ServerFailure('Failed to create payment intent: ${response.body}')
          );
        }
      }

      // Mock implementation for development
      // TODO: Remove in production
      final mockPaymentIntent = PaymentIntent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        invoiceId: invoiceId,
        gateway: PaymentGateway.stripe,
        gatewayPaymentId: 'pi_mock_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        currency: currency,
        status: PaymentIntentStatus.created,
        clientSecret: 'mock_client_secret',
        createdAt: DateTime.now(),
      );

      return (paymentIntent: mockPaymentIntent, error: null);
    } catch (e) {
      return (
        paymentIntent: null,
        error: UnknownFailure('Failed to create Stripe payment intent: ${e.toString()}')
      );
    }
  }

  @override
  Future<({bool success, Failure? error})> confirmPayment({
    required PaymentIntent paymentIntent,
  }) async {
    try {
      // In production, use Stripe SDK to confirm payment
      // await Stripe.instance.confirmPayment(
      //   paymentIntent.clientSecret!,
      //   PaymentMethodParams.card(...),
      // );

      // Mock implementation
      // TODO: Implement real Stripe confirmation
      await Future.delayed(const Duration(seconds: 2));

      return (success: true, error: null);
    } catch (e) {
      return (
        success: false,
        error: UnknownFailure('Failed to confirm Stripe payment: ${e.toString()}')
      );
    }
  }

  @override
  Future<({PaymentIntentStatus? status, Failure? error})> checkPaymentStatus({
    required String gatewayPaymentId,
  }) async {
    try {
      // In production, check status via backend or Stripe API
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 500));
      return (status: PaymentIntentStatus.succeeded, error: null);
    } catch (e) {
      return (
        status: null,
        error: UnknownFailure('Failed to check payment status: ${e.toString()}')
      );
    }
  }
}

/// PayPal Payment Service
/// 
/// NOTE: This is a simplified implementation. In production, you should:
/// 1. Use a backend server to create PayPal Orders
/// 2. Use PayPal's backend API
/// 3. Return approval_url to the app
class PayPalPaymentService implements PaymentService {
  final String? clientId;
  final String? backendUrl;
  final bool isSandbox;

  PayPalPaymentService({
    this.clientId,
    this.backendUrl,
    this.isSandbox = true, // Use sandbox for testing
  });

  @override
  Future<({bool success, Failure? error})> initialize() async {
    // Initialize PayPal SDK if needed
    return (success: true, error: null);
  }

  @override
  Future<({PaymentIntent? paymentIntent, Failure? error})> createPaymentIntent({
    required String invoiceId,
    required double amount,
    required String currency,
    String? description,
  }) async {
    try {
      // In production, call your backend API
      if (backendUrl != null) {
        final response = await http.post(
          Uri.parse('$backendUrl/create-paypal-order'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'invoiceId': invoiceId,
            'amount': amount.toStringAsFixed(2),
            'currency': currency,
            'description': description ?? 'Invoice $invoiceId',
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final paymentIntent = PaymentIntent(
            id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            invoiceId: invoiceId,
            gateway: PaymentGateway.paypal,
            gatewayPaymentId: data['orderId'],
            amount: amount,
            currency: currency,
            status: PaymentIntentStatus.created,
            approvalUrl: data['approvalUrl'],
            createdAt: DateTime.now(),
          );
          return (paymentIntent: paymentIntent, error: null);
        } else {
          return (
            paymentIntent: null,
            error: ServerFailure('Failed to create PayPal order: ${response.body}')
          );
        }
      }

      // Mock implementation for development
      // TODO: Remove in production
      final mockPaymentIntent = PaymentIntent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        invoiceId: invoiceId,
        gateway: PaymentGateway.paypal,
        gatewayPaymentId: 'order_mock_${DateTime.now().millisecondsSinceEpoch}',
        amount: amount,
        currency: currency,
        status: PaymentIntentStatus.created,
        approvalUrl: isSandbox
            ? 'https://www.sandbox.paypal.com/checkoutnow?token=mock_token'
            : 'https://www.paypal.com/checkoutnow?token=mock_token',
        createdAt: DateTime.now(),
      );

      return (paymentIntent: mockPaymentIntent, error: null);
    } catch (e) {
      return (
        paymentIntent: null,
        error: UnknownFailure('Failed to create PayPal order: ${e.toString()}')
      );
    }
  }

  @override
  Future<({bool success, Failure? error})> confirmPayment({
    required PaymentIntent paymentIntent,
  }) async {
    try {
      // In production, confirm PayPal order via backend
      // This would typically be called after user approves in PayPal
      if (backendUrl != null && paymentIntent.gatewayPaymentId != null) {
        final response = await http.post(
          Uri.parse('$backendUrl/confirm-paypal-order'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'orderId': paymentIntent.gatewayPaymentId,
          }),
        );

        if (response.statusCode == 200) {
          return (success: true, error: null);
        } else {
          return (
            success: false,
            error: ServerFailure('Failed to confirm PayPal order: ${response.body}')
          );
        }
      }

      // Mock implementation
      await Future.delayed(const Duration(seconds: 2));
      return (success: true, error: null);
    } catch (e) {
      return (
        success: false,
        error: UnknownFailure('Failed to confirm PayPal payment: ${e.toString()}')
      );
    }
  }

  @override
  Future<({PaymentIntentStatus? status, Failure? error})> checkPaymentStatus({
    required String gatewayPaymentId,
  }) async {
    try {
      // In production, check status via backend or PayPal API
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 500));
      return (status: PaymentIntentStatus.succeeded, error: null);
    } catch (e) {
      return (
        status: null,
        error: UnknownFailure('Failed to check PayPal payment status: ${e.toString()}')
      );
    }
  }
}

