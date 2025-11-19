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
    final scrollOffset =
        _scrollCtrl.hasClients ? _scrollCtrl.offset : 0.0;
    final isScrolled = scrollOffset > 20;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // HEADER
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            expandedHeight: 150,

            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final isCollapsed =
                    constraints.maxHeight <= kToolbarHeight + 20;

                return Container(
                  decoration: BoxDecoration(
                    color: isCollapsed
                        ? Colors.white.withOpacity(0.92)
                        : Colors.white,
                    boxShadow: isCollapsed
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: isCollapsed ? 16 : 0,
                      sigmaY: isCollapsed ? 16 : 0,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Column(
                          children: [
                            // LOGO + MENU
                            SizedBox(
                              height: isCollapsed ? 48 : 60,
                              child: Stack(
                                children: [
                                  Center(
                                    child: AnimatedScale(
                                      scale:
                                          isCollapsed ? 0.88 : 1.0,
                                      duration: const Duration(
                                          milliseconds: 300),
                                      child: Image.network(
                                        'https://aogosto.com.br/delivery/wp-content/uploads/2023/12/Go-Express-fundo-400-x-200-px2-1.png',
                                        height: isCollapsed ? 46 : 58,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),

                                  // BOTÃO MENU
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Builder(
                                      builder: (context) {
                                        return IconButton(
                                          onPressed: () {
  final rootScaffold = context.findRootAncestorStateOfType<ScaffoldState>();
  rootScaffold?.openEndDrawer();
},
                                          icon: Icon(
                                            Icons.menu_rounded,
                                            size: 28,
                                            color: Colors.grey[800],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 4),
                            const SearchFilter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // HERO BANNER
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: hero.SectionHero(height: 180),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // OFERTAS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
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
              padding:
                  EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: FeaturedBanner(
                title: 'Churrasco Perfeito',
                subtitle:
                    'Os melhores cortes para seu final de semana',
                imageUrl:
                    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=1600',
              ),
            ),
          ),

          // SESSÕES
          const SliverToBoxAdapter(child: AllCutsSection()),

          _section(
            title: '🍞 O Clássico Acompanhamento',
            future: _paoDeAlho,
          ),
          _section(
            title: '🍢 Praticidade na Grelha',
            future: _espetos,
            subtitle: 'Espetos prontos para o churrasco',
          ),
          _section(
            title: '🍽️ Sabor de Casa',
            future: _pratosProntos,
            subtitle: 'Pratos prontos deliciosos',
          ),
          _section(
            title: '🥤 Para Acompanhar',
            future: _bebidas,
          ),
          _section(
            title: '⚡ Essenciais para o Churrasco',
            future: _outros,
          ),

          const SliverToBoxAdapter(
              child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // COMPONENTE DE SESSÃO
  SliverToBoxAdapter _section({
    required String title,
    required Future<List<Product>> future,
    String? subtitle,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 16),
            ProductCarousel(
              productsFuture: future,
              height: 295,
              itemWidth: 170,
            ),
          ],
        ),
      ),
    );
  }
}
