# 🥩 Ao Gosto Carnes App

Aplicativo Flutter oficial da **Ao Gosto Carnes**, boutique de carnes premium com mais de 10 unidades em Belo Horizonte.  
O app permite que clientes naveguem pelo catálogo, adicionem produtos ao carrinho, calculem frete via CEP, realizem checkout com endereço e telefone, e integrem com o backend WooCommerce.

---

## 📱 Visão Geral

Este projeto é um **aplicativo multiplataforma (Flutter)** conectado ao WooCommerce via REST API, com **backend em PHP + MySQL** responsável por cadastro local (onboarding de cliente e endereço).  
O app inclui:

- 🧭 Fluxo de **onboarding** (nome, telefone, CEP e endereço)
- 🛒 **Carrinho** global persistente
- 💳 **Checkout** em 2 etapas (dados + pagamento)
- 🚚 Cálculo de **taxa de entrega via CEP**
- 🌐 Integração com **WooCommerce REST API**
- 🗂️ Estrutura modular e reutilizável (controllers, services e widgets)

---

## 🏗️ Estrutura de Pastas

lib/
│
├── main.dart
│
├── api/
│ ├── product_service.dart
│ ├── shipping_service.dart
│ ├── onboarding_service.dart
│
├── models/
│ ├── product.dart
│ ├── cart_item.dart
│ ├── customer.dart
│
├── state/
│ ├── cart_controller.dart
│ ├── app_state.dart
│
├── screens/
│ ├── main_screen.dart
│ │
│ ├── home/
│ │ └── home_screen.dart
│ │
│ ├── onboarding/
│ │ ├── onboarding_flow.dart
│ │ ├── onboarding_gate.dart
│ │ └── onboarding_page.dart ← (versão antiga, pode ser deletada)
│ │
│ ├── cart/
│ │ └── cart_drawer.dart
│ │
│ ├── checkout/
│ │ ├── checkout_screen.dart
│ │ └── checkout_controller.dart
│ │
│ ├── product/
│ │ └── product_details_page.dart
│ │
│ └── splash/
│ └── splash_screen.dart
│
├── utils/
│ ├── app_colors.dart
│ ├── app_text_styles.dart
│ └── helpers.dart
│
└── widgets/
├── product_card.dart
├── app_button.dart
├── section_title.dart
└── custom_text_field.dart

yaml
Copiar código

---

## 🧩 Descrição dos Principais Módulos

### `main.dart`
Ponto de entrada do app.  
Inicializa o tema, o estado global e chama o **MainScreen**, que exibe a navegação principal e verifica o onboarding.

---

### 🟢 API

| Arquivo | Função |
|----------|--------|
| **product_service.dart** | Faz requisições REST para `/wp-json/wc/v3/products` no WooCommerce e retorna lista de produtos. |
| **shipping_service.dart** | Faz consulta à API de frete (`/wp-json/custom/v1/shipping-cost?cep=XXXXX`) e retorna valor da taxa. |
| **onboarding_service.dart** | Controla cadastro do cliente (nome, telefone, endereço), persistência local e busca de CEP via ViaCEP. |

---

### 🧠 Models

| Arquivo | Descrição |
|----------|------------|
| **product.dart** | Modelo do produto WooCommerce (`id`, `name`, `price`, `imageUrl`, `category`). |
| **cart_item.dart** | Estrutura de item no carrinho (`product`, `quantity`, `totalPrice`). |
| **customer.dart** | Modelo de cliente usado no onboarding e checkout. |

---

### ⚙️ State

| Arquivo | Função |
|----------|--------|
| **cart_controller.dart** | Controlador singleton do carrinho global (métodos `add`, `remove`, `increment`, `clear`). |
| **app_state.dart** | Armazena informações globais (cliente logado, configs, tema). |

---

### 🏠 Screens

#### **main_screen.dart**
Tela principal com **BottomNavigationBar**:
- Início 🏠  
- Categorias 🗂️  
- Pedidos 📄  
- Carrinho 🛒  

Integra com `CartController` e abre o **drawer lateral** do carrinho.

---

#### **home/home_screen.dart**
Tela inicial do app, com:
- Banners e destaques 🍖  
- Listas de produtos  
- Botão “+ Carrinho” integrado ao controller  

---

#### **onboarding/**
Fluxo inicial de cadastro.

- **onboarding_flow.dart** → controla as etapas (nome, telefone, CEP).  
- **onboarding_gate.dart** → decide se mostra o fluxo ou vai direto ao app.  
- **onboarding_page.dart** → versão antiga (pode ser deletada).  

**API conectada:** `onboarding_service.dart` → PHP → MySQL.

