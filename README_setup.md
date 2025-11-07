# Ao Gosto Carnes — Starter Pack

Este pacote monta uma estrutura mínima **compilável** do app em Flutter com os arquivos que você já enviou,
mais _placeholders_ para os que estavam faltando.

## O que foi incluído/copied
- Copiados dos seus uploads para os diretórios corretos:
  - `lib/main.dart`
  - `lib/utils/app_theme.dart`
  - `lib/utils/app_colors.dart`
  - `lib/api/product_service.dart`
  - `lib/models/product.dart`
  - `lib/screens/main_screen.dart`
  - `lib/screens/home/home_screen.dart`
  - `lib/widgets/product_card.dart`
  - `lib/screens/home/widgets/banner_slider.dart`

- Criados (genéricos, prontos para compilar):
  - `lib/models/cart_item.dart`
  - `lib/screens/home/widgets/section_header.dart`
  - `lib/screens/home/widgets/search_filter_bar.dart`
  - `lib/screens/home/widgets/product_carousel.dart`
  - `assets/images/app_logo.png`
  - `pubspec.yaml` (com deps: `http`, `google_fonts`, `intl`, `carousel_slider`, etc.)

## Como usar
1. Copie a pasta `ao_gosto_app/` para o seu projeto (ou substitua apenas os arquivos que estavam faltando).
2. Rode:
   ```bash
   flutter pub get
   flutter run -d chrome   # ou seu device
   ```

> Observação: `ProductCarousel` espera um `Future<List<Product>>` via `productsFuture`, alinhado com seu `HomeScreen`.

Quando quisermos evoluir, é só me dizer qual parte quer refinar que eu altero aqui.
