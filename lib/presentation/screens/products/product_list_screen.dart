import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/product_service.dart';
import 'widgets/product_list_empty_state.dart';

final productServiceProvider = Provider<ProductService>(
  (ref) => ProductService(),
);

final productListProvider = FutureProvider.autoDispose<List<Product>>((
  ref,
) async {
  final service = ref.watch(productServiceProvider);
  return service.getProducts();
});

class ProductListScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;

  const ProductListScreen({super.key, this.isSelectionMode = false});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product>? _filteredProducts;
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts(List<Product> allProducts, String query) {
    if (query.isEmpty) {
      setState(() => _filteredProducts = null);
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredProducts = allProducts.where((product) {
        return product.name.toLowerCase().contains(lowerQuery) ||
            product.description.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  void _toggleSelection(Product product) {
    setState(() {
      if (_selectedIds.contains(product.id)) {
        _selectedIds.remove(product.id);
      } else {
        _selectedIds.add(product.id);
      }
    });
  }

  Future<void> _refreshList() async {
    ref.invalidate(productListProvider);
  }

  Future<void> _addMockProduct() async {
    // For MVP phase: Add a mock product directly to test persistence
    // In future, this will open an AddProductScreen
    final service = ref.read(productServiceProvider);

    // Cycle through sample types from HTML
    final samples = [
      Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Consultoria Financeira',
        description: 'Análise mensal de fluxo de caixa',
        price: 1500.00,
        icon: 'analytics',
        colorValue: 0xFF5048E5, // Indigo
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Design de Logo',
        description: 'Identidade visual completa',
        price: 2000.00,
        icon: 'design_services',
        colorValue: 0xFFFF5722, // Deep Orange
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Manutenção Web',
        description: 'Atualizações de segurança',
        price: 300.00,
        icon: 'language',
        colorValue: 0xFF2196F3, // Blue
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ];

    // Pick random
    final newProduct =
        samples[DateTime.now().millisecondsSinceEpoch % samples.length];

    await service.addProduct(newProduct);
    _refreshList();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
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
            _buildHeader(textMain, isDark),

            // Search Bar (Sticky-ish)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ).copyWith(bottom: 16),
              child: _buildSearchBar(isDark, surfaceColor, textMain),
            ),

            // Product List
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  final displayList = _filteredProducts ?? products;

                  if (displayList.isEmpty) {
                    if (products.isEmpty) {
                      return ProductListEmptyState(
                        onAddProduct: _addMockProduct,
                      );
                    } else {
                      return Center(
                        child: Text(
                          'Nenhum produto encontrado',
                          style: TextStyle(color: textSecondary),
                        ),
                      );
                    }
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    itemCount: displayList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildProductCard(
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
          ],
        ),
      ),
      floatingActionButton: widget.isSelectionMode
          ? (_selectedIds.isNotEmpty
                ? FloatingActionButton.extended(
                    onPressed: () {
                      final products =
                          ref.read(productListProvider).value ?? [];
                      final selectedProducts = products
                          .where((p) => _selectedIds.contains(p.id))
                          .toList();
                      Navigator.pop(context, selectedProducts);
                    },
                    backgroundColor: AppColors.primary,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: Text(
                      'Adicionar (${_selectedIds.length})',
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : null)
          : FloatingActionButton(
              onPressed: _addMockProduct,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
    );
  }

  Widget _buildHeader(Color textMain, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: (isDark ? AppColors.backgroundDark : AppColors.background)
          .withOpacity(0.95),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Produtos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textMain,
              letterSpacing: -0.5,
            ),
          ),

          InkWell(
            onTap: () {}, // Tune/Filter action
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: Icon(Icons.tune, color: textMain, size: 24),
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
        style: TextStyle(color: textMain, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.grey[500] : AppColors.textSecondary,
            size: 22,
          ),
          hintText: 'Buscar por nome ou código...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[600] : Colors.grey[400],
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
        onChanged: (val) {
          final products = ref.read(productListProvider).value ?? [];
          _filterProducts(products, val);
        },
      ),
    );
  }

  Widget _buildProductCard(
    Product product,
    bool isDark,
    Color surfaceColor,
    Color textMain,
    Color textSecondary,
  ) {
    // Map string icon name to IconData (simplified mapping for MVP)
    IconData iconData = Icons.inventory_2;
    if (product.icon == 'analytics')
      iconData = Icons.analytics;
    else if (product.icon == 'design_services')
      iconData = Icons.design_services;
    else if (product.icon == 'language')
      iconData = Icons.language;
    else if (product.icon == 'campaign')
      iconData = Icons.campaign; // marketing
    else if (product.icon == 'cloud_queue')
      iconData = Icons.cloud_queue;
    else if (product.icon == 'build')
      iconData = Icons.build;

    final color = Color(product.colorValue);

    final isSelected = _selectedIds.contains(product.id);

    return InkWell(
      onTap: () {
        if (widget.isSelectionMode) {
          _toggleSelection(product);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.05)
              : surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
          ],
        ),
        child: Row(
          children: [
            // Selection Checkbox or Icon
            if (widget.isSelectionMode) ...[
              Container(
                margin: const EdgeInsets.only(right: 16),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],

            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                iconData,
                color: isDark ? color.withOpacity(0.8) : color,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textMain,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Price
            Text(
              'R\$ ${product.price.toStringAsFixed(2).replaceAll('.', ',')}', // Simple PT-BR formatting
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
