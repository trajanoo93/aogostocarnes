# 🥩 Ao Gosto Carnes — Aplicativo Oficial (Flutter)

Aplicativo oficial Flutter da Ao Gosto Carnes, boutique de carnes premium com +10 unidades em Belo Horizonte.
Um app moderno, rápido e totalmente integrado ao WooCommerce, Firestore e serviços internos da empresa.

---

## 📱 Status Atual

**✅ PRODUÇÃO:** Checkout 100% funcional + Histórico de Pedidos (Firestore) + Integração WooCommerce + Sistema de Categorias Completo + Perfil de Usuário

---

## 🌐 Visão Geral

O aplicativo foi desenvolvido em Flutter (multiplataforma) e integra:

- **WooCommerce REST API** → Catálogo, preços, estoque e criação de pedidos reais
- **Firebase Firestore** → **Perfil completo, múltiplos endereços e histórico de pedidos em tempo real**
- **ViaCEP + API Custom** → Cálculo de frete e definição da loja efetiva
- **Provider** → State management global (Customer + Cart)


✨ Fluxo de Inicialização (Onboarding + SplashScreen)

O aplicativo utiliza um fluxo moderno de inicialização baseado em gate + onboarding + splash, garantindo:

carregamento suave da interface

experiências consistentes

primeiras interações guiadas

tempo suficiente para pré-carregar dados iniciais (produtos, banners, categorias etc.)

🧭 Fluxo Completo
▶ Primeira vez abrindo o app

OnboardingGate detecta que onboarding_done = false

O app abre automaticamente o OnboardingFlow

Usuário preenche nome, telefone, CEP e endereço

Ao finalizar:

onboarding_done = true é salvo no SharedPreferences

O app exibe a SplashScreen animada (Lottie)

Após a animação → vai para o MainScreen

▶ A partir do segundo acesso

OnboardingGate detecta onboarding_done = true

Abre diretamente a SplashScreen

Após a animação → navega para o MainScreen

🔥 Estrutura Implementada
📌 onboarding_gate.dart

Controla o fluxo inicial do app:

if (needsOnboarding) {
  OnboardingFlow.maybeStart(context, force: true);
}

return const SplashScreen();


Sempre retorna a SplashScreen, garantindo uma transição visual suave independentemente de onboarding.

📌 onboarding_flow.dart

Ao concluir o onboarding, salva o status:

final sp = await SharedPreferences.getInstance();
await sp.setBool('onboarding_done', true);

📌 splash_screen.dart

Tela minimalista com animação Lottie:

fundo branco

logo animada

tempo de exibição: ~2,2s

redireciona automaticamente para o MainScreen:

Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => const MainScreen()),
);
---

## Atualização Forçada (Forced Update) — Controle Total

Sistema automático de atualização obrigatória implementado com **Firebase Hosting**.

### Como funciona:
- O app verifica ao abrir se a versão atual é menor que a mínima exigida
- Se sim → **trava o app** e força o usuário a atualizar
- Controle 100% remoto via JSON (sem precisar recompilar o app)

### Arquivo de controle:

https://ao-gosto-app-c0b31.web.app/app_version.json

### Tela de Force Update para o usuário ###

lib/screens/update/forced_update_screen.dart


## 🚀 Funcionalidades Implementadas

