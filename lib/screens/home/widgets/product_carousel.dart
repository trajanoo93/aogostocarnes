import 'package:flutter/material.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/widgets/product_card.dart';
import 'package:ao_gosto_app/state/cart_controller.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/screens/cart/cart_drawer.dart';
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
    this.itemWidth = 210,
    this.itemSpacing = 14,
    this.height = 340,
    this.imageFit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: height,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: height * 0.45,
            child: const Center(child: Text('Erro ao carregar produtos')),
          );
        }
        final products = snapshot.data ?? const <Product>[];
        if (products.isEmpty) {
          return SizedBox(
            height: height * 0.45,
            child: const Center(child: Text('Nenhum produto encontrado')),
          );
        }

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
                      MaterialPageRoute(builder: (_) => ProductDetailsPage(product: p)),
                    );
                  },
                  onAddToCart: () async {
                    CartController.instance.add(p);
                    await showCartDrawer(context);
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
