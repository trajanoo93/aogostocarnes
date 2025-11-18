🥩 Ao Gosto Carnes — Aplicativo Oficial (Flutter)

Aplicativo oficial Flutter da Ao Gosto Carnes, boutique de carnes premium com +10 unidades em Belo Horizonte.
Um app moderno, rápido e totalmente integrado ao WooCommerce, Firestore e serviços internos da empresa.

📱 Status Atual:
Checkout 100% funcional + Histórico de Pedidos (Firestore) + Integração WooCommerce em produção

🌐 Visão Geral

O aplicativo foi desenvolvido em Flutter (multiplataforma) e integra:

WooCommerce REST API → Catálogo, preços, estoque e criação de pedidos reais

Firebase Firestore → Histórico de pedidos em tempo real + tracker

Backend PHP + MySQL → Cadastro local via onboarding

ViaCEP + API Custom → Cálculo de frete e definição da loja efetiva

Animações Lottie → UI fluida e moderna

Persistência local → Carrinho e informações do cliente

🚀 Funcionalidades Implementadas
Status	Funcionalidade
✔️ Done	Catálogo completo via WooCommerce
✔️ Done	Carrinho global persistente (singleton)
✔️ Done	Onboarding completo (nome, telefone, endereço)
✔️ Done	Cálculo de frete via CEP + loja efetiva
✔️ Done	Checkout em duas etapas com validação total
✔️ Done	Agendamento inteligente (horários, domingos, feriados)
✔️ Done	Métodos de pagamento: PIX, Dinheiro, Cartão, Vale
✔️ Done	Criação de pedidos reais no WooCommerce
✔️ Done	Histórico de pedidos em tempo real via Firestore
✔️ Done	Status humanizados ("Registrado" → "Montado")
✔️ Done	Imagens de produtos carregadas dinamicamente
✔️ Done	KeepAlive para telas → performance máxima
✔️ Done	Lottie e animações integradas
🔜 Next	Push notifications
🔜 Next	Filtros e buscas avançadas
🔜 Next	Lista de compras / favoritos


📁 Estrutura Completa de Pastas

lib/
├── main.dart                         ← inicialização, tema, e onboarding gate
│
├── api/
│   ├── product_service.dart          ← lista produtos do WooCommerce
│   ├── shipping_service.dart         ← retorna StoreInfo + custo por CEP
│   ├── onboarding_service.dart       ← cadastro local (PHP + MySQL) + ViaCEP
│   ├── order_service.dart            ← cria pedido real no WooCommerce
│   ├── firestore_service.dart        ← salva e lê pedidos em tempo real
│   └── product_image_service.dart    ← busca imagens por nome do produto
│
├── models/
│   ├── product.dart
│   ├── cart_item.dart
│   ├── customer.dart
│   └── order_model.dart              ← AppOrder, OrderItem, Address, PaymentMethod
│
├── state/
│   ├── cart_controller.dart          ← singleton do carrinho
│   └── checkout_controller.dart      ← lógica completa do checkout
│
├── screens/
│   ├── main_screen.dart
│   │
│   ├── home/
│   │   └── home_screen.dart
│   │
│   ├── cart/
│   │   └── cart_drawer.dart
│   │
│   ├── onboarding/
│   │   ├── onboarding_flow.dart
│   │   ├── onboarding_gate.dart
│   │   └── onboarding_page.dart (legado)
│   │
│   ├── checkout/
│   │   ├── checkout_screen.dart
│   │   ├── checkout_controller.dart
│   │   ├── steps/
│   │   │   ├── step_address.dart    ← endereço, telefone, agendamento
│   │   │   └── step_payment.dart    ← métodos de pagamento
│   │   └── widgets/
│   │       ├── calendar_widget.dart ← modal com feriados
│   │       └── time_slot_grid.dart
│   │
│   ├── product/
│   │   └── product_details_page.dart
│   │
│   ├── thank_you/
│   │   └── thank_you_screen.dart    ← mostra ID real + voltar ao início
│   │
│   └── orders/
│       ├── orders_screen.dart       ← lista animada com Lottie
│       └── order_detail_screen.dart ← tracker moderno + avaliação
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


🔄 Fluxo Completo do Checkout
1. Usuário informa CEP

→ shipping_service retorna:

{
  "store": "Unidade Sion",
  "store_id": 12,
  "shipping_cost": 7.90
}


2. checkout_controller guarda localmente

Sem latência. Sem redirecionamentos.

3. Usuário seleciona horário

Regras (local):

Retirada

Seg–Sáb: 09–12, 12–15, 15–18

Domingo/Feriado: 09–12

Entrega

Seg–Sáb: 09–12, 12–15, 15–18, 18–20

Domingo/Feriado: 09–12

4. Pagamento

PIX, Dinheiro, Cartão, Vale.

5. Pedido real enviado ao WooCommerce:

{
  "status": "pending",
  "created_via": "App",
  "billing": {
    "company": "App",
    "email": "app@aogosto.com.br"
  },
  "line_items": [...],
  "meta_data": [
    { "key": "_effective_store_final", "value": "Unidade Sion" },
    { "key": "delivery_date", "value": "2025-11-12" },
    { "key": "delivery_time", "value": "18:00 - 20:00" },
    { "key": "order_notes", "value": "Favor buzinar" }
  ]
}


🔥 Histórico em Tempo Real (Firestore)

Cada pedido é salvo no Firestore imediatamente após ser criado no WooCommerce.

Estrutura:

{
  "id": "9876",
  "status": "montado",
  "items": [ ... ],
  "total": 199.90,
  "store": "Sion",
  "customer": { "name": "Guilherme", "phone": "31999999999" },
  "created_at": 1731433282
}


Tela do app:

Lista animada com Lottie

Status traduzidos

Tracker moderno

Produtos com imagens dinâmicas

🗄️ Backend (PHP + MySQL)

Banco: u991329655_app

Tabelas

customers

| Campo | Tipo         |
| ----- | ------------ |
| id    | INT          |
| name  | VARCHAR(100) |
| phone | VARCHAR(20)  |


customer_addresses
| Campo               | Tipo    |
| ------------------- | ------- |
| id                  | INT     |
| customer_id         | INT     |
| street, number, cep | VARCHAR |


🛣️ Roadmap Oficial

| Etapa                      | Status       |
| -------------------------- | ------------ |
| Estrutura Flutter          | ✔️ Done      |
| Produtos via WooCommerce   | ✔️ Done      |
| Carrinho global            | ✔️ Done      |
| Onboarding                 | ✔️ Done      |
| Frete por CEP              | ✔️ Done      |
| Checkout completo          | ✔️ Done      |
| Pedido real WooCommerce    | ✔️ Done      |
| Histórico Firestore        | ✔️ Done      |
| Push Notifications         | 🔜 Em breve  |
| Melhorias UI/UX            | 🔜 Em breve  |
| Filtros, buscas, favoritos | 🔜 Planejado |


🎨 Padrões Visuais

Tema baseado em AppColors primário: #FA4815

Tipografia custom em app_text_styles.dart

Ícones e animações Lottie

UI consistente com a marca Ao Gosto Carnes


🤝 Contribuição

Pull Requests são bem-vindos!
O projeto possui estrutura modular pensada para expansão contínua.

📎 Licença

Este projeto é proprietário da Ao Gosto Carnes.
Distribuição ou uso externo não autorizado é proibido.



