// lib/screens/home/widgets/product_carousel.dart - ATUALIZADO COM MODAL
import 'package:flutter/material.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/widgets/product_card.dart';
import 'package:ao_gosto_app/widgets/variation_selector_modal.dart';
import 'package:ao_gosto_app/screens/product/product_details_page.dart';

class ProductCarousel extends StatelessWidget {
  final Future<List<Product>> productsFuture;
  final EdgeInsets padding;
  final double itemWidth;
  final double itemSpacing;
  final double height;
  final BoxFit imageFit;

  const ProductCarousel({
    super.key,
    required this.productsFuture,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.itemWidth = 170,
    this.itemSpacing = 12,
    this.height = 310,
    this.imageFit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: productsFuture,
      builder: (context, snapshot) {
        // SKELETON LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: height,
            child: ListView.separated(
              padding: padding,
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => SizedBox(width: itemSpacing),
              itemBuilder: (_, __) => _ProductSkeleton(width: itemWidth),
            ),
          );
        }

        // ERRO
        if (snapshot.hasError) {
          return SizedBox(
            height: height * 0.45,
            child: const Center(
              child: Text('Erro ao carregar produtos'),
            ),
          );
        }

        // VAZIO
        final products = snapshot.data ?? const <Product>[];
        if (products.isEmpty) {
          return SizedBox(
            height: height * 0.45,
            child: const Center(
              child: Text('Nenhum produto encontrado'),
            ),
          );
        }

        // PRODUTOS
        return SizedBox(
          height: height,
          child: ListView.separated(
            padding: padding,
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => SizedBox(width: itemSpacing),
            itemBuilder: (context, i) {
              final p = products[i];
              return SizedBox(
                width: itemWidth,
                child: ProductCard(
                  product: p,
                  imageFit: imageFit,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailsPage(product: p),
                      ),
                    );
                  },
                  // ✅ USA O MODAL PARA PRODUTOS COM VARIAÇÕES
                  onAddToCart: () async {
                    await showVariationSelector(
                      context: context,
                      product: p,
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Skeleton loading do card de produto
class _ProductSkeleton extends StatefulWidget {
  final double width;

  const _ProductSkeleton({required this.width});

  @override
  State<_ProductSkeleton> createState() => _ProductSkeletonState();
}

class _ProductSkeletonState extends State<_ProductSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem skeleton
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: const [
                        Color(0xFFEBEBEB),
                        Color(0xFFF4F4F4),
                        Color(0xFFEBEBEB),
                      ],
                      stops: [
                        _controller.value - 0.3,
                        _controller.value,
                        _controller.value + 0.3,
                      ],
                    ).createShader(bounds);
                  },
                  child: Container(
                    width: widget.width,
                    height: widget.width,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),

          // Info skeleton
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: const [
                            Color(0xFFEBEBEB),
                            Color(0xFFF4F4F4),
                            Color(0xFFEBEBEB),
                          ],
                          stops: [
                            _controller.value - 0.3,
                            _controller.value,
                            _controller.value + 0.3,
                          ],
                        ).createShader(bounds);
                      },
                      child: child!,
                    );
                  },
                  child: Container(
                    height: 14,
                    width: widget.width * 0.8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: const [
                            Color(0xFFEBEBEB),
                            Color(0xFFF4F4F4),
                            Color(0xFFEBEBEB),
                          ],
                          stops: [
                            _controller.value - 0.3,
                            _controller.value,
                            _controller.value + 0.3,
                          ],
                        ).createShader(bounds);
                      },
                      child: child!,
                    );
                  },
                  child: Container(
                    height: 14,
                    width: widget.width * 0.6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Preço
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: const [
                            Color(0xFFEBEBEB),
                            Color(0xFFF4F4F4),
                            Color(0xFFEBEBEB),
                          ],
                          stops: [
                            _controller.value - 0.3,
                            _controller.value,
                            _controller.value + 0.3,
                          ],
                        ).createShader(bounds);
                      },
                      child: child!,
                    );
                  },
                  child: Container(
                    height: 20,
                    width: widget.width * 0.5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}