// lib/screens/home/widgets/all_cuts_section.dart

import 'package:flutter/material.dart';
import 'package:ao_gosto_app/api/product_service.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/widgets/product_card.dart';
import 'package:ao_gosto_app/screens/home/widgets/category_bubble.dart';
import 'package:ao_gosto_app/screens/product/product_details_page.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/screens/cart/cart_drawer.dart';

class AllCutsSection extends StatefulWidget {
  const AllCutsSection({super.key});

  @override
  State<AllCutsSection> createState() => _AllCutsSectionState();
}

class _AllCutsSectionState extends State<AllCutsSection> {
  final _service = ProductService();

  // IDs e imagens (na ordem)
  final _categories = const [
    (name: 'Picanha', id: 33, img: 'https://images.unsplash.com/photo-1552528340-b41335f4f5f8?q=80&w=300&auto=format&fit=crop'),
    (name: 'Boi',     id: 34, img: 'https://images.unsplash.com/photo-1603360492579-3a3a0e404a36?q=80&w=300&auto=format&fit=crop'),
    (name: 'Frango',  id: 32, img: 'https://images.unsplash.com/photo-1626081598926-d18fa7a0b3f2?q=80&w=300&auto=format&fit=crop'),
    (name: 'Porco',   id: 44, img: 'https://images.unsplash.com/photo-1606043903698-7515b6d9e487?q=80&w=300&auto=format&fit=crop'),
    (name: 'Linguiça',id: 51, img: 'https://images.unsplash.com/photo-1594212699903-a41e1fcf7529?q=80&w=300&auto=format&fit=crop'),
    (name: 'Exótico', id: 55, img: 'https://images.unsplash.com/photo-1625862243769-d4e21a37a13c?q=80&w=300&auto-format&fit=crop'),
  ];

  late Future<List<Product>> _allCutsFuture;
  late int _activeCategoryId;
  int _visibleCount = 10;

  @override
  void initState() {
    super.initState();
    _activeCategoryId = _categories.first.id;
    _allCutsFuture = _service.fetchProductsByCategories(
      _categories.map((c) => c.id).toList(),
      perCategory: 50,
    );
  }

  void _openDetails(Product p) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailsPage(product: p)),
    );
  }

  Future<void> _addAndOpenCart(Product p) async {
    CartController.instance.add(p);
    await showCartDrawer(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Todos os Cortes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                TextButton(
                  onPressed: () {}, // se quiser, navega p/ uma listagem geral
                  child: const Text('Ver todos'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bubbles
          SizedBox(
            height: 124,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = _categories[i];
                return CategoryBubble(
                  name: c.name,
                  imageUrl: c.img,
                  active: _activeCategoryId == c.id,
                  onTap: () => setState(() {
                    _activeCategoryId = c.id;
                    _visibleCount = 10;
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FutureBuilder<List<Product>>(
              future: _allCutsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                }
                final all = snap.data ?? const <Product>[];
                final filtered = all.where((p) => p.categoryIds.contains(_activeCategoryId)).toList();
                final visible = filtered.take(_visibleCount).toList();
                final remaining = filtered.length - visible.length;

                if (filtered.isEmpty) {
                  return const Center(child: Text('Nenhum produto encontrado'));
                }

                return Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: visible.length,
                      itemBuilder: (_, i) {
                        final p = visible[i];
                        return ProductCard(
                          product: p,
                          onTap: () => _openDetails(p),
                          onAddToCart: () => _addAndOpenCart(p),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (remaining > 0)
                                     TextButton.icon(
  onPressed: () => setState(() => _visibleCount = filtered.length),
  icon: const Icon(Icons.expand_more_rounded),
  label: Text(
    'Revelar os $remaining cortes restantes',
    style: const TextStyle(fontWeight: FontWeight.w800),
  ),
  style: ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(AppColors.primary),
    foregroundColor: WidgetStatePropertyAll(Colors.white),
    padding: WidgetStatePropertyAll(const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
    overlayColor: WidgetStatePropertyAll(Colors.white.withOpacity(0.10)),
  ),
),

                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
