import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/client_model.dart';
import '../../data/models/invoice_model.dart' as ui_model;
import '../../data/models/product_model.dart';
import '../../domain/entities/invoice.dart' as domain;
import '../../domain/repositories/invoice_repository.dart';
import 'invoice_repository_provider.dart';
import 'invoice_provider.dart';

// State for the Smart Invoice Creator
class SmartInvoiceState {
  final bool isScanning;
  final File? scannedImage;
  final Client? client; // Changed from String? clientName
  final bool isClientDetected;
  final List<ui_model.InvoiceItem> items;
  final String? note;
  final bool isSubmitting;
  final String? error;

  const SmartInvoiceState({
    this.isScanning = false,
    this.scannedImage,
    this.client,
    this.isClientDetected = false,
    this.items = const [],
    this.note,
    this.isSubmitting = false,
    this.error,
  });

  bool get isValid =>
      items.isNotEmpty && items.every((i) => i.isValid) && client != null;

  double get subtotal => items.fold(0, (sum, item) => sum + (item.total));
  double get tax => subtotal * 0.10; // 10% tax for demo
  double get total => subtotal + tax;

  SmartInvoiceState copyWith({
    bool? isScanning,
    File? scannedImage,
    Client? client,
    bool? isClientDetected,
    List<ui_model.InvoiceItem>? items,
    String? note,
    bool? isSubmitting,
    String? error,
  }) {
    return SmartInvoiceState(
      isScanning: isScanning ?? this.isScanning,
      scannedImage: scannedImage ?? this.scannedImage,
      client: client ?? this.client,
      isClientDetected: isClientDetected ?? this.isClientDetected,
      items: items ?? this.items,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
    );
  }
}

// Notifier
class SmartInvoiceNotifier extends StateNotifier<SmartInvoiceState> {
  final InvoiceRepository _repository;
  final Ref _ref;

  SmartInvoiceNotifier(
    this._repository,
    this._ref,
  ) : super(const SmartInvoiceState());

  // Pick Image (Camera or Gallery)
  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        state = state.copyWith(scannedImage: File(image.path));
        // Trigger AI Scan Simulation
        await simulateAIScan();
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to pick image: $e');
    }
  }

  // Simulate AI Scan (OCR)
  Future<void> simulateAIScan() async {
    state = state.copyWith(isScanning: true, error: null);

    // Simulate network delay for AI processing
    await Future.delayed(const Duration(seconds: 2));

    // Mock Data extracted from "AI"
    final mockItems = [
      ui_model.InvoiceItem.mock(
        name: "MacBook Pro 14' M3 - Silver",
        unitPrice: 1999.00,
        quantity: 1,
        isValid: true,
      ),
      ui_model.InvoiceItem.mock(
        name: "Unknown Accessory",
        unitPrice: 29.00,
        quantity: 0,
        isValid: false, // Needs attention
      ),
    ];

    // Mock Client Detection
    final mockClient = Client.mock(
      id: '1',
      name: 'StartFlow Systems',
      company: 'StartFlow Inc.',
      status: ClientStatus.active,
      totalBilled: 0,
      lastActivity: 'Detected via AI',
      initials: 'SF',
      gradient: [const Color(0xFFE0E7FF), const Color(0xFFDBEAFE)],
    );

    state = state.copyWith(
      isScanning: false,
      client: mockClient,
      isClientDetected: true,
      items: mockItems,
    );
  }

  // Manually Select Client
  void selectClient(Client client) {
    state = state.copyWith(client: client, isClientDetected: false);
  }

  // Update Item (e.g. validaty when user edits)
  void updateItem(int index, ui_model.InvoiceItem updatedItem) {
    if (index < 0 || index >= state.items.length) return;

    final newItems = List<ui_model.InvoiceItem>.from(state.items);
    newItems[index] = updatedItem;

    state = state.copyWith(items: newItems);
  }

  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;
    final newItems = List<ui_model.InvoiceItem>.from(state.items);
    newItems.removeAt(index);
    state = state.copyWith(items: newItems);
  }

  void addItem() {
    final newItem = ui_model.InvoiceItem.mock(
      name: 'New Item',
      unitPrice: 0.0,
      isValid: false,
    );
    state = state.copyWith(items: [...state.items, newItem]);
  }

  void addItemFromProduct(Product product) {
    final newItem = ui_model.InvoiceItem.mock(
      name: product.name,
      unitPrice: product.price,
      quantity: 1,
      isValid: true,
    );
    state = state.copyWith(items: [...state.items, newItem]);
  }

  // Create Invoice
  Future<bool> createInvoice() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please complete all required fields');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    final now = DateTime.now();
    final clientId = state.client?.id ?? '';

    if (clientId.isEmpty) {
      state = state.copyWith(
        error: 'Client is required',
        isSubmitting: false,
      );
      return false;
    }

    // Convert UI items to domain items
    final domainItems = state.items.map((item) {
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
      invoiceNumber:
          'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecond}',
      date: now,
      dueDate: now.add(const Duration(days: 30)),
      status: domain.InvoiceStatus.draft,
      items: domainItems,
      subtotal: state.subtotal,
      taxRate: 0.10, // 10% tax
      taxAmount: state.tax,
      discountAmount: 0.0,
      total: state.total,
      currency: 'USD',
      notes: state.note,
      createdAt: now,
      updatedAt: now,
    );

    // Use repository to create invoice
    final result = await _repository.createInvoice(domainInvoice);

    if (result.error != null) {
      state = state.copyWith(
        error: result.error!.message,
        isSubmitting: false,
      );
      return false;
    }

    // Refresh main list
    await _ref.read(invoiceProvider.notifier).loadInvoices();

    state = state.copyWith(isSubmitting: false);
    return true;
  }
}

// Provider
final smartInvoiceProvider =
    StateNotifierProvider.autoDispose<SmartInvoiceNotifier, SmartInvoiceState>((
      ref,
    ) {
      final repository = ref.watch(invoiceRepositoryProvider);
      return SmartInvoiceNotifier(repository, ref);
    });
