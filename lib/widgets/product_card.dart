// lib/widgets/product_card.dart - COMPLETO COM CACHE
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onAddToCart;
  final VoidCallback? onTap;
  final BoxFit imageFit; // ✅ MANTIDO

  const ProductCard({
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
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 170,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
              // ✨ IMAGEM COM CACHE
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: imageFit,
                        width: double.infinity,
                        
                        // Placeholder
                        placeholder: (context, url) => Container(
                          color: const Color(0xFFF3F4F6),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.grey.shade400,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Erro
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFFF5F5F5),
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey[400],
                          ),
                        ),
                        
                        // Cache otimizado
                        fadeInDuration: const Duration(milliseconds: 300),
                        memCacheWidth: 400,
                        memCacheHeight: 400,
                      ),
                    ),
                  ),

                  // Badges superiores
                  if (product.isBestseller || product.isFrozen || product.isChilled || product.isSeasoned)
                    Positioned(
                      left: 8,
                      top: 8,
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
                      right: 8,
                      top: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Oferta',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
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
                      left: 8,
                      bottom: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(10),
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
                                  size: 11,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _weightText,
                                  style: TextStyle(
                                    fontSize: 10,
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
                      right: 8,
                      bottom: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Material(
                            color: AppColors.primary.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(12),
                            elevation: 0,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: onAddToCart,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // INFORMAÇÕES
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nome do produto
                    SizedBox(
                      height: 32,
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 6),

                    // Preços
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isOffer)
                          Text(
                            brl.format(product.regularPrice),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (_isOffer) const SizedBox(height: 2),
                        Text(
                          brl.format(product.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
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
      margin: const EdgeInsets.only(right: 5),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.95),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(icon, size: 12, color: Colors.white),
    );
  }
}