---

#### **cart/cart_drawer.dart**
Carrinho lateral animado:
- Lista de produtos  
- Subtotal, taxa e total  
- Botão **“Finalizar Compra”** que redireciona ao `CheckoutScreen`.

---

#### **checkout/checkout_screen.dart**
Checkout dividido em **duas etapas:**

1. **Onde e Quando** → endereço, telefone e tipo de entrega (🏠 Entrega / 🛵 Retirada)  
2. **Como Pagar** → (etapa futura: Pix, cartão etc.)  

Integra com:
- `CartController` (para total e itens)
- `OnboardingService` (para dados salvos)
- `ShippingService` (para cálculo de taxa via CEP)

---

#### **checkout/checkout_controller.dart**
Gerencia toda a lógica do checkout:
- Recupera dados persistidos (nome, telefone, endereço)
- Consulta o frete via `ShippingService`
- Calcula total com base no carrinho
- Gerencia o fluxo de etapas (stepper)

---

### 🎨 Utils

| Arquivo | Função |
|----------|--------|
| **app_colors.dart** | Paleta oficial: laranja `#FA4815`, gradientes e fundos. |
| **app_text_styles.dart** | Estilos de texto globais (títulos, legendas, preços). |
| **helpers.dart** | Funções auxiliares (formatar preço, validar CEP, etc). |

---

### 🧱 Widgets Reutilizáveis

| Arquivo | Descrição |
|----------|------------|
| **product_card.dart** | Card de produto com imagem, preço e badges (🔥 Oferta, 🥩 Angus, ❄️ Congelado). |
| **app_button.dart** | Botão laranja padronizado com bordas arredondadas. |
| **section_title.dart** | Cabeçalho de seção (ex: “Ofertas da Semana”). |
| **custom_text_field.dart** | Campos de texto com máscara (telefone, CEP). |

---

## 💾 Backend (PHP + MySQL)

### 📂 Estrutura no Servidor
/app/onboarding/
├── register.php
├── get_profile.php
└── update_address.php

pgsql
Copiar código

---

### 🧱 Banco de Dados: `u991329655_app`

#### Tabela `customers`
| Campo | Tipo | Descrição |
|-------|------|------------|
| `id` | INT | ID único do cliente |
| `name` | VARCHAR(100) | Nome completo |
| `phone` | VARCHAR(20) | Telefone (usado como identificador) |
| `created_at` | TIMESTAMP | Data do cadastro |

#### Tabela `customer_addresses`
| Campo | Tipo | Descrição |
|-------|------|------------|
| `id` | INT | ID único do endereço |
| `customer_id` | INT | FK → `customers.id` |
| `street` | VARCHAR(120) | Rua |
| `number` | VARCHAR(20) | Número |
| `complement` | VARCHAR(80) | Complemento |
| `neighborhood` | VARCHAR(80) | Bairro |
| `city` | VARCHAR(80) | Cidade |
| `state` | VARCHAR(2) | UF |
| `cep` | VARCHAR(9) | CEP |
| `created_at` | TIMESTAMP | Data de cadastro |

---

### 🔗 Relação

```sql
ALTER TABLE customer_addresses
ADD CONSTRAINT fk_customer
FOREIGN KEY (customer_id)
REFERENCES customers(id)
ON DELETE CASCADE;
🔁 Fluxo do Cadastro
O Flutter envia JSON para register.php:

json
Copiar código
{
  "customer": {
    "name": "João Silva",
    "phone": "31998501560"
  },
  "address": {
    "street": "Av. Mário Werneck",
    "number": "1550",
    "neighborhood": "Buritis",
    "city": "Belo Horizonte",
    "state": "MG",
    "cep": "30575-180"
  }
}
O PHP grava nas tabelas customers e customer_addresses.

Retorna:

json
Copiar código
{ "ok": true, "customer_id": 12 }
O app salva isso localmente via SharedPreferences.

🗓️ Roadmap
Etapa	Descrição	Status
🟢 1	Estrutura Flutter e navegação	✅
🟢 2	Integração WooCommerce / Produtos	✅
🟢 3	Carrinho global	✅
🟢 4	Onboarding (cadastro + CEP + telefone)	✅
🟢 5	Cálculo de taxa de entrega	✅
🟠 6	Checkout moderno (dados e frete)	✅
⚪ 7	Pagamentos (Pix / cartão / maquininha)	🚧
⚪ 8	Integração de pedidos reais (WooCommerce REST)	🚧
⚪ 9	Histórico de pedidos / login persistente	🚧
⚪ 10	Push notifications (Firebase Messaging)	🚧

