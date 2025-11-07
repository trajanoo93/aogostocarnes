// screens/home/home_screen.dart:

import 'package:flutter/material.dart';
import 'package:ao_gosto_app/utils/app_colors.dart';
import 'package:ao_gosto_app/api/product_service.dart';
import 'package:ao_gosto_app/models/product.dart';
import 'package:ao_gosto_app/widgets/product_card.dart';
import 'package:ao_gosto_app/screens/home/widgets/all_cuts_section.dart';

import 'package:ao_gosto_app/screens/home/widgets/section_hero.dart' as hero;
import 'package:ao_gosto_app/screens/home/widgets/search_filter.dart';
import 'package:ao_gosto_app/screens/home/widgets/section_header.dart' as header;
import 'package:ao_gosto_app/screens/home/widgets/product_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Campo de busca fixo do header
class _HeaderSearchBar extends StatelessWidget {
  const _HeaderSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // garante fundo branco sob a busca
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: const SearchFilter(),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final _scrollCtrl = ScrollController();

  /// controla o “encolher” da logo conforme rola
  bool _isCollapsed = false;

  // Ofertas
  late Future<List<Product>> _onSaleProducts;

  // Extras (IDs fixos)
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
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    // a partir de ~24px de scroll, consideramos “colapsado”
    final collapsed = _scrollCtrl.hasClients && _scrollCtrl.offset > 24;
    if (collapsed != _isCollapsed) {
      setState(() => _isCollapsed = collapsed);
    }
  }

  void _loadProducts() {
    _onSaleProducts = _productService.fetchOnSaleProducts();

    _paoDeAlho     = _productService.fetchProductsByCategory(_idPaoDeAlho);
    _espetos       = _productService.fetchProductsByCategory(_idEspetos);
    _pratosProntos = _productService.fetchProductsByCategory(_idPratosProntos);
    _bebidas       = _productService.fetchProductsByCategory(_idBebidas);
    _outros        = _productService.fetchProductsByCategory(_idOutros);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          // ====== HEADER DINÂMICO (logo encolhe e busca sempre visível) ======
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: _isCollapsed ? 0.6 : 0,
            // não queremos “área de toolbar” quando colapsar
            toolbarHeight: 0,
            expandedHeight: 168, // espaço para a logo “respirar”
            flexibleSpace: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  // Altura da logo varia um pouco ao rolar
                  height: _isCollapsed ? 52 : 62,
                  margin: const EdgeInsets.only(top: 10, bottom: 2), // suspiro acima da busca
                  child: Image.network(
                    'https://aogosto.com.br/delivery/wp-content/uploads/2023/12/Go-Express-fundo-400-x-200-px2-1.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Busca SEMPRE presente no “bottom” e pinada
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(68),
              child: _HeaderSearchBar(),
            ),
            // borda suave só quando rolar
            shape: _isCollapsed
                ? const Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.6),
                  )
                : null,
          ),

          // ====== HERO / BANNERS ======
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: hero.SectionHero(),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ====== OFERTAS DA SEMANA ======
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.backgroundSecondary,
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: header.SectionHeader(title: '🔥 Ofertas da Semana'),
                  ),
                  const SizedBox(height: 16),
                  ProductCarousel(productsFuture: _onSaleProducts),
                ],
              ),
            ),
          ),

          // ====== TODOS OS CORTES (bolhas + grid) ======
          const SliverToBoxAdapter(child: AllCutsSection()),

          // ====== EXTRAS ======
          _sliverSection(
            title: '🥖 O Clássico Acompanhamento',
            future: _paoDeAlho,
            onViewAll: () =>
                _openCategoryList('🥖 O Clássico Acompanhamento', _idPaoDeAlho),
            shaded: false,
          ),
          _sliverSection(
            title: '🍢 Praticidade na Grelha: Espetos',
            future: _espetos,
            onViewAll: () =>
                _openCategoryList('🍢 Praticidade na Grelha: Espetos', _idEspetos),
            shaded: true,
          ),
          _sliverSection(
            title: '🍲 Sabor de Casa: Pratos Prontos',
            future: _pratosProntos,
            onViewAll: () =>
                _openCategoryList('🍲 Sabor de Casa: Pratos Prontos', _idPratosProntos),
            shaded: false,
          ),

          // Bebidas
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.backgroundSecondary,
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: header.SectionHeader(
                      title: '🍻 Para Acompanhar: Bebidas',
                      onViewAll: () =>
                          _openCategoryList('🍻 Para Acompanhar: Bebidas', _idBebidas),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProductCarousel(productsFuture: _bebidas),
                ],
              ),
            ),
          ),

          _sliverSection(
            title: '🛒 Essenciais para o Churrasco',
            future: _outros,
            onViewAll: () =>
                _openCategoryList('🛒 Essenciais para o Churrasco', _idOutros),
            shaded: false,
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)), // espaço pro BottomNav
        ],
      ),
    );
  }

  // ====== HELPERS ======

  SliverToBoxAdapter _sliverSection({
    required String title,
    required Future<List<Product>> future,
    VoidCallback? onViewAll,
    bool shaded = false,
  }) {
    final child = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: header.SectionHeader(title: title, onViewAll: onViewAll),
        ),
        const SizedBox(height: 16),
        ProductCarousel(productsFuture: future),
      ],
    );

    return SliverToBoxAdapter(
      child: shaded
          ? Container(
              color: AppColors.backgroundSecondary,
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: child,
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: child,
            ),
    );
  }

  void _openCategoryList(String title, int categoryId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CategoryListPage(
          title: title,
          categoryId: categoryId,
          loader: (page) =>
              _productService.fetchProductsByCategory(categoryId, perPage: 40),
        ),
      ),
    );
  }
}

// ====== LISTAGEM "VER TODOS" (tela enxuta dentro do mesmo arquivo) ======

class _CategoryListPage extends StatefulWidget {
  final String title;
  final int categoryId;
  final Future<List<Product>> Function(int page) loader;

  const _CategoryListPage({
    required this.title,
    required this.categoryId,
    required this.loader,
  });

  @override
  State<_CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<_CategoryListPage> {
  final _items = <Product>[];
  int _page = 1;
  bool _loading = true;
  bool _end = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({bool loadMore = false}) async {
    if (_end) return;
    setState(() => _loading = true);
    final page = loadMore ? _page + 1 : 1;
    final list = await widget.loader(page);
    if (!mounted) return;
    setState(() {
      if (loadMore) {
        _page = page;
        _items.addAll(list);
      } else {
        _page = 1;
        _items
          ..clear()
          ..addAll(list);
      }
      _loading = false;
      if (list.isEmpty) _end = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetch(loadMore: false),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < _items.length) {
                      return ProductCard(product: _items[index]);
                    }
                    // loader card
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  },
                  childCount: _items.isEmpty
                      ? (_loading ? 4 : 0)
                      : _items.length + (_end ? 0 : 1),
                ),
              ),
            ),
            if (!_end && !_loading && _items.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: () => _fetch(loadMore: true),
                      icon: const Icon(Icons.expand_more_rounded),
                      label: const Text('Carregar mais'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
