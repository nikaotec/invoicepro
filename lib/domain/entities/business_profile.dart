/// Business profile domain entity
class BusinessProfile {
  final String id;
  final String name;
  final String? logoPath;
  final String? taxId;
  final String email;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? website;
  final String defaultCurrency;
  final double defaultTaxRate;
  final String? invoicePrefix;
  final int nextInvoiceNumber;
  final String? bankName;
  final String? bankAccountNumber;
  final String? paymentTerms;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessProfile({
    required this.id,
    required this.name,
    this.logoPath,
    this.taxId,
    required this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.website,
    required this.defaultCurrency,
    required this.defaultTaxRate,
    this.invoicePrefix,
    required this.nextInvoiceNumber,
    this.bankName,
    this.bankAccountNumber,
    this.paymentTerms,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Generate next invoice number
  String generateInvoiceNumber() {
    final prefix = invoicePrefix ?? 'INV';
    return '$prefix-${nextInvoiceNumber.toString().padLeft(5, '0')}';
  }

  /// Get formatted full address
  String get fullAddress {
    final parts = <String>[];
    if (address != null) parts.add(address!);
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (postalCode != null) parts.add(postalCode!);
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }

  /// Copy with method
  BusinessProfile copyWith({
    String? id,
    String? name,
    String? logoPath,
    String? taxId,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? website,
    String? defaultCurrency,
    double? defaultTaxRate,
    String? invoicePrefix,
    int? nextInvoiceNumber,
    String? bankName,
    String? bankAccountNumber,
    String? paymentTerms,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      logoPath: logoPath ?? this.logoPath,
      taxId: taxId ?? this.taxId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      website: website ?? this.website,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      defaultTaxRate: defaultTaxRate ?? this.defaultTaxRate,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      bankName: bankName ?? this.bankName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
