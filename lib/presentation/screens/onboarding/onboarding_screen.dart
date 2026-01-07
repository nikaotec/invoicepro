import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'business_name_onboarding_screen.dart';
import 'payment_methods_onboarding_screen.dart';
import 'onboarding_complete_screen.dart';
import '../../providers/business_profile_provider.dart';
import '../../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  String? _businessName;
  Map<String, bool> _paymentMethodsEnabled = {};
  String? _defaultPaymentMethod;
  double? _taxRate;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onBack() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onSkip() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    // Save onboarding data to business profile
    final profileNotifier = ref.read(businessProfileProvider.notifier);

    profileNotifier.updateProfile(
      name: _businessName?.isNotEmpty == true ? _businessName : null,
      currency: 'USD', // Default currency, can be changed in settings
      taxRate: _taxRate ?? 0.0,
    );

    // Mark onboarding as completed
    await ref.read(onboardingNotifierProvider.notifier).markAsCompleted();

    // Navigation will be handled by the OnboardingCompleteScreen
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101622)
          : const Color(0xFFF6F6F8),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _onBack,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  TextButton(
                    onPressed: _onSkip,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.grey[400]
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: List.generate(_totalSteps, (index) {
                      final isActive = index <= _currentStep;
                      return Expanded(
                        child: Container(
                          height: 6,
                          margin: EdgeInsets.only(
                            right: index < _totalSteps - 1 ? 8 : 0,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF135BEC)
                                : (isDark
                                      ? Colors.grey[700]
                                      : Colors.grey[200]),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Step ${_currentStep + 1} of $_totalSteps',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: isDark
                          ? Colors.grey[400]
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  BusinessNameOnboardingScreen(
                    initialValue: _businessName,
                    onChanged: (value) {
                      setState(() {
                        _businessName = value;
                      });
                    },
                    onNext: _onNext,
                  ),
                  PaymentMethodsOnboardingScreen(
                    initialEnabled: _paymentMethodsEnabled.isEmpty
                        ? null
                        : _paymentMethodsEnabled,
                    initialDefault: _defaultPaymentMethod,
                    onEnabledChanged: (value) {
                      setState(() {
                        _paymentMethodsEnabled = value;
                      });
                    },
                    onDefaultChanged: (value) {
                      setState(() {
                        _defaultPaymentMethod = value;
                      });
                    },
                    onNext: _onNext,
                  ),
                  OnboardingCompleteScreen(
                    businessName: _businessName,
                    currency: 'USD', // Default currency
                    onComplete: _completeOnboarding,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