| Status | Funcionalidade |
|--------|----------------|
| ✔️ Done | Catálogo completo via WooCommerce |
| ✔️ Done | **Sistema de Categorias Completo (20 categorias)** |
| ✔️ Done | **Subcategorias Dinâmicas (Bovinos, Kits, Linguiças, etc)** |
| ✔️ Done | **Filtros: Todos, Churrasco, Dia a Dia, Fitness** |
| ✔️ Done | Carrinho global persistente (singleton) |
| ✔️ Done | Onboarding completo (nome, telefone, endereço) |
| ✔️ Done | **Perfil de Usuário Completo (Meu Perfil)** |
| ✔️ Done | **Gestão de Múltiplos Endereços** |
| ✔️ Done | **Busca de CEP com ViaCEP** |
| ✔️ Done | **Máscara de Telefone Brasileira** |
| ✔️ Done | **Menu Drawer Premium com Cashback** |
| ✔️ Done | Cálculo de frete via CEP + loja efetiva |
| ✔️ Done | Checkout em duas etapas com validação total |
| ✔️ Done | Agendamento inteligente (horários, domingos, feriados) |
| ✔️ Done | Métodos de pagamento: PIX, Dinheiro, Cartão, Vale |
| ✔️ Done | Criação de pedidos reais no WooCommerce |
| ✔️ Done | Histórico de pedidos em tempo real via Firestore |
| ✔️ Done | Status humanizados ("Registrado" → "Montado") |
| ✔️ Done | Imagens de produtos carregadas dinamicamente |
| ✔️ Done | KeepAlive para telas → performance máxima |
| ✔️ Done | Lottie e animações integradas |
| ✔️ Done | **Bottom Navigation corrigido (sem vão transparente)** |
| 🔜 Next | Push notifications |
| 🔜 Next | Busca avançada de produtos |
| 🔜 Next | Lista de compras / favoritos |

---

## 📁 Estrutura Completa de Pastas

```
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
│   ├── category_data.dart            ← ✨ NOVO: 20 categorias + subcategorias
│   └── order_model.dart              ← AppOrder, OrderItem, Address, PaymentMethod
│
├── state/
│   ├── cart_controller.dart          ← singleton do carrinho
│   └── checkout_controller.dart      ← lógica completa do checkout
│
├── screens/
│   ├── main_screen.dart              ← ✨ ATUALIZADO: Nav com Categorias + Perfil
│   │
│   ├── home/
│   │   └── home_screen.dart
│   │
│   ├── cart/
│   │   └── cart_drawer.dart
│   │
│   ├── categories/                    ← ✨ NOVO: Sistema completo de categorias
│   │   ├── categories_screen.dart    ← Grid de 20 categorias
│   │   └── category_detail_screen.dart ← Detalhes + subcategorias
│   │
│   ├── profile/                       ← ✨ NOVO: Perfil de usuário
│   │   └── meu_perfil.dart           ← Perfil + endereços + avatar
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
    ├── custom_text_field.dart
    ├── custom_bottom_navigation.dart  ← ✨ ATUALIZADO: Sem vão transparente
    └── header_menu_modal.dart         ← ✨ ATUALIZADO: Menu drawer premium
```
🧱 Estrutura de Pastas (atualização)

Adicione este novo item:

├── screens/
│   ├── splash/
│   │   └── splash_screen.dart       ← ✨ Nova Splash animada (Lottie)
---

## 🎯 NOVIDADES - Sistema de Categorias

### 📋 20 Categorias Reais:

#### Churrasco (16 categorias):
1. **Bovinos** (ID: 56)
   - Subcategorias: Todos, Acém, Ancho, Angus, Chorizo, Maminha, Cortes Gourmet, Cortes Magros, Costela

2. **Kits Prontos** (ID: 71)
   - Subcategorias: Todos, Até 5, Até 10, Até 15, Até 20

3. **Picanhas** (ID: 32)
4. **Porco** (ID: 44)
5. **Frango** (ID: 32)
6. **Exóticos** (ID: 55)
7. **Pescados** (ID: 63)

8. **Linguiças** (ID: 51)
   - Subcategorias: Todos, Linguiça Bovina, Linguiça Suína

9. **Pão de Alho** (ID: 73)
10. **Espetinhos Gourmet** (ID: 59)
11. **Queijos** (ID: 252)
12. **Hambúrgueres** (ID: 390)

13. **Massas e Pratos Prontos** (ID: 8)
    - Subcategorias: Todos, Massas, Massas e Tortas, Pratos Prontos

14. **Complementos** (ID: 377)
    - Subcategorias: Todos, Complementos, Molhos, Temperos

15. **Bebidas** (ID: 69)
16. **Boutique** (ID: 12)
17. **Outros** (ID: 62)

#### Dia a Dia (5 categorias):
1. **Linha Dia a Dia** (ID: 342)
2. **Forno** (ID: 53)
3. **Air Fryer** (ID: 350)
4. **Massas e Pratos Prontos** (ID: 8)
5. **Bebidas** (ID: 69)

#### Fitness (1 categoria):
1. **Linha Dia a Dia** (ID: 342)

