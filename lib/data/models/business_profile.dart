import 'dart:typed_data';

class BusinessProfile {
  final String name;
  final String email;
  final String phone;
  final String address;
  final Uint8List? logoBytes;

  const BusinessProfile({
    this.name = 'Acme Corp',
    this.email = 'contact@acme.com',
    this.phone = '+1 (555) 123-4567',
    this.address = '123 Business Rd, Tech City, CA 94000',
    this.logoBytes,
  });

  BusinessProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    Uint8List? logoBytes,
  }) {
    return BusinessProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      logoBytes: logoBytes ?? this.logoBytes,
    );
  }
}
