import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/business_profile.dart';

class BusinessProfileNotifier extends StateNotifier<BusinessProfile> {
  BusinessProfileNotifier() : super(const BusinessProfile());

  void updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
    dynamic
    logoBytes, // Using dynamic to avoid import issues, but should be Uint8List?
  }) {
    state = state.copyWith(
      name: name,
      email: email,
      phone: phone,
      address: address,
      logoBytes: logoBytes,
    );
  }
}

final businessProfileProvider =
    StateNotifierProvider<BusinessProfileNotifier, BusinessProfile>((ref) {
      return BusinessProfileNotifier();
    });