### ✨ Features das Categorias:

- ✅ **Grid responsivo** com cards animados
- ✅ **Filtros inteligentes**: Todos, Churrasco, Dia a Dia, Fitness
- ✅ **Hero header** com imagem e gradiente
- ✅ **Subcategorias dinâmicas** para filtrar produtos
- ✅ **Busca em tempo real** dentro da categoria
- ✅ **Integração total** com WooCommerce API
- ✅ **Loading states** elegantes
- ✅ **Empty states** informativos

---

## 👤 Sistema de Perfil de Usuário

### 📱 Meu Perfil:

**Features:**
- ✅ Avatar com status online
- ✅ Edição de nome
- ✅ Edição de telefone (máscara brasileira)
- ✅ Gestão de múltiplos endereços
- ✅ Busca de CEP automática (ViaCEP)
- ✅ Endereço padrão marcado
- ✅ Apelidos personalizados para endereços
- ✅ Validação completa de campos

### 📍 Gestão de Endereços:

**Campos:**
- Apelido (Casa, Trabalho, etc)
- CEP (com busca automática)
- Rua, Número, Complemento
- Bairro, Cidade, Estado
- Marcar como padrão

**Ações:**
- ✅ Adicionar novo endereço
- ✅ Editar endereço existente
- ✅ Excluir endereço
- ✅ Definir como padrão

### 🎨 Menu Drawer Premium:

**Features:**
- ✅ Header com gradiente laranja
- ✅ Avatar com status online
- ✅ Badge de cashback disponível
- ✅ Botão voltar
- ✅ Logo no footer
- ✅ Items: Perfil, WhatsApp, Features em breve
- ✅ WhatsApp: +55 31 3461-3297

---

## 🔄 Fluxo Completo do Checkout

### 1. Usuário informa CEP

→ shipping_service retorna:

```json
{
  "store": "Unidade Sion",
  "store_id": 12,
  "shipping_cost": 7.90
}
```

### 2. checkout_controller guarda localmente

Sem latência. Sem redirecionamentos.

### 3. Usuário seleciona horário

**Regras (local):**

**Retirada:**
- Seg–Sáb: 09–12, 12–15, 15–18
- Domingo/Feriado: 09–12

**Entrega:**
- Seg–Sáb: 09–12, 12–15, 15–18, 18–20
- Domingo/Feriado: 09–12

### 4. Pagamento

PIX, Dinheiro, Cartão, Vale.

### 5. Pedido real enviado ao WooCommerce:

```json
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
```

---

## 🔥 Histórico em Tempo Real (Firestore)

Cada pedido é salvo no Firestore imediatamente após ser criado no WooCommerce.

**Estrutura:**

```json
{
  "id": "9876",
  "status": "montado",
  "items": [ ... ],
  "total": 199.90,
  "store": "Sion",
  "customer": { "name": "Guilherme", "phone": "31999999999" },
  "created_at": 1731433282
}
```

**Tela do app:**
- Lista animada com Lottie
- Status traduzidos
- Tracker moderno
- Produtos com imagens dinâmicas

---

## 🎨 Padrões Visuais

- **Tema primário:** `#FA4815` (AppColors.primary)
- **Tipografia:** Custom em `app_text_styles.dart`
- **Ícones:** Material Icons + Lottie animations
- **Bottom Nav:** Branco com blur + botão central laranja
- **Cards:** Bordas arredondadas 20px + sombras sutis
- **UI consistente** com a marca Ao Gosto Carnes

---

## 📱 Navegação Bottom Nav

| Índice | Tela | Descrição |
|--------|------|-----------|
| 0 | HomeScreen | Ofertas, categorias, produtos |
| 1 | CategoriesScreen | ✨ 20 categorias com filtros |
| 2 | OrdersScreen | Histórico de pedidos |
| 3 | MeuPerfilPage | ✨ Perfil + endereços |
| 4 | CartDrawer | Carrinho (botão central) |

---

## 🛣️ Roadmap Oficial

