# Ao Gosto Carnes App

**Aplicativo Flutter oficial da Ao Gosto Carnes** — boutique de carnes premium com mais de 10 unidades em Belo Horizonte.  
O app permite que clientes naveguem pelo catálogo, adicionem produtos ao carrinho, calculem frete via CEP, realizem checkout completo com endereço, telefone, agendamento e pagamento, e **criem pedidos reais no WooCommerce**.

---

## Visão Geral

Este projeto é um **aplicativo multiplataforma (Flutter)** totalmente integrado ao **WooCommerce via REST API**, com **backend em PHP + MySQL** para cadastro local (onboarding de cliente e endereço).  

**Status atual**: **Checkout 100% funcional com pedidos reais criados no WooCommerce**

### Funcionalidades Implementadas

| Check | Funcionalidade |
|-------|----------------|
| Check | **Catálogo de produtos** (WooCommerce) |
| Check | **Carrinho global persistente** |
| Check | **Onboarding completo** (nome, telefone, CEP, endereço) |
| Check | **Cálculo de frete por CEP** (API custom) |
| Check | **Checkout em 2 etapas** (endereço + pagamento) |
| Check | **Agendamento com regras de horário** (seg-sáb, dom/feriados) |
| Check | **Métodos de pagamento** (PIX, Dinheiro, Cartão na entrega, Vale) |
| Check | **Criação de pedidos reais no WooCommerce** |
| Check | **ID do pedido real no Thank You** |
| Check | **Loja efetiva calculada localmente** (sem latência) |
| Check | **Validação obrigatória** (telefone, endereço, agendamento) |

---

## Estrutura de Pastas

lib/
│
├── main.dart
│
├── api/
│   ├── product_service.dart
│   ├── shipping_service.dart          ← retorna StoreInfo (nome + ID)
│   ├── onboarding_service.dart
│   └── order_service.dart             ← cria pedido real no WooCommerce
│
├── models/
│   ├── product.dart
│   ├── cart_item.dart
│   └── customer.dart
│
├── state/
│   ├── cart_controller.dart           ← carrinho global
│   └── app_state.dart
│
├── screens/
│   ├── main_screen.dart
│   │
│   ├── home/
│   │   └── home_screen.dart
│   │
│   ├── onboarding/
│   │   ├── onboarding_flow.dart
│   │   ├── onboarding_gate.dart
│   │   └── onboarding_page.dart (obsoleto)
│   │
│   ├── cart/
│   │   └── cart_drawer.dart
│   │
│   ├── checkout/
│   │   ├── checkout_screen.dart       ← 2 etapas + botão fixo
│   │   ├── checkout_controller.dart   ← lógica completa (sem store-decision)
│   │   ├── steps/
│   │   │   ├── step_address.dart      ← endereço, telefone, agendamento
│   │   │   └── step_payment.dart      ← PIX, dinheiro, cartão
│   │   └── widgets/
│   │       ├── calendar_widget.dart   ← modal com feriados
│   │       └── time_slot_grid.dart
│   │
│   ├── product/
│   │   └── product_details_page.dart
│   │
│   └── thank_you/
│       └── thank_you_screen.dart      ← ID real + botão voltar
│
├── utils/
│   ├── app_colors.dart
│   ├── app_text_styles.dart
│   └── helpers.dart
│
└── widgets/
├── product_card.dart
├── app_button.dart
├── section_title.dart
└── custom_text_field.dart



---

## Módulos Principais

### `main.dart`
- Inicializa tema, estado global
- Verifica onboarding → `OnboardingGate`

---

### API

| Arquivo | Função |
|--------|--------|
| **product_service.dart** | `/wp-json/wc/v3/products` → lista de produtos |
| **shipping_service.dart** | `/wp-json/custom/v1/shipping-cost?cep=XXXXX` → **retorna `StoreInfo` (nome + ID + custo)** |
| **onboarding_service.dart** | Cadastro local (MySQL) + ViaCEP |
| **order_service.dart** | `POST /wp-json/wc/v3/orders` → **cria pedido real** |

---

### State

| Arquivo | Função |
|--------|--------|
| **cart_controller.dart** | Singleton: `add`, `remove`, `increment`, `clear` |
| **checkout_controller.dart** | Gerencia todo o fluxo: frete, loja, agendamento, pagamento, pedido real |

---

### Screens

#### **main_screen.dart**
- `BottomNavigationBar`: Início, Categorias, Pedidos, Carrinho
- Drawer lateral com carrinho

#### **checkout/**
- **2 etapas**:
  1. **Onde e Quando?** → endereço, telefone, entrega/retirada, agendamento
  2. **Como Pagar?** → PIX, Dinheiro, Cartão na entrega, Vale
- **Botão fixo** com total
- **Validação obrigatória**

#### **thank_you_screen.dart**
- Exibe **ID real do WooCommerce**
- Botão "Voltar ao Início"

---

## Fluxo de Checkout (100% Local + Rápido)



    A[CEP digitado] --> B[shipping_service → StoreInfo]
    B --> C[salva storeInfo no controller]
    C --> D[Clica "Continuar"]
    D --> E[usa storeInfo → 0ms]
    E --> F[placeOrder() → WooCommerce]

    Sem store-decision → sem latência

    Regras de Agendamento (Local)

    // pickup
seg-sáb: 09-12, 12-15, 15-18
dom/feriado: 09-12

// delivery
seg-sáb: 09-12, 12-15, 15-18, 18-20
dom/feriado: 09-12

Pedido Real (WooCommerce)

{
  "status": "pending",
  "created_via": "App",
  "billing": { "company": "App", "email": "app@aogosto.com.br" },
  "line_items": [ ... ],
  "meta_data": [
    { "key": "_effective_store_final", "value": "Unidade Sion" },
    { "key": "delivery_date", "value": "2025-11-12" },
    { "key": "delivery_time", "value": "18:00 - 20:00" },
    { "key": "order_notes", "value": "Favor buzinar" }
  ]
}

Backend (PHP + MySQL)
Banco: u991329655_app
customers

Campo,Tipo
id,INT
name,VARCHAR(100)
phone,VARCHAR(20)

customer_addresses
Campo,Tipo
id,INT
customer_id,INT
"street, number, cep",VARCHAR

Roadmap

Etapa,Status
1. Estrutura Flutter,Done
2. Produtos WooCommerce,Done
3. Carrinho global,Done
4. Onboarding,Done
5. Frete por CEP,Done
6. Checkout (endereço),Done
7. Pagamentos + Pedido Real,Done
8. Histórico de pedidos,Next
9. Push notifications,Next