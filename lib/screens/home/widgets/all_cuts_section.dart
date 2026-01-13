// lib/screens/home/widgets/all_cuts_section.dart - VERSÃO OTIMIZADA
import 'package:flutter/material.dart';
import 'package:ao_gosto_app/api/product_service.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/widgets/compact_product_card.dart';
import 'package:ao_gosto_app/screens/home/widgets/category_bubble.dart';
import 'package:ao_gosto_app/screens/product/product_details_page.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/screens/cart/cart_drawer.dart';
import 'package:ao_gosto_app/state/navigation_controller.dart';

class AllCutsSection extends StatefulWidget {
  const AllCutsSection({super.key});

  @override
  State<AllCutsSection> createState() => _AllCutsSectionState();
}

class _AllCutsSectionState extends State<AllCutsSection> {
  final _service = ProductService();

  final _categories = const [
    (name: 'Picanha', id: 33, img: 'assets/icons_category/picanha.webp'),
    (name: 'Boi', id: 34, img: 'assets/icons_category/boi.webp'),
    (name: 'Frango', id: 32, img: 'assets/icons_category/frango.webp'),
    (name: 'Porco', id: 44, img: 'assets/icons_category/porco.webp'),
    (name: 'Linguiça', id: 51, img: 'assets/icons_category/linguica.webp'),
    (name: 'Exótico', id: 55, img: 'assets/icons_category/jacare.webp'),
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
      perCategory: 20, // ✅ REDUZIDO DE 50 PARA 20
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Todos os ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF18181B),
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    const Color(0xFFFF8C00),
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'Cortes',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.restaurant_menu_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Explore nossa seleção premium',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    GestureDetector(
                      onTap: () => NavigationController.changeTab?.call(1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ver todos',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

         // AllCutsSection

SizedBox(
  height: 108, // em vez de 124 ou 110
  child: ListView.separated(
    padding: const EdgeInsets.symmetric(horizontal: 16),
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

          
          const SizedBox(height: 0),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FutureBuilder<List<Product>>(
              future: _allCutsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }
                
                final all = snap.data ?? const <Product>[];
                final filtered = all
                    .where((p) => p.categoryIds.contains(_activeCategoryId))
                    .toList();
                final visible = filtered.take(_visibleCount).toList();
                final remaining = filtered.length - visible.length;

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Nenhum produto encontrado'),
                  );
                }

                return Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: visible.length,
                      itemBuilder: (_, i) {
                        final p = visible[i];
                        return CompactProductCard(
                          product: p,
                          onTap: () => _openDetails(p),
                          onAddToCart: () => _addAndOpenCart(p),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    if (remaining > 0)
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              const Color(0xFFFF8C00),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _visibleCount = filtered.length),
                            borderRadius: BorderRadius.circular(14),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.expand_more_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Revelar os $remaining cortes restantes',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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