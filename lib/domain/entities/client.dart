/// Client/Customer domain entity
class Client {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? taxId;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Client({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.taxId,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    required this.createdAt,
    required this.updatedAt,
  });

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
  Client copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? taxId,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