| Etapa | Status |
| ----- | ------ |
| Estrutura Flutter | ✔️ Done |
| Produtos via WooCommerce | ✔️ Done |
| Carrinho global | ✔️ Done |
| Onboarding | ✔️ Done |
| Frete por CEP | ✔️ Done |
| Checkout completo | ✔️ Done |
| Pedido real WooCommerce | ✔️ Done |
| Histórico Firestore | ✔️ Done |
| **Sistema de Categorias** | ✔️ Done |
| **Perfil de Usuário** | ✔️ Done |
| **Gestão de Endereços** | ✔️ Done |
| **Menu Drawer Premium** | ✔️ Done |
| Push Notifications | 🔜 Em breve |
| Busca Avançada | 🔜 Em breve |
| Filtros, favoritos | 🔜 Planejado |

---

## 💳 Sistema de Pagamento Online (Pagar.me)

### 🎯 Integração Completa

O app possui integração nativa com o **Pagar.me** para pagamentos via **PIX instantâneo**.

### 🔧 Arquitetura
```
lib/
├── config/
│   └── pagarme_credentials.dart    ← Credenciais unificadas
│
├── services/
│   └── pagarme_service.dart        ← Geração de PIX
│

```

---

### 🔥 Como Funciona

#### **1. Decisão da Loja Final**

O sistema determina automaticamente qual CD (Centro de Distribuição) irá processar o pedido:

**Entrega:**
- Baseado no CEP do cliente
- Considera horário de cutoff
- Retornado pelo `shipping_service`

**Retirada:**
- Loja selecionada pelo usuário
- IDs: `86261` (Central), `131813` (Lagoa Santa), `127163` (Sion), `110727` (Barreiro)
```dart
final effectiveStoreId = _getEffectiveStoreId();
final effectiveStoreName = _getEffectiveStoreName(effectiveStoreId);
```

---

#### **2. Geração do PIX**

Quando o usuário escolhe **PIX** como método de pagamento:
```dart
if (paymentMethod == 'pix') {
  final pagarmeService = PagarMeService();
  
  final pixResponse = await pagarmeService.generatePix(
    orderId: orderId!,
    storeFinal: effectiveStoreName,  // ← Conciliação bancária
    totalAmount: total,
    customerPhone: userPhoneRaw,
  );
  
  pixCode = pixResponse.qrCodeText;
  pixExpiresAt = pixResponse.expiresAt;
}
```

**Retorno do Pagar.me:**
- ✅ QR Code (texto para copiar)
- ✅ Data de expiração (60 minutos)
- ✅ ID da transação

---

#### **3. Credenciais Unificadas**
```dart
// config/pagarme_credentials.dart

class PagarMeCredentials {
  // ✅ CHAVE ÚNICA PARA TODAS AS LOJAS
  static const String apiKey = 'sk_2b9fa1c33b224ba19a13ee0880e61d25';
  
  // ✅ TIMEOUT DO PIX
  static const int pixExpiresIn = 3600; // 60 minutos
  
  // ✅ MAPEAMENTO DE LOJAS
  static const Map storeNames = {
    '86261': 'Central Distribuição (Sagrada Família)',
    '131813': 'Unidade Lagoa Santa',
    '127163': 'Unidade Sion',
    '110727': 'Unidade Barreiro',
  };
}
```

**💡 Por que uma única chave?**
- Simplifica a gestão de credenciais
- A diferenciação ocorre via **metadados**
- Relatórios financeiros filtram por `store_final`

---

#### **4. Metadados Enviados ao Pagar.me**
```json
{
  "metadata": {
    "store_final": "Unidade Sion",
    "order_id": "12345",
    "customer_phone": "31999999999",
    "customer_name": "João Silva",
    "delivery_type": "delivery"
  }
}
```

Esses dados permitem:
- ✅ Conciliação bancária por loja
- ✅ Rastreamento de pedidos
- ✅ Relatórios financeiros precisos

---

### 📊 Status dos Pedidos

#### **No WooCommerce:**

| Método | Status Inicial | Status após Pagamento |
|--------|----------------|------------------------|
| PIX | `pending` | *(atualizado manualmente)* |
| Dinheiro | `processing` | `processing` |
| Cartão | `processing` | `processing` |
| Vale | `processing` | `processing` |

**⚠️ Webhook não implementado:** Status PIX requer atualização manual no painel WooCommerce.

