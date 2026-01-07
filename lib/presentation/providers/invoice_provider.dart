import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/invoice_model.dart' as ui_model;
import '../../domain/entities/invoice.dart' as domain;
import '../../domain/repositories/invoice_repository.dart';
import 'invoice_repository_provider.dart';
import '../../data/repositories/client_repository_impl.dart';

// Invoice List State (using UI models for presentation)
class InvoiceState {
  final List<ui_model.Invoice> invoices;
  final bool isLoading;
  final String? error;

  const InvoiceState({
    this.invoices = const [],
    this.isLoading = false,
    this.error,
  });

  bool get isEmpty => !isLoading && invoices.isEmpty;

  InvoiceState copyWith({
    List<ui_model.Invoice>? invoices,
    bool? isLoading,
    String? error,
  }) {
    return InvoiceState(
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Invoice Notifier - Uses Repository Pattern
class InvoiceNotifier extends StateNotifier<InvoiceState> {
  final InvoiceRepository _repository;
  final ClientRepositoryImpl _clientRepository;

  InvoiceNotifier(this._repository, this._clientRepository)
    : super(const InvoiceState()) {
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repository.getRecentInvoices(limit: 10);

    if (result.error != null) {
      state = state.copyWith(error: result.error!.message, isLoading: false);
      return;
    }

    // Convert domain entities to UI models
    final uiInvoices = await _convertToUIModels(result.data ?? []);
    state = state.copyWith(invoices: uiInvoices, isLoading: false);
  }

  // Debug method to simulate empty state
  void clearInvoices() {
    state = state.copyWith(invoices: []);
  }

  // Debug method to reload data
  void refresh() {
    loadInvoices();
  }

  Future<void> createRandomInvoice() async {
    state = state.copyWith(isLoading: true);

    // Get a client to use
    final clientsResult = await _clientRepository.getClients();
    final clientId = clientsResult.data?.isNotEmpty == true
        ? clientsResult.data!.first.id
        : '';

    if (clientId.isEmpty) {
      state = state.copyWith(
        error: 'No clients available. Please add a client first.',
        isLoading: false,
      );
      return;
    }

    // Create domain invoice
    final now = DateTime.now();
    final domainInvoice = domain.Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clientId: clientId,
      invoiceNumber: 'INV-${DateTime.now().millisecond}',
      date: now,
      dueDate: now.add(const Duration(days: 14)),
      status: domain.InvoiceStatus.draft,
      items: const [],
      subtotal: 1250.00,
      taxRate: 0.0,
      taxAmount: 0.0,
      discountAmount: 0.0,
      total: 1250.00,
      currency: 'USD',
      notes: null,
      createdAt: now,
      updatedAt: now,
    );

    final result = await _repository.createInvoice(domainInvoice);

    if (result.error != null) {
      state = state.copyWith(error: result.error!.message, isLoading: false);
      return;
    }

    await loadInvoices();
  }

  /// Convert domain entities to UI models
  Future<List<ui_model.Invoice>> _convertToUIModels(
    List<domain.Invoice> domainInvoices,
  ) async {
    final uiInvoices = <ui_model.Invoice>[];

    for (final domainInvoice in domainInvoices) {
      // Get client name
      String clientName = 'Unknown Client';
      try {
        final clientResult = await _clientRepository.getClientById(
          domainInvoice.clientId,
        );
        if (clientResult.data != null) {
          clientName = clientResult.data!.name;
        }
      } catch (e) {
        // Use default name
      }

      // Convert to UI model
      uiInvoices.add(
        ui_model.Invoice(
          id: domainInvoice.id,
          number: domainInvoice.invoiceNumber,
          clientName: clientName,
          amount: domainInvoice.total,
          date: domainInvoice.date,
          dueDate: domainInvoice.dueDate,
          status: _convertStatus(domainInvoice.status),
          items: domainInvoice.items.map((item) {
            return ui_model.InvoiceItem(
              id: item.id,
              name: item.description,
              quantity: item.quantity.toInt(),
              unitPrice: item.unitPrice,
            );
          }).toList(),
        ),
      );
    }

    return uiInvoices;
  }

  /// Convert domain status to UI status
  ui_model.InvoiceStatus _convertStatus(domain.InvoiceStatus status) {
    switch (status) {
      case domain.InvoiceStatus.draft:
        return ui_model.InvoiceStatus.draft;
      case domain.InvoiceStatus.sent:
        return ui_model.InvoiceStatus.pending;
      case domain.InvoiceStatus.paid:
        return ui_model.InvoiceStatus.paid;
      case domain.InvoiceStatus.overdue:
        return ui_model.InvoiceStatus.overdue;
      case domain.InvoiceStatus.cancelled:
        return ui_model.InvoiceStatus.cancelled;
    }
  }
}

// Invoice Provider - Uses Repository
final invoiceProvider = StateNotifierProvider<InvoiceNotifier, InvoiceState>((
  ref,
) {
  final repository = ref.watch(invoiceRepositoryProvider);
  final clientRepository = ClientRepositoryImpl();
  return InvoiceNotifier(repository, clientRepository);
});

// Dashboard Stats Provider (Derived State) - Uses Repository
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  // Wait for invoices to load
  await ref.read(invoiceProvider.notifier).loadInvoices();
  final invoices = ref.read(invoiceProvider).invoices;

  // Calculate stats from invoices
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  double totalRevenue = 0.0;
  double dueToday = 0.0;
  double overdue = 0.0;
  double received = 0.0;

  for (final invoice in invoices) {
    final dueDate = DateTime(
      invoice.dueDate.year,
      invoice.dueDate.month,
      invoice.dueDate.day,
    );

    totalRevenue += invoice.amount;

    if (invoice.status == ui_model.InvoiceStatus.paid) {
      received += invoice.amount;
    } else if (invoice.status == ui_model.InvoiceStatus.overdue) {
      overdue += invoice.amount;
    } else if (invoice.status == ui_model.InvoiceStatus.pending) {
      if (dueDate.isAtSameMomentAs(today)) {
        dueToday += invoice.amount;
      } else if (dueDate.isBefore(today)) {
        overdue += invoice.amount;
      }
    }
  }

  return {
    'totalRevenue': totalRevenue,
    'dueToday': dueToday,
    'overdue': overdue,
    'received': received,
  };
});
