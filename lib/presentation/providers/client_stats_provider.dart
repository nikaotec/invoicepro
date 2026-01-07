import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/invoice.dart' as domain;
import 'client_repository_provider.dart';
import 'invoice_repository_provider.dart';

/// Client statistics for a specific client
class ClientStats {
  final double totalInvoiced;
  final int totalInvoices;
  final double outstandingAmount;
  final int pendingInvoices;
  final double averageDelay; // in days
  final String riskLevel; // 'Low Risk', 'Medium Risk', 'High Risk'

  const ClientStats({
    this.totalInvoiced = 0.0,
    this.totalInvoices = 0,
    this.outstandingAmount = 0.0,
    this.pendingInvoices = 0,
    this.averageDelay = 0.0,
    this.riskLevel = 'Low Risk',
  });
}

/// Provider to get statistics for all clients
final clientStatsProvider = FutureProvider<Map<String, ClientStats>>((ref) async {
  final clientRepository = ref.read(clientRepositoryProvider);
  final invoiceRepository = ref.read(invoiceRepositoryProvider);

  // Get all clients
  final clientsResult = await clientRepository.getClients();
  if (clientsResult.error != null || clientsResult.data == null) {
    return {};
  }

  // Get all invoices
  final invoicesResult = await invoiceRepository.getInvoices();
  if (invoicesResult.error != null || invoicesResult.data == null) {
    return {};
  }

  final clients = clientsResult.data!;
  final invoices = invoicesResult.data!;

  final Map<String, ClientStats> statsMap = {};

  for (final client in clients) {
    // Filter invoices for this client
    final clientInvoices = invoices
        .where((invoice) => invoice.clientId == client.id)
        .toList();

    if (clientInvoices.isEmpty) {
      statsMap[client.id] = const ClientStats();
      continue;
    }

    // Calculate statistics
    double totalInvoiced = 0.0;
    double outstandingAmount = 0.0;
    int pendingInvoices = 0;
    List<double> delays = [];

    for (final invoice in clientInvoices) {
      totalInvoiced += invoice.total;

      if (invoice.status == domain.InvoiceStatus.sent ||
          invoice.status == domain.InvoiceStatus.overdue) {
        outstandingAmount += invoice.total;
        pendingInvoices++;
      }

      // Calculate delay for paid invoices
      if (invoice.status == domain.InvoiceStatus.paid) {
        final dueDate = invoice.dueDate;
        final paidDate = invoice.updatedAt; // Assuming updatedAt is when it was paid
        final delay = paidDate.difference(dueDate).inDays;
        if (delay > 0) {
          delays.add(delay.toDouble());
        } else {
          delays.add(0.0);
        }
      }
    }

    // Calculate average delay
    double averageDelay = 0.0;
    if (delays.isNotEmpty) {
      averageDelay = delays.reduce((a, b) => a + b) / delays.length;
    }

    // Determine risk level
    String riskLevel = 'Low Risk';
    if (averageDelay > 30) {
      riskLevel = 'High Risk';
    } else if (averageDelay > 10) {
      riskLevel = 'Medium Risk';
    } else if (pendingInvoices > 3) {
      riskLevel = 'Medium Risk';
    }

    statsMap[client.id] = ClientStats(
      totalInvoiced: totalInvoiced,
      totalInvoices: clientInvoices.length,
      outstandingAmount: outstandingAmount,
      pendingInvoices: pendingInvoices,
      averageDelay: averageDelay,
      riskLevel: riskLevel,
    );
  }

  return statsMap;
});

/// Provider to get overall client statistics
final overallClientStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final clientRepository = ref.read(clientRepositoryProvider);
  final invoiceRepository = ref.read(invoiceRepositoryProvider);

  // Get all clients
  final clientsResult = await clientRepository.getClients();
  final clients = clientsResult.data ?? [];

  // Get all invoices
  final invoicesResult = await invoiceRepository.getInvoices();
  final invoices = invoicesResult.data ?? [];

  // Calculate total outstanding
  double totalOutstanding = 0.0;
  int pendingInvoicesCount = 0;

  for (final invoice in invoices) {
    if (invoice.status == domain.InvoiceStatus.sent ||
        invoice.status == domain.InvoiceStatus.overdue) {
      totalOutstanding += invoice.total;
      pendingInvoicesCount++;
    }
  }

  // Count new clients this month
  final now = DateTime.now();
  final thisMonthStart = DateTime(now.year, now.month, 1);
  int newClientsThisMonth = 0;

  for (final client in clients) {
    // Check if client was created this month
    if (client.createdAt.isAfter(thisMonthStart)) {
      newClientsThisMonth++;
    }
  }

  return {
    'totalClients': clients.length,
    'newClientsThisMonth': newClientsThisMonth,
    'totalOutstanding': totalOutstanding,
    'pendingInvoices': pendingInvoicesCount,
  };
});

