# Integração com Stripe e PayPal para Recebimento de Pagamentos

## 📋 Visão Geral

Este documento descreve como implementar a integração com Stripe e PayPal para permitir que os usuários do InvoicePro recebam pagamentos reais de seus clientes através de links de pagamento.

## 🎯 Objetivo

Permitir que os clientes paguem invoices diretamente através de links seguros usando:
- **Stripe** - Cartões de crédito/débito, Apple Pay, Google Pay
- **PayPal** - Conta PayPal, cartões via PayPal

## 🏗️ Arquitetura da Solução

### Fluxo de Pagamento Online

```
┌─────────────┐
│   Cliente   │
│  (recebe    │
│   link)     │
└──────┬──────┘
       │
       │ 1. Clica no link de pagamento
       ▼
┌─────────────────────────┐
│  InvoicePro Web/App     │
│  - Mostra invoice       │
│  - Botão "Pay Now"      │
└──────┬──────────────────┘
       │
       │ 2. Escolhe método de pagamento
       │    (Stripe ou PayPal)
       ▼
   ┌─────────┴─────────┐
   │                   │
   ▼                   ▼
┌──────────┐      ┌──────────┐
│  Stripe  │      │  PayPal  │
│ Gateway  │      │ Gateway  │
└────┬─────┘      └────┬─────┘
     │                 │
     │ 3. Processa     │ 3. Processa
     │    pagamento    │    pagamento
     │                 │
     ▼                 ▼
┌─────────────────────────┐
│  Backend (Firebase      │
│  Functions ou Server)   │
│  - Cria Payment Intent  │
│  - Processa webhook     │
└──────┬──────────────────┘
       │
       │ 4. Atualiza status
       ▼
┌─────────────────────────┐
│  Firestore/Database     │
│  - Marca invoice como   │
│    paid                 │
│  - Cria registro de     │
│    pagamento            │
└─────────────────────────┘
```

## 📦 Dependências Necessárias

### Flutter Packages

```yaml
dependencies:
  # Stripe
  flutter_stripe: ^11.1.0
  
  # PayPal (via web ou SDK nativo)
  webview_flutter: ^4.4.2  # Para integração PayPal via web
  url_launcher: ^6.2.5     # Para abrir PayPal em browser
  
  # HTTP para chamadas à API
  http: ^1.2.0
  
  # Deep linking para retornar ao app
  app_links: ^6.1.1
  
  # Já existentes no projeto
  firebase_core: ^2.31.0
  cloud_firestore: ^4.17.3
```

## 🔧 Implementação

### Opção 1: Backend Próprio (Recomendado)

Usar Firebase Functions ou backend próprio para:
- Criar Payment Intents no Stripe
- Criar Orders no PayPal
- Processar webhooks
- Atualizar invoices no Firestore

### Opção 2: Stripe Checkout / PayPal Buttons (Mais Simples)

Usar os produtos hospedados:
- **Stripe Checkout** - Página de pagamento hospedada
- **PayPal Smart Buttons** - Botões de pagamento embutidos

## 🎨 Interface do Usuário

### Tela de Pagamento (para o Cliente)

1. **Visualização da Invoice**
   - Detalhes da invoice
   - Valor total
   - Itens/Serviços
   - Informações do vendedor

2. **Seleção de Método de Pagamento**
   - Opção Stripe (cartões, Apple Pay, Google Pay)
   - Opção PayPal
   - Ícones visuais para cada método

3. **Processamento**
   - Tela de loading
   - Redirecionamento para gateway
   - Confirmação de sucesso/falha

## 🔐 Segurança

### Boas Práticas

1. **Nunca armazenar chaves secretas no app**
   - Usar backend para operações sensíveis
   - Chaves públicas apenas no cliente

2. **Validar pagamentos no backend**
   - Sempre verificar via webhooks
   - Não confiar apenas no retorno do cliente

3. **Usar HTTPS sempre**
   - TLS 1.2+ obrigatório
   - Certificados válidos

4. **Proteção contra fraude**
   - Rate limiting
   - Validação de valores
   - Logs de auditoria

## 📝 Estrutura de Dados

### Payment Intent (Stripe)

```dart
class PaymentIntent {
  final String id;
  final String invoiceId;
  final String stripePaymentIntentId;
  final double amount;
  final String currency;
  final PaymentIntentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
}
```

### PayPal Order

```dart
class PayPalOrder {
  final String id;
  final String invoiceId;
  final String paypalOrderId;
  final double amount;
  final String currency;
  final PayPalOrderStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
}
```

## 🔄 Fluxo de Integração

### 1. Criar Payment Link

Quando invoice é enviada, gerar link único:
```
https://invoicepro.app/pay/{invoiceId}/{token}
```

### 2. Cliente Acessa Link

- Abre tela de pagamento
- Mostra detalhes da invoice
- Permite escolher método

### 3. Processar Pagamento

#### Stripe Flow:
1. App chama backend → Cria Payment Intent
2. Backend retorna client_secret
3. App usa flutter_stripe para processar
4. Stripe processa pagamento
5. Webhook notifica backend
6. Backend atualiza invoice

#### PayPal Flow:
1. App chama backend → Cria Order
2. Backend retorna order_id e approval_url
3. App abre WebView com PayPal
4. Cliente aprova no PayPal
5. PayPal redireciona de volta
6. App confirma pagamento com backend
7. Backend atualiza invoice

## 🚀 Passos de Implementação

### Fase 1: Preparação
- [ ] Adicionar dependências
- [ ] Configurar contas Stripe/PayPal
- [ ] Criar estrutura de dados
- [ ] Configurar deep linking

### Fase 2: Backend (Firebase Functions)
- [ ] Criar função para Stripe Payment Intent
- [ ] Criar função para PayPal Order
- [ ] Implementar webhooks
- [ ] Criar função para atualizar invoice

### Fase 3: Frontend - Serviços
- [ ] PaymentService (abstração)
- [ ] StripePaymentService
- [ ] PayPalPaymentService
- [ ] Integração com providers

### Fase 4: Frontend - UI
- [ ] Tela de pagamento (public)
- [ ] Seleção de método
- [ ] Processamento de pagamento
- [ ] Tela de confirmação

### Fase 5: Integração
- [ ] Conectar com fluxo existente
- [ ] Atualizar InvoiceDetailScreen
- [ ] Adicionar links de pagamento
- [ ] Testes end-to-end

## 📚 Recursos

### Documentação
- [Stripe Flutter SDK](https://stripe.dev/stripe-flutter/)
- [PayPal SDK](https://developer.paypal.com/docs/checkout/)
- [Stripe Checkout](https://stripe.com/docs/payments/checkout)
- [Firebase Functions](https://firebase.google.com/docs/functions)

### Exemplos
- Stripe Flutter Examples
- PayPal Integration Guides
- Payment Gateway Best Practices

## ⚠️ Considerações

1. **Taxas**: Stripe (~2.9% + $0.30), PayPal (~2.9% + $0.30)
2. **Regiões**: Verificar disponibilidade por país
3. **Moedas**: Suporte multi-moeda
4. **Refund**: Implementar sistema de reembolsos
5. **Compliance**: PCI DSS, GDPR, etc.

