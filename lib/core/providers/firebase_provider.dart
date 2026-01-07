import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

/// Provider to check if Firebase is initialized
final firebaseInitializedProvider = FutureProvider<bool>((ref) async {
  try {
    await Firebase.app();
    return true;
  } catch (e) {
    return false;
  }
});

