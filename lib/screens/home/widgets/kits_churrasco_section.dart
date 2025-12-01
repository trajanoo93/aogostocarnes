// lib/screens/home/widgets/kits_churrasco_section.dart
import 'package:flutter/material.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/api/product_service.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/screens/home/widgets/product_carousel.dart';

class SubcategoryData {
  final int id;
  final String name;

  const SubcategoryData({
    required this.id,
    required this.name,
  });
}

class KitsChurrascoSection extends StatefulWidget {
  const KitsChurrascoSection({super.key});

  @override
  State<KitsChurrascoSection> createState() => _KitsChurrascoSectionState();
}

class _KitsChurrascoSectionState extends State<KitsChurrascoSection> {
  final ProductService _productService = ProductService();
  
  // Subcategorias
  final List<SubcategoryData> _subcategories = const [
    SubcategoryData(id: 357, name: 'Até 5'),
    SubcategoryData(id: 358, name: 'Até 10'),
    SubcategoryData(id: 359, name: 'Até 15'),
    SubcategoryData(id: 360, name: 'Até 20'),
  ];
  
  int _selectedSubcategoryId = 357; // Até 5 por padrão
  late Future<List<Product>> _productsFuture;
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }
  
  void _loadProducts() {
    setState(() {
      _productsFuture = _productService.fetchProductsByCategory(
        _selectedSubcategoryId,
        perPage: 20,
      );
    });
  }
  
  void _selectSubcategory(int id) {
    if (_selectedSubcategoryId != id) {
      setState(() {
        _selectedSubcategoryId = id;
        _loadProducts();
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24), // ✅ Consistente com outras seções
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TÍTULO COMPACTO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título "Kits Churrasco"
                Row(
                  children: [
                    const Text(
                      'Kits ',
                      style: TextStyle(
                        fontSize: 20, // ✅ Mesmo tamanho das outras seções
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF18181B),
                        height: 1.1,
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
                        'Churrasco',
                        style: TextStyle(
                          fontSize: 20, // ✅ Mesmo tamanho
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.outdoor_grill_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                const Text(
                  'Escolha o kit perfeito',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16), // ✅ Consistente
          
          // SUBCATEGORIAS COMPACTAS
          SizedBox(
            height: 40, // ✅ Mais compacto
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _subcategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final subcategory = _subcategories[index];
                final isSelected = _selectedSubcategoryId == subcategory.id;
                
                return _SubcategoryChip(
                  name: subcategory.name,
                  isSelected: isSelected,
                  onTap: () => _selectSubcategory(subcategory.id),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // CARROSSEL DE PRODUTOS
          ProductCarousel(
            productsFuture: _productsFuture,
            height: 295,
            itemWidth: 170,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//                  CHIP DE SUBCATEGORIA COMPACTO
// ═══════════════════════════════════════════════════════════
class _SubcategoryChip extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _SubcategoryChip({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: 16, // ✅ Mais compacto
          vertical: 10,   // ✅ Mais compacto
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primary,
                    const Color(0xFFFF8C00),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Text(
          name, // ✅ Apenas "Até X"
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isSelected
                ? Colors.white
                : const Color(0xFF18181B),
          ),
        ),
      ),
    );
  }
}