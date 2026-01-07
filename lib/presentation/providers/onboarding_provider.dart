import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _onboardingCompletedKey = 'onboarding_completed';

/// Provider to check if onboarding is completed
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  } catch (e) {
    return false;
  }
});

/// Provider to mark onboarding as completed
final onboardingNotifierProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier();
});

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false) {
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_onboardingCompletedKey) ?? false;
    } catch (e) {
      state = false;
    }
  }

  Future<void> markAsCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
      state = true;
    } catch (e) {
      // Error saving, but continue
    }
  }

  Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, false);
      state = false;
    } catch (e) {
      // Error saving, but continue
    }
  }
}

