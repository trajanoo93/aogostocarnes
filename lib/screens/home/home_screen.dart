// lib/screens/home/home_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/api/product_service.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/screens/home/widgets/all_cuts_section.dart';
import 'package:ao_gosto_app/screens/home/widgets/section_hero.dart' as hero;
import 'package:ao_gosto_app/screens/home/widgets/search_filter.dart';
import 'package:ao_gosto_app/screens/home/widgets/product_carousel.dart';
import 'package:ao_gosto_app/screens/home/widgets/featured_banner.dart';
import 'package:ao_gosto_app/widgets/product_card.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final _scrollCtrl = ScrollController();

  // Ofertas e seções
  late Future<List<Product>> _onSaleProducts;
  static const _idPaoDeAlho = 73;
  static const _idEspetos = 59;
  static const _idPratosProntos = 172;
  static const _idBebidas = 69;
  static const _idOutros = 62;

  late Future<List<Product>> _paoDeAlho;
  late Future<List<Product>> _espetos;
  late Future<List<Product>> _pratosProntos;
  late Future<List<Product>> _bebidas;
  late Future<List<Product>> _outros;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _loadProducts() {
    _onSaleProducts = _productService.fetchOnSaleProducts();
    _paoDeAlho = _productService.fetchProductsByCategory(_idPaoDeAlho);
    _espetos = _productService.fetchProductsByCategory(_idEspetos);
    _pratosProntos = _productService.fetchProductsByCategory(_idPratosProntos);
    _bebidas = _productService.fetchProductsByCategory(_idBebidas);
    _outros = _productService.fetchProductsByCategory(_idOutros);
  }

  @override
  Widget build(BuildContext context) {
    final scrollOffset = _scrollCtrl.hasClients ? _scrollCtrl.offset : 0.0;
    final isScrolled = scrollOffset > 20;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // HEADER ORIGINAL (mantido)
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: isScrolled ? Colors.white.withOpacity(0.92) : Colors.white,
                  boxShadow: isScrolled
                      ? [BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )]
                      : null,
                ),
                child: BackdropFilter(
                  filter: isScrolled
                      ? ImageFilter.blur(sigmaX: 16, sigmaY: 16)
                      : ImageFilter.blur(sigmaX: 0),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Column(
                        children: [
                          SizedBox(
                            height: isScrolled ? 48 : 60,
                            child: Stack(
                              children: [
                                // Logo centro
                                Center(
                                  child: AnimatedScale(
                                    scale: isScrolled ? 0.88 : 1.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Image.network(
                                      'https://aogosto.com.br/delivery/wp-content/uploads/2023/12/Go-Express-fundo-400-x-200-px2-1.png',
                                      height: isScrolled ? 46 : 58,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                // Menu clean (direita)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                                    icon: Icon(
                                      Icons.menu_rounded,
                                      size: 28,
                                      color: Colors.grey[800],
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const SearchFilter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // HERO BANNER
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: hero.SectionHero(height: 180),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // OFERTAS DA SEMANA (BRANCO)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔥 Ofertas da Semana',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aproveite enquanto dura!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProductCarousel(
                    productsFuture: _onSaleProducts,
                    height: 295,
                    itemWidth: 170,
                  ),
                ],
              ),
            ),
          ),

          // BANNER DESTAQUE
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: FeaturedBanner(
                title: 'Churrasco Perfeito',
                subtitle: 'Os melhores cortes para seu final de semana',
                imageUrl: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=1600',
              ),
            ),
          ),

          // TODOS OS CORTES
          const SliverToBoxAdapter(child: AllCutsSection()),

          // PÃO DE ALHO (BRANCO)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '🍞 O Clássico Acompanhamento',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProductCarousel(
                    productsFuture: _paoDeAlho,
                    height: 295,
                    itemWidth: 170,
                  ),
                ],
              ),
            ),
          ),

          // ESPETOS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🍢 Praticidade na Grelha',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Espetos prontos para o churrasco',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProductCarousel(
                    productsFuture: _espetos,
                    height: 295,
                    itemWidth: 170,
                  ),
                ],
              ),
            ),
          ),

          // PRATOS PRONTOS (BRANCO)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🍽️ Sabor de Casa',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pratos prontos deliciosos',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProductCarousel(
                    productsFuture: _pratosProntos,
                    height: 295,
                    itemWidth: 170,
                  ),
                ],
              ),
            ),
          ),

          // BEBIDAS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '🥤 Para Acompanhar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProductCarousel(
                    productsFuture: _bebidas,
                    height: 295,
                    itemWidth: 170,
                  ),
                ],
              ),
            ),
          ),

          // OUTROS (BRANCO)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '⚡ Essenciais para o Churrasco',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProductCarousel(
                    productsFuture: _outros,
                    height: 295,
                    itemWidth: 170,
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}