import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/dashboard/dashboard_empty_screen.dart';
import 'presentation/screens/invoice/invoice_list_screen.dart';
import 'presentation/screens/invoice/smart_invoice_creator_screen.dart';
import 'presentation/screens/clients/clients_list_screen.dart';

import 'presentation/screens/settings/business_settings_screen.dart';
import 'presentation/providers/invoice_provider.dart';
import 'core/utils/responsive_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialize Firebase
  // await Firebase.initializeApp();

  runApp(const ProviderScope(child: InvoicelyProApp()));
}

class InvoicelyProApp extends ConsumerWidget {
  const InvoicelyProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Invoicely Pro',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
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
                            builder: (context) =>
                                const SmartInvoiceCreatorScreen(),
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
            : const DashboardScreen();
      case 1:
        return const InvoiceListScreen();
      case 2:
        return const ClientsListScreen();
      case 3:
        return const BusinessSettingsScreen();
      default:
        return hasNoInvoices
            ? const DashboardEmptyScreen()
            : const DashboardScreen();
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
