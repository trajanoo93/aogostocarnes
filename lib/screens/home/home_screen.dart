// lib/screens/home/home_screen.dart - CORRIGIDO COM CATEGORIA 521
import 'package:flutter/material.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/api/product_service.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/screens/home/widgets/all_cuts_section.dart';
import 'package:ao_gosto_app/screens/home/widgets/section_hero.dart' as hero;
import 'package:ao_gosto_app/screens/home/widgets/search_filter.dart';
import 'package:ao_gosto_app/screens/home/widgets/product_carousel.dart';
import 'package:ao_gosto_app/screens/home/widgets/featured_banner.dart';
import 'package:ao_gosto_app/screens/home/widgets/kits_churrasco_section.dart';
import 'package:ao_gosto_app/screens/update/forced_update_screen.dart';

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
  static const _idPratosProntos = 521; // ✅ CATEGORIA MÃE (Massas + Tortas + Pratos Prontos)
  static const _idHamburgueres = 390;
  static const _idBebidas = 69;
  static const _idOutros = 62;

  late Future<List<Product>> _paoDeAlho;
  late Future<List<Product>> _espetos;
  late Future<List<Product>> _pratosProntos;
  late Future<List<Product>> _hamburgueres;
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
    _hamburgueres = _productService.fetchProductsByCategory(_idHamburgueres);
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
        // HEADER (LOGO + MENU) FIXO
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 68,
          flexibleSpace: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: SizedBox(
                height: 56,
                child: Stack(
                  children: [

                    // 🔥 ZONA SECRETA PARA ABRIR TELA DE UPDATE (DEBUG)
                    GestureDetector(
                      onLongPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ForcedUpdateScreen(),
                          ),
                        );
                      },
                      child: Container(
                        color: Colors.transparent,
                        height: 56,
                        width: double.infinity,
                      ),
                    ),

                    // LOGO CENTRAL
                    Center(
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        height: 36,
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
                                  .findRootAncestorStateOfType<ScaffoldState>();
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

          // SEARCH BAR FIXA
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchBarHeaderDelegate(),
          ),

          // HERO BANNER
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: hero.SectionHero(height: 180),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ✨ KITS CHURRASCO (PRIMEIRO CARROSSEL) ✨
          const SliverToBoxAdapter(
            child: KitsChurrascoSection(),
          ),

          // OFERTAS DA SEMANA
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
                        Row(
                          children: [
                            const Text(
                              'Ofertas da ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF18181B),
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
                                'Semana',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.local_offer_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Aproveite enquanto dura!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF71717A),
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
                imageUrl:
                    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=1600',
              ),
            ),
          ),

          // SESSÃO "TODOS OS CORTES"
          const SliverToBoxAdapter(child: AllCutsSection()),

          // ✨ OUTRAS SESSÕES ✨
          
          // Pão de Alho
          _section(
            title: 'Pão de Alho Irresistível',
            highlightWord: 'Alho',
            icon: Icons.bakery_dining_rounded,
            future: _paoDeAlho,
            subtitle: 'O clássico que não pode faltar',
          ),
          
          // Espetos
          _section(
            title: 'Praticidade na Grelha',
            highlightWord: 'Grelha',
            icon: Icons.dining_rounded,
            future: _espetos,
            subtitle: 'Espetos prontos para o churrasco',
          ),
          
          // ✅ Pratos Prontos (AGORA PUXA CATEGORIA 521)
          _section(
            title: 'Sabor de Casa',
            highlightWord: 'Casa',
            icon: Icons.restaurant_rounded,
            future: _pratosProntos,
            subtitle: 'Massas, tortas e pratos deliciosos',
          ),
          
          // Hambúrgueres
          _section(
            title: 'Hambúrgueres Premium',
            highlightWord: 'Premium',
            icon: Icons.lunch_dining_rounded,
            future: _hamburgueres,
            subtitle: 'Suculentos e irresistíveis',
          ),
          
          // Bebidas
          _section(
            title: 'Para Acompanhar',
            highlightWord: 'Acompanhar',
            icon: Icons.sports_bar_rounded,
            future: _bebidas,
          ),
          
          // Outros (Temperos)
          _section(
            title: 'Essenciais para o Churrasco',
            highlightWord: 'Essenciais',
            icon: Icons.local_fire_department_rounded,
            future: _outros,
            subtitle: 'Temperos e complementos',
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _section({
    required String title,
    required Future<List<Product>> future,
    String? subtitle,
    required String highlightWord,
    required IconData icon,
  }) {
    final parts = title.split(highlightWord);
    
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
                  Row(
                    children: [
                      if (parts.isNotEmpty && parts[0].isNotEmpty)
                        Text(
                          parts[0],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF18181B),
                          ),
                        ),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            AppColors.primary,
                            const Color(0xFFFF8C00),
                          ],
                        ).createShader(bounds),
                        child: Text(
                          highlightWord,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (parts.length > 1 && parts[1].isNotEmpty)
                        Text(
                          parts[1],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF18181B),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        icon,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF71717A),
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

// HEADER FIXO DA SEARCH BAR
class _SearchBarHeaderDelegate extends SliverPersistentHeaderDelegate {
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

    final double topPadding = _lerp(10, 4, t);
    final double bottomPadding = _lerp(10, 4, t);
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