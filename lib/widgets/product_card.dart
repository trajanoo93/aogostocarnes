import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aogosto_carnes_flutter/models/product.dart';
import 'package:aogosto_carnes_flutter/utils/app_colors.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onAddToCart;
  /// Tocar no card abre a página de detalhes
  final VoidCallback? onTap;
  /// Para trocar cover/contain onde precisar
  final BoxFit imageFit;

  const ProductCard({
    super.key,
    required this.product,
    this.onAddToCart,
    this.onTap,
    this.imageFit = BoxFit.cover,
  });

  bool get _isOffer =>
      product.regularPrice != null && product.regularPrice! > product.price;

  @override
  Widget build(BuildContext context) {
    final brl = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Stack(
          children: [
            Card(
              color: Colors.white,
              elevation: 2.5,
              shadowColor: Colors.black.withOpacity(0.07),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // IMAGEM
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: AspectRatio(
                      aspectRatio: 1.18,
                      child: Image.network(
                        product.imageUrl,
                        fit: imageFit,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE5E7EB),
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.black26,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // INFO
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.18,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Meta curta (peso aprox. / preço por kg)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (product.averageWeightGrams != null)
                              _metaPill('Aprox. ${product.averageWeightGrams!.toStringAsFixed(0)}g'),
                            if (product.pricePerKg != null)
                              Text(
                                '${brl.format(product.pricePerKg)} / kg',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Preço antigo (opcional)
                        if (_isOffer)
                          Text(
                            brl.format(product.regularPrice),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9CA3AF),
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                        // Preço atual
                        Text(
                          brl.format(product.price),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Badges (overlay topo-esquerda)
            Positioned(
              left: 12,
              top: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.isBestseller)
                    _badge('Mais vendido', const Color(0xFFF59E0B), Icons.workspace_premium_rounded),
                  if (product.isFrozen)
                    _badge('Congelado', const Color(0xFF3B82F6), Icons.ac_unit_rounded),
                  if (product.isChilled)
                    _badge('Resfriado', const Color(0xFF10B981), Icons.thermostat_rounded),
                  if (product.isSeasoned)
                    _badge('Temperado', const Color(0xFFEF4444), Icons.restaurant_menu_rounded),
                ],
              ),
            ),

            // Botão adicionar
            if (onAddToCart != null)
              Positioned(
                right: 12,
                bottom: 12,
                child: Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onAddToCart,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ------- auxiliares -------
  Widget _metaPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}