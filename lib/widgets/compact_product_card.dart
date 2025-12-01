// lib/widgets/compact_product_card.dart - VERSÃO COMPACTA PARA GRID
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'dart:ui';

class CompactProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onAddToCart;
  final VoidCallback? onTap;
  final BoxFit imageFit;

  const CompactProductCard({
    super.key,
    required this.product,
    this.onAddToCart,
    this.onTap,
    this.imageFit = BoxFit.cover,
  });

  bool get _isOffer => product.regularPrice != null && product.regularPrice! > product.price;

  String get _weightText {
    if (product.averageWeightGrams == null) return '';
    final weight = product.averageWeightGrams!;
    return '~${weight.toStringAsFixed(0)}g';
  }

  @override
  Widget build(BuildContext context) {
    final brl = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // IMAGEM + BADGES (compacta)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 1.0, // ✅ Mantém proporção
                      child: Image.network(
                        product.imageUrl,
                        fit: imageFit,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF5F5F5),
                          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400]),
                        ),
                      ),
                    ),
                  ),

                  // Badges superiores
                  if (product.isBestseller || product.isFrozen || product.isChilled || product.isSeasoned)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Row(
                        children: [
                          if (product.isBestseller) _badge(Icons.star_rounded, const Color(0xFFF59E0B)),
                          if (product.isFrozen) _badge(Icons.ac_unit_rounded, const Color(0xFF3B82F6)),
                          if (product.isChilled) _badge(Icons.thermostat_rounded, const Color(0xFF10B981)),
                          if (product.isSeasoned) _badge(Icons.restaurant_menu_rounded, const Color(0xFFEF4444)),
                        ],
                      ),
                    ),

                  // Label OFERTA
                  if (_isOffer)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt, size: 12, color: Colors.white),
                                SizedBox(width: 3),
                                Text(
                                  'Oferta',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Badge de peso
                  if (product.averageWeightGrams != null && _weightText.isNotEmpty)
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.scale_rounded,
                                  size: 10,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _weightText,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Botão +
                  if (onAddToCart != null)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Material(
                            color: AppColors.primary.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(10),
                            elevation: 0,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: onAddToCart,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // INFORMAÇÕES (compactas)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nome do produto
                    SizedBox(
                      height: 28,
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 4),

                    // Preços
                    if (_isOffer) ...[
                      Text(
                        brl.format(product.regularPrice),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      brl.format(product.price),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.95),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(icon, size: 10, color: Colors.white),
    );
  }
}