import 'package:flutter/material.dart';

class ProductListEmptyState extends StatelessWidget {
  final VoidCallback onAddProduct;

  const ProductListEmptyState({super.key, required this.onAddProduct});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Using colors consistent with HTML design
    final textMain = isDark ? Colors.white : const Color(0xFF111827);
    final textSub = isDark ? Colors.grey[400] : const Color(0xFF6B7280);
    final primary = const Color(0xFF5048E5);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Stack
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Circle (Soft Glow)
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.05),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
                // Box Icon
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: primary.withOpacity(0.5),
                ),
                // Search Icon (Small)
                Positioned(
                  right: 20,
                  bottom: 24,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2D) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.search_off, size: 20, color: textSub),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Sua lista de produtos está vazia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione produtos ou serviços para\ncomeçar a criar faturas mais rápido.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textSub, height: 1.5),
          ),

          const SizedBox(height: 32),

          // Action Button
          ElevatedButton.icon(
            onPressed: onAddProduct,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Adicionar Primeiro Produto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 4,
              shadowColor: primary.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
