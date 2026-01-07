import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/client_model.dart';
import '../../providers/client_repository_provider.dart';
import '../../providers/client_stats_provider.dart';
import 'add_client_screen.dart';

// Search query provider
final clientSearchProvider = StateProvider<String>((ref) => '');

class ClientsListScreen extends ConsumerStatefulWidget {
  final bool selectMode;

  const ClientsListScreen({
    super.key,
    this.selectMode = false,
  });

  @override
  ConsumerState<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends ConsumerState<ClientsListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final searchQuery = ref.watch(clientSearchProvider);
    final clientsAsync = ref.watch(clientListProvider);
    final statsAsync = ref.watch(clientStatsProvider);
    final overallStatsAsync = ref.watch(overallClientStatsProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            _buildHeader(context, isDark, widget.selectMode),

            // Search Bar
            _buildSearchBar(context, isDark),

            // Summary Stats
            overallStatsAsync.when(
              data: (stats) => _buildSummaryStats(context, isDark, stats),
              loading: () => const SizedBox(height: 120),
              error: (_, __) => const SizedBox(height: 120),
            ),

            // List Header
            _buildListHeader(context, isDark),

            // Client List
            Expanded(
              child: clientsAsync.when(
                data: (clients) {
                  // Filter clients by search query
                  final filteredClients = searchQuery.isEmpty
                      ? clients
                      : clients.where((client) {
                          final query = searchQuery.toLowerCase();
                          return client.name.toLowerCase().contains(query) ||
                              client.company.toLowerCase().contains(query) ||
                              client.email.toLowerCase().contains(query);
                        }).toList();

                  if (filteredClients.isEmpty) {
                    return _buildEmptyState(context, isDark, searchQuery.isNotEmpty);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = filteredClients[index];
                      return statsAsync.when(
                        data: (statsMap) {
                          final stats = statsMap[client.id] ?? const ClientStats();
                          return _buildClientCard(
                            context,
                            isDark,
                            client,
                            stats,
                            widget.selectMode,
                          );
                        },
                        loading: () => _buildClientCard(
                          context,
                          isDark,
                          client,
                          const ClientStats(),
                          widget.selectMode,
                        ),
                        error: (_, __) => _buildClientCard(
                          context,
                          isDark,
                          client,
                          const ClientStats(),
                          widget.selectMode,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
            Text(
                        'Error loading clients',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddClientScreen(),
            ),
          ).then((_) {
            // Refresh clients list
            ref.invalidate(clientListProvider);
            ref.invalidate(clientStatsProvider);
            ref.invalidate(overallClientStatsProvider);
          });
        },
        backgroundColor: const Color(0xFF135BEC),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, bool selectMode) {
    final canPop = Navigator.canPop(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8))
            .withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (canPop || selectMode)
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              Text(
                selectMode ? 'Select Client' : 'My Clients',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          if (!selectMode)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF135BEC).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Color(0xFF135BEC)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddClientScreen(),
                    ),
                  ).then((_) {
                    ref.invalidate(clientListProvider);
                    ref.invalidate(clientStatsProvider);
                    ref.invalidate(overallClientStatsProvider);
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(
                Icons.search,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                size: 22,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(clientSearchProvider.notifier).state = value;
                },
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by name or company...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                size: 22,
              ),
              onPressed: () {
                // TODO: Implement filter
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStats(
    BuildContext context,
    bool isDark,
    Map<String, dynamic> stats,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Total Clients Card
            _buildStatCard(
              context,
              isDark,
              title: 'Total Clients',
              value: stats['totalClients']?.toString() ?? '0',
              subtitle: '+${stats['newClientsThisMonth'] ?? 0} this month',
              icon: Icons.people,
              iconColor: const Color(0xFF135BEC),
              isPositive: true,
            ),
            const SizedBox(width: 12),
            // Outstanding Card
            _buildStatCard(
              context,
              isDark,
              title: 'Outstanding',
              value: _formatCurrency(stats['totalOutstanding'] ?? 0.0),
              subtitle: '${stats['pendingInvoices'] ?? 0} invoices pending',
              icon: Icons.pending,
              iconColor: Colors.orange,
              isPositive: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    bool isDark, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isPositive,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withOpacity(0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (isPositive)
                    Icon(
                      Icons.trending_up,
                      size: 14,
                      color: Colors.green,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isPositive
                          ? Colors.green
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'All Clients',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement sort
            },
            child: const Text(
              'Sort by',
              style: TextStyle(
                color: Color(0xFF135BEC),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(
    BuildContext context,
    bool isDark,
    Client client,
    ClientStats stats,
    bool selectMode,
  ) {
    final riskLevel = stats.riskLevel;
    Color riskColor;
    Color riskBgColor;

    switch (riskLevel) {
      case 'High Risk':
        riskColor = isDark ? Colors.red[400]! : Colors.red[600]!;
        riskBgColor = isDark
            ? Colors.red[900]!.withOpacity(0.3)
            : Colors.red[50]!;
        break;
      case 'Medium Risk':
        riskColor = isDark ? Colors.orange[400]! : Colors.orange[600]!;
        riskBgColor = isDark
            ? Colors.orange[900]!.withOpacity(0.3)
            : Colors.orange[50]!;
        break;
      default: // Low Risk
        riskColor = isDark ? Colors.green[400]! : Colors.green[600]!;
        riskBgColor = isDark
            ? Colors.green[900]!.withOpacity(0.3)
            : Colors.green[50]!;
    }

    final delayColor = stats.averageDelay > 30
        ? (isDark ? Colors.red[400] : Colors.red[600])
        : (stats.averageDelay > 10
            ? (isDark ? Colors.orange[400] : Colors.orange[600])
            : (isDark ? Colors.grey[300] : Colors.grey[700]));

    return InkWell(
      onTap: () {
        if (selectMode) {
          // Return selected client to previous screen
          Navigator.of(context).pop(client);
        } else {
          // TODO: Navigate to client details
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header: Avatar, Name, Risk Badge
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
                        color: _getAvatarBackgroundColor(client.initials, isDark),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.grey[600]! : Colors.grey[200]!,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          client.initials,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getAvatarColor(client.initials),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and Contact
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.company,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          client.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Risk Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    riskLevel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Divider
            Divider(
              color: isDark ? Colors.grey[700] : Colors.grey[200],
              height: 1,
            ),

            const SizedBox(height: 12),

            // Stats: Total Invoiced and Avg Delay
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Total Invoiced
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Invoiced',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(symbol: '\$', decimalDigits: 2)
                          .format(stats.totalInvoiced),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [const FontFeature.tabularFigures()],
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                // Avg Delay
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Avg Delay',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.averageDelay.toStringAsFixed(0)} days',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: delayColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No clients found' : 'No clients yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try a different search term'
                : 'Add your first client to start managing contacts',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String initials) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Orange
      const Color(0xFF0EA5E9), // Sky
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF14B8A6), // Teal
    ];
    final index = initials.hashCode % colors.length;
    return colors[index.abs()];
  }

  Color _getAvatarBackgroundColor(String initials, bool isDark) {
    final color = _getAvatarColor(initials);
    return isDark ? color.withOpacity(0.3) : color.withOpacity(0.1);
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000) {
      final kValue = amount / 1000;
      if (kValue >= 10) {
        return '\$${kValue.toStringAsFixed(0)}k';
      } else {
        return '\$${kValue.toStringAsFixed(1)}k';
      }
    }
    return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(amount);
  }
}

// Client List Provider
final clientListProvider = FutureProvider<List<Client>>((ref) async {
  final repository = ref.read(clientRepositoryProvider);
  final result = await repository.getClients();

  if (result.error != null) {
    throw Exception(result.error!.message);
  }

  // Convert domain entities to UI models
  final clients = result.data ?? [];
  return clients.map((domainClient) {
    // Generate initials
    final nameParts = domainClient.name.split(' ');
    final initials = nameParts.length >= 2
        ? (nameParts[0][0] + nameParts[1][0]).toUpperCase()
        : domainClient.name.substring(0, domainClient.name.length >= 2 ? 2 : 1)
            .toUpperCase();

    // Use name as company if no company field exists
    final company = domainClient.name;

    return Client(
      id: domainClient.id,
      name: domainClient.name,
      company: company,
      email: domainClient.email,
      status: ClientStatus.active, // Default status
      totalBilled: 0.0, // Will be calculated by stats provider
      lastActivityOrInvoice: 'Recently',
      initials: initials,
      avatarGradient: [
        _getColorForInitials(initials),
        _getColorForInitials(initials).withOpacity(0.5),
      ],
    );
  }).toList();
});

Color _getColorForInitials(String initials) {
  final colors = [
    const Color(0xFF6366F1),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFF0EA5E9),
    const Color(0xFF8B5CF6),
    const Color(0xFF14B8A6),
  ];
  final index = initials.hashCode % colors.length;
  return colors[index.abs()];
}
