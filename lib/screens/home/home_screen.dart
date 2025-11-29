// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/api/product_service.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/screens/home/widgets/all_cuts_section.dart';
import 'package:ao_gosto_app/screens/home/widgets/section_hero.dart' as hero;
import 'package:ao_gosto_app/screens/home/widgets/search_filter.dart';
import 'package:ao_gosto_app/screens/home/widgets/product_carousel.dart';
import 'package:ao_gosto_app/screens/home/widgets/featured_banner.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // ------------------------------------------------
          // HEADER (LOGO + MENU) FIXO
          // ------------------------------------------------
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 68, // um pouco mais compacto
            flexibleSpace: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: SizedBox(
                  height: 56,
                  child: Stack(
                    children: [
                      // LOGO CENTRAL (um pouco maior)
                      Center(
  child: Image.asset(
    'assets/icon/app_icon.png',
    height: 36,          // ajuste se quiser maior ou menor
    fit: BoxFit.contain,
  ),
),
                      // BOTÃO MENU À DIREITA
                      Align(
                        alignment: Alignment.centerRight,
                        child: Builder(
                          builder: (context) {
                            return IconButton(
                              onPressed: () {
                                final rootScaffold = context
                                    .findRootAncestorStateOfType<
                                        ScaffoldState>();
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
              ),
            ),
          ),

          // ------------------------------------------------
          // SEARCH BAR FIXA (SEGUNDA LINHA DO HEADER)
          // ------------------------------------------------
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchBarHeaderDelegate(),
          ),

          // ------------------------------------------------
          // HERO BANNER
          // ------------------------------------------------
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: hero.SectionHero(height: 180),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ------------------------------------------------
          // OFERTAS DA SEMANA
          // ------------------------------------------------
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
                      children: const [
                        Text(
                          '🔥 Ofertas da Semana',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Aproveite enquanto dura!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
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

          // ------------------------------------------------
          // BANNER DESTAQUE
          // ------------------------------------------------
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: FeaturedBanner(
                title: 'Churrasco Perfeito',
                subtitle: 'Os melhores cortes para seu final de semana',
                imageUrl:
                    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=1600',
              ),
            ),
          ),

          // ------------------------------------------------
          // SESSÃO "TODOS OS CORTES"
          // ------------------------------------------------
          const SliverToBoxAdapter(child: AllCutsSection()),

          // ------------------------------------------------
          // OUTRAS SESSÕES
          // ------------------------------------------------
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

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ------------------------------------------------
  // COMPONENTE DE SESSÃO
  // ------------------------------------------------
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
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

// ------------------------------------------------------
// HEADER FIXO DA SEARCH BAR (COMPACTA AO ROLAR)
// ------------------------------------------------------
class _SearchBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  // Alturas mínima e máxima do header da busca
  static const double _minHeight = 64;
  static const double _maxHeight = 84;

  @override
  double get minExtent => _minHeight;

  @override
  double get maxExtent => _maxHeight;

  double _lerp(double min, double max, double t) =>
      min + (max - min) * t.clamp(0.0, 1.0);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double delta = _maxHeight - _minHeight;
    final double t = delta == 0 ? 0 : (shrinkOffset / delta).clamp(0.0, 1.0);

    // Padding vai de 10 → 4 conforme rola
    final double topPadding = _lerp(10, 4, t);
    final double bottomPadding = _lerp(10, 4, t);

    // Search bar escala levemente (1.0 → 0.94) pra ficar mais compacta
    final double scale = _lerp(1.0, 0.94, t);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, bottomPadding),
      alignment: Alignment.center,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: const SearchFilter(),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchBarHeaderDelegate oldDelegate) => false;
}