---

#### **No Firestore:**

Todos os pedidos são salvos instantaneamente com estrutura padronizada:
```json
{
  "id": "12345",
  "status": "-",
  "pagamento": {
    "metodo_principal": "Pix",
    "valor_total": 199.90,
    "taxa_entrega": 7.90
  },
  "agendamento": {
    "is_agendado": false,
    "janela_tempo": "18:00 - 20:00"
  },
  "cd": "CD Sion"
}

---

## 🔄 Sistema de Webhook Real-Time (WooCommerce → Firestore)

### 🎯 Arquitetura Completa
```
PIX pago → Pagar.me
     ↓
Plugin PHP → WooCommerce (status: processing)
     ↓
Webhook WooCommerce
     ↓
Cloud Function (Firebase)
     ↓
Firestore (atualiza status: processing)
     ↓
App Flutter (StreamBuilder detecta mudança)
     ↓
ThankYouScreen mostra: "✅ Pagamento Confirmado!"
```

---

### 🔧 Componentes

#### **1. Plugin PHP (Pagar.me Custom)**
```php
// wp-content/plugins/woocommerce-pagarme-custom/

add_action('woocommerce_order_status_changed', 'agosto_sync_order_status_to_firestore', 10, 4);

function agosto_sync_order_status_to_firestore($order_id, $old_status, $new_status, $order) {
    if ($new_status !== 'processing') return;
    
    $webhook_url = 'https://us-central1-ao-gosto-app-c0b31.cloudfunctions.net/woocommerceStatusWebhook';
    
    wp_remote_post($webhook_url, array(
        'headers' => array('Content-Type' => 'application/json'),
        'body'    => json_encode(array(
            'id'     => $order_id,
            'status' => $new_status,
        )),
    ));
}
```

#### **2. Cloud Function (Firebase)**
```javascript
// functions/index.js

