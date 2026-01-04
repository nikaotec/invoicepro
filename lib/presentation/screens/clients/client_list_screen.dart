import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/client_model.dart';
import '../../../data/services/client_service.dart';
import 'widgets/client_list_empty_state.dart';
import 'add_client_screen.dart';

// Provider for Client Service
final clientServiceProvider = Provider<ClientService>((ref) => ClientService());

// Provider for Client List
final clientListProvider = FutureProvider.autoDispose<List<Client>>((
  ref,
) async {
  final service = ref.watch(clientServiceProvider);
  return service.getClients();
});

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All Clients';
  List<Client>? _filteredClients;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterClients(List<Client> allClients, String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredClients = allClients.where((client) {
        final matchesQuery =
            client.name.toLowerCase().contains(lowerQuery) ||
            client.company.toLowerCase().contains(lowerQuery);

        if (!matchesQuery) return false;

        if (_selectedFilter == 'All Clients') return true;
        if (_selectedFilter == 'Outstanding' &&
            client.status == ClientStatus.overdue)
          return true;
        // logic for 'Top Accounts' or others could be added here

        return true; // Default fallthrough
      }).toList();
    });
  }

  Future<void> _refreshList() async {
    // Invalidate provider to re-fetch from service
    ref.invalidate(clientListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.background;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textMain = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondary = isDark ? Colors.grey[400]! : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, textMain, isDark),

            // Search & Filter
            // Only show search if there are clients or we are filtering
            if (clientsAsync.valueOrNull?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    _buildSearchBar(isDark, surfaceColor, textMain),
                    const SizedBox(height: 16),
                    _buildFilterTabs(isDark, surfaceColor, textSecondary),
                  ],
                ),
              ),

            // Client List
            Expanded(
              child: clientsAsync.when(
                data: (clients) {
                  if (clients.isEmpty) {
                    return ClientListEmptyState(
                      onImportContacts: () {
                        // For demo: Restore default mock data
                        final service = ref.read(clientServiceProvider);
                        service.resetClients();
                        _refreshList();
                      },
                      onAddDate: () {},
                    );
                  }

                  final displayList = _filteredClients ?? clients;

                  if (displayList.isEmpty && clients.isNotEmpty) {
                    return Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(color: textSecondary),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: displayList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildClientCard(
                        displayList[index],
                        isDark,
                        surfaceColor,
                        textMain,
                        textSecondary,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text(
                    'Error: $err',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),

            // Bottom Add Button (Always visible)
            _buildBottomBar(context, surfaceColor, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textMain, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.backgroundDark : AppColors.background)
            .withOpacity(0.95),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.centerLeft,
              child: Icon(Icons.arrow_back, color: textMain, size: 24),
            ),
          ),
          Expanded(
            child: Text(
              'Clients',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textMain,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Debug Actions Menu
          PopupMenuButton<String>(
            onSelected: (value) {
              final service = ref.read(clientServiceProvider);
              if (value == 'clear') {
                service.clearClients();
              } else if (value == 'reset') {
                service.resetClients();
              }
              _refreshList();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Debug: Clear All (Show Empty)'),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Text('Debug: Reset Data'),
              ),
            ],
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.centerRight,
              child: Icon(Icons.more_horiz, color: textMain, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color surfaceColor, Color textMain) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: textMain,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.grey[500] : AppColors.textSecondary,
          ),
          hintText: 'Search name, email, or company...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
        onChanged: (val) {
          final clients = ref.read(clientListProvider).value ?? [];
          _filterClients(clients, val);
        },
      ),
    );
  }

  Widget _buildFilterTabs(
    bool isDark,
    Color surfaceColor,
    Color textSecondary,
  ) {
    final tabs = ['All Clients', 'Outstanding', 'Top Accounts'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedFilter == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = tab;
                  // Re-apply filter
                  final clients = ref.read(clientListProvider).value ?? [];
                  _filterClients(clients, _searchController.text);
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.textPrimary)
                      : surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                        ),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClientCard(
    Client client,
    bool isDark,
    Color surfaceColor,
    Color textMain,
    Color textSecondary,
  ) {
    return InkWell(
      onTap: () {
        // Return selected client
        Navigator.pop(context, client);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
          ],
          border: Border.all(color: Colors.transparent),
        ),
        child: Column(
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: client.avatarGradient,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: client.initials.length > 2
                          ? Icon(
                              IconData(
                                client.initials == 'apartment'
                                    ? Icons.apartment.codePoint
                                    : Icons.storefront.codePoint,
                                fontFamily: 'MaterialIcons',
                              ),
                              size: 24,
                              color: isDark
                                  ? Colors.indigo[200]
                                  : Colors.indigo[600],
                            )
                          : Text(
                              client.initials,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.indigo[200]
                                    : AppColors.primary,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textMain,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          client.company,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: client.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: client.status.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        client.status.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: client.status.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: isDark ? Colors.grey[800] : Colors.grey[50]!,
            ),
            const SizedBox(height: 12),

            // Bottom Grid
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL BILLED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        client.totalBilled > 0
                            ? '\$${client.totalBilled.toStringAsFixed(2)}'
                            : '—',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textMain,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        client.creditLeft != null
                            ? 'CREDIT LEFT'
                            : (client.status == ClientStatus.newLead
                                  ? 'LAST ACTIVITY'
                                  : 'LAST INVOICE'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        client.creditLeft ?? client.lastActivityOrInvoice,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: client.status == ClientStatus.overdue
                              ? AppColors.error
                              : (client.creditLeft != null
                                    ? textSecondary
                                    : textMain),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    Color surfaceColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        32,
      ), // Safe area bottom padding handled by structure or manual
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () async {
            // Navigate to Add Client Screen
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddClientScreen()),
            );
            // Refresh list on return (in case a client was added)
            _refreshList();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add, size: 20, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Add New Client',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
