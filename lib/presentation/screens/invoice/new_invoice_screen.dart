import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/client_model.dart';
import '../../../data/models/invoice_model.dart' as ui_model;
import '../../../domain/entities/invoice.dart' as domain;
import '../../../domain/entities/client.dart' as domain_client;
import '../../providers/invoice_repository_provider.dart';
import '../../providers/client_repository_provider.dart';
import '../../providers/invoice_provider.dart';
import '../clients/clients_list_screen.dart';
import 'invoice_pdf_preview_screen.dart';

// State for new invoice
class NewInvoiceState {
  final Client? client;
  final String invoiceNumber;
  final DateTime? dueDate;
  final String description;
  final List<ui_model.InvoiceItem> items;
  final Map<String, bool> paymentMethods;
  final bool isLoading;
  final String? error;

  const NewInvoiceState({
    this.client,
    this.invoiceNumber = '',
    this.dueDate,
    this.description = '',
    this.items = const [],
    this.paymentMethods = const {'bank_transfer': true, 'credit_card': false},
    this.isLoading = false,
    this.error,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get tax => subtotal * 0.10; // 10% tax
  double get total => subtotal + tax;

  NewInvoiceState copyWith({
    Client? client,
    String? invoiceNumber,
    DateTime? dueDate,
    String? description,
    List<ui_model.InvoiceItem>? items,
    Map<String, bool>? paymentMethods,
    bool? isLoading,
    String? error,
  }) {
    return NewInvoiceState(
      client: client ?? this.client,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      items: items ?? this.items,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Provider
final newInvoiceProvider =
    StateNotifierProvider<NewInvoiceNotifier, NewInvoiceState>((ref) {
  return NewInvoiceNotifier(
    ref.read(invoiceRepositoryProvider),
    ref.read(clientRepositoryProvider),
  );
});

class NewInvoiceNotifier extends StateNotifier<NewInvoiceState> {
  final invoiceRepository;
  final clientRepository;

  NewInvoiceNotifier(this.invoiceRepository, this.clientRepository)
      : super(NewInvoiceState()) {
    _initialize();
  }

  void _initialize() {
    // Generate invoice number
    final now = DateTime.now();
    final invoiceNumber = 'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    
    // Set default due date (30 days from now)
    final dueDate = now.add(const Duration(days: 30));

    state = state.copyWith(
      invoiceNumber: invoiceNumber,
      dueDate: dueDate,
    );
  }

  void selectClient(Client client) {
    state = state.copyWith(client: client);
  }

  void updateInvoiceNumber(String number) {
    state = state.copyWith(invoiceNumber: number);
  }

  void updateDueDate(DateTime date) {
    state = state.copyWith(dueDate: date);
  }

  void updateDescription(String desc) {
    state = state.copyWith(description: desc);
  }

  void addItem(ui_model.InvoiceItem item) {
    final items = List<ui_model.InvoiceItem>.from(state.items)..add(item);
    state = state.copyWith(items: items);
  }

  void removeItem(int index) {
    final items = List<ui_model.InvoiceItem>.from(state.items)..removeAt(index);
    state = state.copyWith(items: items);
  }

  void updateItem(int index, ui_model.InvoiceItem item) {
    final items = List<ui_model.InvoiceItem>.from(state.items);
    items[index] = item;
    state = state.copyWith(items: items);
  }

  void togglePaymentMethod(String method) {
    final methods = Map<String, bool>.from(state.paymentMethods);
    methods[method] = !(methods[method] ?? false);
    state = state.copyWith(paymentMethods: methods);
  }

  Future<String?> saveDraft() async {
    if (state.client == null) {
      state = state.copyWith(error: 'Please select a client');
      return null;
    }

    return await _createInvoice(domain.InvoiceStatus.draft);
  }

  Future<String?> createAndSend() async {
    if (state.client == null) {
      state = state.copyWith(error: 'Please select a client');
      return null;
    }

    if (state.items.isEmpty) {
      state = state.copyWith(error: 'Please add at least one item');
      return null;
    }

    return await _createInvoice(domain.InvoiceStatus.sent);
  }

  Future<String?> _createInvoice(domain.InvoiceStatus status) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get client ID from domain - need to find client by name or create mapping
      final clientsResult = await clientRepository.getClients();
      domain_client.Client? client;
      
      // Try to find client by name
      if (clientsResult.data != null && clientsResult.data!.isNotEmpty) {
        try {
          client = clientsResult.data!.firstWhere(
            (c) => c.name == state.client!.name,
          );
        } catch (e) {
          // If not found, use first client
          client = clientsResult.data!.first;
        }
      }

      if (client == null) {
        state = state.copyWith(
          error: 'Client not found. Please select a valid client.',
          isLoading: false,
        );
        return null;
      }

      // Convert items to domain
      final domainItems = state.items.map((item) {
        return domain.InvoiceItem(
          id: item.id,
          description: item.name,
          quantity: item.quantity.toDouble(),
          unitPrice: item.unitPrice,
          total: item.total,
        );
      }).toList();

      final now = DateTime.now();
      final domainInvoice = domain.Invoice(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        clientId: client.id,
        invoiceNumber: state.invoiceNumber,
        date: now,
        dueDate: state.dueDate ?? now.add(const Duration(days: 30)),
        status: status,
        items: domainItems,
        subtotal: state.subtotal,
        taxRate: 0.10,
        taxAmount: state.tax,
        discountAmount: 0.0,
        total: state.total,
        currency: 'USD',
        notes: state.description.isNotEmpty ? state.description : null,
        createdAt: now,
        updatedAt: now,
      );

      final result = await invoiceRepository.createInvoice(domainInvoice);

      if (result.error != null) {
        state = state.copyWith(
          error: result.error!.message,
          isLoading: false,
        );
        return null;
      }

      // Invoice created successfully
      final invoiceId = result.invoiceId ?? domainInvoice.id;
      state = state.copyWith(isLoading: false);
      return invoiceId;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return null;
    }
  }
}

class NewInvoiceScreen extends ConsumerStatefulWidget {
  const NewInvoiceScreen({super.key});

  @override
  ConsumerState<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends ConsumerState<NewInvoiceScreen> {
  final _invoiceNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = ref.read(newInvoiceProvider);
    _invoiceNumberController.text = state.invoiceNumber;
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(newInvoiceProvider);
    final notifier = ref.read(newInvoiceProvider.notifier);

    // Update amount display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final total = state.total;
      if (_amountController.text != NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(total)) {
        _amountController.text = NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(total);
      }
    });

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
                    // Amount Hero Section
                    _buildAmountHero(context, isDark, state),

                    const SizedBox(height: 24),

                    // Smart Suggestion
                    _buildSmartSuggestion(context, isDark),

                    const SizedBox(height: 16),

                    // Client Selector Card
                    _buildClientSelector(context, isDark, state, notifier),

                    const SizedBox(height: 16),

                    // Invoice Details
                    _buildInvoiceDetails(context, isDark, state, notifier),

                    const SizedBox(height: 16),

                    // Payment Options
                    _buildPaymentOptions(context, isDark, state, notifier),

                    const SizedBox(height: 100), // Space for footer
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Sticky Footer
      bottomNavigationBar: _buildFooter(context, isDark, state, notifier),
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
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            color: isDark ? Colors.white : Colors.black87,
          ),
          Text(
            'New Invoice',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show menu
            },
            color: isDark ? Colors.white : Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountHero(
    BuildContext context,
    bool isDark,
    NewInvoiceState state,
  ) {
    return Column(
      children: [
        Text(
          'Total Amount',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          readOnly: true,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildSmartSuggestion(BuildContext context, bool isDark) {
    return Center(
      child: InkWell(
        onTap: () {
          // TODO: Implement repeat last invoice
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF135BEC).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: const Color(0xFF135BEC),
              ),
              const SizedBox(width: 6),
              Text(
                'Repeat last invoice for Acme Corp?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF135BEC),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientSelector(
    BuildContext context,
    bool isDark,
    NewInvoiceState state,
    NewInvoiceNotifier notifier,
  ) {
    return InkWell(
      onTap: () async {
        // Navigate to client selection
        final selectedClient = await Navigator.push<Client>(
          context,
          MaterialPageRoute(
            builder: (_) => const ClientsListScreen(selectMode: true),
          ),
        );
        if (selectedClient != null) {
          notifier.selectClient(selectedClient);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2230) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
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
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[200],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.grey[600]! : Colors.grey[200]!,
                ),
              ),
              child: state.client != null
                  ? Center(
                      child: Text(
                        state.client!.initials,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getAvatarColor(state.client!.initials),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
            ),
            const SizedBox(width: 16),
            // Client Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BILL TO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.client?.name ?? 'Select Client',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: state.client != null
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? Colors.grey[500] : Colors.grey[400]),
                    ),
                  ),
                  if (state.client != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      state.client!.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceDetails(
    BuildContext context,
    bool isDark,
    NewInvoiceState state,
    NewInvoiceNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2230) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
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
          // Invoice Number & Due Date Grid
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice No.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _invoiceNumberController,
                      onChanged: (value) => notifier.updateInvoiceNumber(value),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        prefixText: '#',
                        prefixStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF101622)
                            : const Color(0xFFF6F6F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: state.dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          notifier.updateDueDate(date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF101622)
                              : const Color(0xFFF6F6F8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                state.dueDate != null
                                    ? DateFormat('MMM d, yyyy')
                                        .format(state.dueDate!)
                                    : 'Select date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Quick Date Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDateChip(
                  context,
                  isDark,
                  label: 'Today',
                  days: 0,
                  isSelected: false,
                  onTap: () {
                    notifier.updateDueDate(DateTime.now());
                  },
                ),
                const SizedBox(width: 8),
                _buildDateChip(
                  context,
                  isDark,
                  label: '7 Days',
                  days: 7,
                  isSelected: false,
                  onTap: () {
                    notifier.updateDueDate(
                      DateTime.now().add(const Duration(days: 7)),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildDateChip(
                  context,
                  isDark,
                  label: '14 Days',
                  days: 14,
                  isSelected: false,
                  onTap: () {
                    notifier.updateDueDate(
                      DateTime.now().add(const Duration(days: 14)),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildDateChip(
                  context,
                  isDark,
                  label: '30 Days',
                  days: 30,
                  isSelected: false,
                  onTap: () {
                    notifier.updateDueDate(
                      DateTime.now().add(const Duration(days: 30)),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Divider(
            color: isDark ? Colors.grey[700] : Colors.grey[200],
            height: 1,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            'Description',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[300] : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            onChanged: (value) => notifier.updateDescription(value),
            maxLines: 2,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'E.g. Web Design Project Phase 1',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF101622)
                  : const Color(0xFFF6F6F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),

          const SizedBox(height: 16),

          // Line Items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items (${state.items.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _showAddItemDialog(context, isDark, notifier);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF135BEC),
                ),
              ),
            ],
          ),

          // Items List
          if (state.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No items added yet',
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                ),
              ),
            )
          else
            ...state.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return _buildItemCard(context, isDark, item, index, notifier);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildDateChip(
    BuildContext context,
    bool isDark, {
    required String label,
    required int days,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF135BEC)
              : (isDark
                  ? const Color(0xFF101622)
                  : const Color(0xFFF6F6F8)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    bool isDark,
    ui_model.InvoiceItem item,
    int index,
    NewInvoiceNotifier notifier,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} × ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(item.unitPrice)} = ${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(item.total)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => notifier.removeItem(index),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions(
    BuildContext context,
    bool isDark,
    NewInvoiceState state,
    NewInvoiceNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2230) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
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
            'Payment Methods',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // Bank Transfer
          _buildPaymentMethodOption(
            context,
            isDark,
            icon: Icons.account_balance,
            title: 'Bank Transfer',
            subtitle: '2-3 business days',
            isEnabled: state.paymentMethods['bank_transfer'] ?? false,
            onToggle: () => notifier.togglePaymentMethod('bank_transfer'),
            iconColor: const Color(0xFF135BEC),
          ),
          const SizedBox(height: 12),
          Divider(
            color: isDark ? Colors.grey[700] : Colors.grey[200],
            height: 1,
          ),
          const SizedBox(height: 12),
          // Credit Card
          _buildPaymentMethodOption(
            context,
            isDark,
            icon: Icons.credit_card,
            title: 'Credit Card',
            subtitle: 'Instant • 2.9% fee',
            isEnabled: state.paymentMethods['credit_card'] ?? false,
            onToggle: () => notifier.togglePaymentMethod('credit_card'),
            iconColor: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback onToggle,
    required Color iconColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        Switch(
          value: isEnabled,
          onChanged: (_) => onToggle(),
          activeColor: const Color(0xFF135BEC),
        ),
      ],
    );
  }

  Widget _buildFooter(
    BuildContext context,
    bool isDark,
    NewInvoiceState state,
    NewInvoiceNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF101622) : Colors.white).withOpacity(0.8),
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
              child: ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        final invoiceId = await notifier.saveDraft();
                        if (invoiceId != null && mounted) {
                          // Refresh invoice list
                          ref.read(invoiceProvider.notifier).loadInvoices();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Draft saved successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (mounted && state.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.error!),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save Draft',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        final invoiceId = await notifier.createAndSend();
                        if (invoiceId != null && mounted) {
                          // Refresh invoice list
                          ref.read(invoiceProvider.notifier).loadInvoices();
                          
                          // Navigate to PDF preview screen
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => InvoicePdfPreviewScreen(
                                invoiceId: invoiceId,
                              ),
                            ),
                          );
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invoice created and sent successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (mounted && state.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.error!),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF135BEC).withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Create & Send',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.send, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog(
    BuildContext context,
    bool isDark,
    NewInvoiceNotifier notifier,
  ) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A2230) : Colors.white,
        title: Text(
          'Add Item',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Item Name',
                labelStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF101622)
                    : const Color(0xFFF6F6F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF101622)
                          : const Color(0xFFF6F6F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Unit Price',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF101622)
                          : const Color(0xFFF6F6F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text) ?? 1;
              final price = double.tryParse(priceController.text) ?? 0.0;
              final item = ui_model.InvoiceItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                quantity: quantity,
                unitPrice: price,
              );
              notifier.addItem(item);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF135BEC),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String initials) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF0EA5E9),
      const Color(0xFF8B5CF6),
    ];
    final index = initials.hashCode % colors.length;
    return colors[index.abs()];
  }
}

