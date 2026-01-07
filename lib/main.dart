import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/onboarding_provider.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/dashboard/cash_flow_dashboard_screen.dart';
import 'presentation/screens/dashboard/dashboard_empty_screen.dart';
import 'presentation/screens/invoice/invoice_list_screen.dart';
import 'presentation/screens/invoice/new_invoice_screen.dart';
import 'presentation/screens/clients/clients_list_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/providers/invoice_provider.dart';
import 'core/utils/responsive_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase - Required for app to work
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    debugPrint(
      'Please check your google-services.json file and build.gradle configuration',
    );
    // Continue anyway - error will be shown in auth provider
  }

  runApp(const ProviderScope(child: InvoicelyProApp()));
}

class InvoicelyProApp extends ConsumerWidget {
  const InvoicelyProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);
    final onboardingCompletedAsync = ref.watch(onboardingCompletedProvider);
    final onboardingNotifier = ref.watch(onboardingNotifierProvider);

    // Determine which screen to show
    Widget homeScreen;
    if (!authState.isAuthenticated) {
      homeScreen = const LoginScreen();
    } else {
      // Check onboarding status - use notifier state if available, otherwise check async
      final isCompleted =
          onboardingNotifier ||
          onboardingCompletedAsync.maybeWhen(
            data: (v) => v,
            orElse: () => false,
          );

      if (!isCompleted) {
        // First time user - show onboarding
        homeScreen = const OnboardingScreen();
      } else {
        // Authenticated and onboarding completed - show main app
        homeScreen = const CashFlowDashboardScreen();
      }
    }

    return MaterialApp(
      title: 'Invoicely Pro',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: homeScreen,
    );
  }
}

/// Wrapper that shows the main app when authenticated
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const HomeScreen();
  }
}

/// Main home screen with adaptive navigation
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navItems = const [
    NavigationItem(
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard,
      label: 'Home',
    ),
    NavigationItem(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'Invoices',
    ),
    NavigationItem(
      icon: Icons.group_outlined,
      selectedIcon: Icons.group,
      label: 'Clients',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Watch the invoice state to determine if we have data
    final invoiceState = ref.watch(invoiceProvider);
    final hasNoInvoices = invoiceState.isEmpty;

    return ResponsiveBuilder(
      builder: (context, deviceType) {
        final isMobile = deviceType == DeviceType.mobile;

        return Scaffold(
          body: Row(
            children: [
              // Navigation Rail for tablet/desktop
              if (!isMobile)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: _navItems.map((item) {
                    return NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    );
                  }).toList(),
                ),

              // Main content
              Expanded(child: _buildScreen(_selectedIndex, hasNoInvoices)),
            ],
          ),

          // Bottom Navigation for mobile
          bottomNavigationBar: isMobile
              ? NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  destinations: _navItems.map((item) {
                    return NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label,
                    );
                  }).toList(),
                )
              : null,

          // Modern Floating Action Button (Only show if NOT in empty state for Dashboard)
          floatingActionButton:
              _selectedIndex < 2 && !(_selectedIndex == 0 && hasNoInvoices)
              ? Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.5),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                        spreadRadius: -12,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NewInvoiceScreen(),
                          ),
                        );
                      },
                      customBorder: const CircleBorder(),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildScreen(int index, bool hasNoInvoices) {
    switch (index) {
      case 0:
        return hasNoInvoices
            ? const DashboardEmptyScreen()
            : const CashFlowDashboardScreen();
      case 1:
        return const InvoiceListScreen();
      case 2:
        return const ClientsListScreen();
      case 3:
        return const SettingsScreen();
      default:
        return hasNoInvoices
            ? const DashboardEmptyScreen()
            : const CashFlowDashboardScreen();
    }
  }
}

/// Navigation item data
class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
