// lib/widgets/product_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onAddToCart;
  final VoidCallback? onTap;
  final BoxFit imageFit;

  const ProductCard({
    super.key,
    required this.product,
    this.onAddToCart,
    this.onTap,
    this.imageFit = BoxFit.cover,
  });

  bool get _isOffer => product.regularPrice != null && product.regularPrice! > product.price;

  String get _metaText {
    final List<String> parts = [];

    if (product.averageWeightGrams != null) {
      final weight = product.averageWeightGrams!;
      if (weight >= 1000) {
        parts.add('~${(weight / 1000).toStringAsFixed(1)}kg');
      } else {
        parts.add('~${weight.toStringAsFixed(0)}g');
      }
    }

    if (product.pricePerKg != null) {
      final brl = NumberFormat.simpleCurrency(locale: 'pt_BR');
      parts.add('${brl.format(product.pricePerKg)}/kg');
    }

    return parts.isEmpty ? '' : parts.join(' • ');
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
            children: [
              // IMAGEM + BADGES
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Image.network(
                        product.imageUrl,
                        fit: imageFit,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF5F5F5),
                          child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400]),
                        ),
                      ),
                    ),
                  ),

                  // Badges (bestseller, frozen, etc)
                  if (product.isBestseller || product.isFrozen || product.isChilled || product.isSeasoned)
                    Positioned(
                      left: 10,
                      top: 10,
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
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, size: 15, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Oferta', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                  // Botão +
                  if (onAddToCart != null)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Material(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 6,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onAddToCart,
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(Icons.add_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // INFORMAÇÕES
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    if (_metaText.isNotEmpty)
                      Text(
                        _metaText,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    if (_metaText.isNotEmpty) const SizedBox(height: 8),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isOffer)
                          Text(
                            brl.format(product.regularPrice),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (_isOffer) const SizedBox(height: 2),
                        Text(
                          brl.format(product.price),
                          style: const TextStyle(
                            fontSize: 18,
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
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
      ),
      child: Icon(icon, size: 14, color: Colors.white),
    );
  }
}