exports.woocommerceStatusWebhook = functions.https.onRequest(async (req, res) => {
  const orderId = req.body.id.toString();
  const status = req.body.status;
  
  const docRef = db.collection("pedidos").doc(orderId);
  const doc = await docRef.get();
  
  if (!doc.exists) {
    return res.status(404).send("Order not found");
  }
  
  await docRef.set({
    status: status === "processing" ? "processing" : status,
    pagamento: { status_woocommerce: status },
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
  
  return res.status(200).send("OK");
});
```

#### **3. Backend Python (Proteção de Status)**
```python
# firestore_sync.py

def salvar_pedido_firestore(db, pedido_id, dados):
    doc_ref = db.collection("pedidos").document(pedido_id)
    doc = doc_ref.get()
    
    # ✅ NÃO SOBRESCREVE SE JÁ ESTÁ PAGO
    if doc.exists and doc.to_dict().get('status') == 'processing':
        dados_safe = {k: v for k, v in dados.items() if k != 'status'}
        doc_ref.set(dados_safe, merge=True)
        return True
    
    doc_ref.set(dados, merge=True)
    return True
```

#### **4. App Flutter (Real-Time)**
```dart
// thank_you_screen.dart

StreamBuilder<AppOrder?>(
  stream: FirestoreService().getOrderById(orderId),
  builder: (context, snapshot) {
    final status = snapshot.data?.status ?? '-';
    
    if (status == 'processing') {
      return _buildPaymentConfirmed(); // ✅ Pago!
    }
    
    return _buildPixPending(); // ⏳ Aguardando
  },
)
```

---

### ⚡ Fluxo de Atualização

1. **Usuário paga PIX** → Pagar.me detecta
2. **Pagar.me envia webhook** → Plugin PHP
3. **Plugin PHP muda status** → WooCommerce (processing)
4. **WooCommerce envia webhook** → Cloud Function
5. **Cloud Function atualiza** → Firestore (status: processing)
6. **App escuta Firestore** → StreamBuilder detecta mudança
7. **ThankYouScreen atualiza** → "✅ Pagamento Confirmado!"

**⏱️ Tempo total: 2-5 segundos (instantâneo para o usuário)**

---

### 🛡️ Proteção contra Conflitos

O backend Python **NÃO sobrescreve** o status se já estiver "processing":
```python
if existing_status == 'processing':
    # Remove status dos dados
    dados_safe = {k: v for k, v in dados.items() if k != 'status'}
    doc_ref.set(dados_safe, merge=True)
```

Isso garante que:
- ✅ PIX pago permanece "processing"
- ✅ App mostra status correto
- ✅ Backend continua processando (Sheets, WhatsApp, PDF)

---

### 📊 Estrutura Firestore
```
pedidos/
  ├── 132221/  (orderId)
      ├── id: "132221"
      ├── status: "processing"  ← Atualizado pelo webhook
      ├── cliente: { telefone: "5531999999999" }
      ├── pagamento: { 
          metodo_principal: "Pix",
          status_woocommerce: "processing"
      }
      ├── created_at: Timestamp
      ├── updated_at: Timestamp
```

---

### 🔮 Roadmap Webhook

| Feature | Status |
|---------|--------|
| Webhook WooCommerce → Firebase | ✅ Done |
| Atualização real-time no app | ✅ Done |
| Proteção contra sobrescrita | ✅ Done |
| Status "processing" instantâneo | ✅ Done |
| Logs de debug | ✅ Done |
| Retry automático | 🔜 Em breve |
| Notificação push | 🔜 Em breve |

---
---

### 🎨 UI do Pagamento PIX

**Features da tela:**
- ✅ QR Code visual (placeholder)
- ✅ Código PIX copiável (um clique)
- ✅ Timer de expiração (60 min)
- ✅ Feedback visual ao copiar
- ✅ Design moderno com gradientes

// screens/checkout/steps/step_payment.dart

class _ModernPixCard extends StatelessWidget {
  final String code;
  final DateTime expiresAt;
  
  // Exibe QR Code + código + timer
}


---

### 🔮 Roadmap Pagar.me

| Feature | Status |
|---------|--------|
| Geração de PIX | ✅ Done |
| QR Code copiável | ✅ Done |
| Timer de expiração | ✅ Done |
| Metadados completos | ✅ Done |
| Webhook automático | 🔜 Planejado |
| Cartão de crédito | 🔜 Em breve |
| Notificação push | 🔜 Em breve |

---


## 📊 Métricas de Qualidade

### Performance:
- ✅ KeepAlive em telas principais
- ✅ Lazy loading de imagens
- ✅ Cache de produtos (SharedPreferences)
- ✅ Query otimizada WooCommerce (`_fields`)
- ✅ Debounce em buscas

### UX:
- ✅ Loading states elegantes
- ✅ Empty states informativos
- ✅ Animações suaves (Lottie)
- ✅ Feedback visual em ações
- ✅ Navegação intuitiva

### Code Quality:
- ✅ Arquitetura modular
- ✅ Separação de concerns
- ✅ Services desacoplados
- ✅ State management eficiente
- ✅ Widgets reutilizáveis

---

## 🔧 Tecnologias

### Flutter Packages:
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State & Storage
  provider: ^6.0.5
  shared_preferences: ^2.2.0
  
  # Network
  http: ^1.1.0
  
  # Firebase
  cloud_firestore: ^4.13.0
  firebase_core: ^2.24.0
  
  # UI
  lottie: ^2.7.0
  cached_network_image: ^3.3.0
  
  # Utils
  intl: ^0.18.1
  url_launcher: ^6.2.1
  mask_text_input_formatter: ^2.5.0
```

---

## 🤝 Contribuição

Pull Requests são bem-vindos!
O projeto possui estrutura modular pensada para expansão contínua.

### Guidelines:
1. Seguir padrões de código existentes
2. Documentar novas features no README
3. Testar em iOS e Android
4. Commits descritivos em português

---

## 📎 Licença

Este projeto é **proprietário da Ao Gosto Carnes**.
Distribuição ou uso externo não autorizado é **proibido**.

---

## 📞 Contato

**WhatsApp:** +55 31 3461-3297
**Site:** aogosto.com.br

---

**🥩 Ao Gosto Carnes - A melhor experiência em carnes premium!**

**Versão:** 1.1.0 (Produção)
**Arquitetura:** Flutter + WooCommerce + Firebase Firestore (fonte única do cliente)
**Última atualização:** Novembro 2025