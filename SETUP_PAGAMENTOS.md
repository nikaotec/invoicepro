# Setup de Integração Stripe e PayPal

## ⚠️ IMPORTANTE: Requisitos para Produção

A implementação atual usa **mock/placeholders** para desenvolvimento. Para produção, você **DEVE**:

1. **Criar um backend server** (Firebase Functions, Node.js, etc.)
2. **Nunca usar chaves secretas no app mobile**
3. **Sempre validar pagamentos via webhooks**

## 🔧 Configuração Inicial

### 1. Contas e Credenciais

#### Stripe
1. Criar conta em [stripe.com](https://stripe.com)
2. Obter chaves de API:
   - Publishable Key (usar no app)
   - Secret Key (APENAS no backend)
3. Configurar webhooks para receber notificações

#### PayPal
1. Criar conta comercial em [paypal.com/business](https://paypal.com/business)
2. Acessar [PayPal Developer](https://developer.paypal.com/)
3. Criar app e obter credenciais:
   - Client ID (usar no app)
   - Secret (APENAS no backend)

### 2. Backend (Obrigatório para Produção)

Crie endpoints no seu backend:

```
POST /api/create-payment-intent (Stripe)
  Body: { invoiceId, amount, currency, description }
  Response: { id, paymentIntentId, clientSecret }

POST /api/create-paypal-order (PayPal)
  Body: { invoiceId, amount, currency, description }
  Response: { id, orderId, approvalUrl }

POST /api/confirm-paypal-order
  Body: { orderId }
  Response: { success }

GET /api/payment-status/:paymentId
  Response: { status }
```

### 3. Configurar no App

Edite `lib/data/services/payment_service.dart`:

```dart
// Stripe
StripePaymentService(
  publishableKey: 'pk_test_...', // Sua chave pública
  backendUrl: 'https://seu-backend.com/api', // URL do seu backend
)

// PayPal
PayPalPaymentService(
  clientId: 'seu_client_id',
  backendUrl: 'https://seu-backend.com/api',
  isSandbox: false, // true para testes, false para produção
)
```

### 4. Inicializar Stripe (se usar SDK)

No `main.dart`:

```dart
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar Stripe
  Stripe.publishableKey = 'pk_test_...';
  Stripe.merchantIdentifier = 'merchant.com.yourapp';
  await Stripe.instance.applySettings();
  
  runApp(MyApp());
}
```

## 📱 Deep Linking (Opcional)

Para retornar ao app após pagamento PayPal:

1. Configurar URL schemes no `android/app/src/main/AndroidManifest.xml` e `ios/Runner/Info.plist`
2. Usar `app_links` package para capturar callbacks

## 🔄 Fluxo Completo

### Stripe Checkout (Recomendado para início)

1. Cliente clica em "Pay Online"
2. App chama backend → cria Payment Intent
3. Backend retorna `client_secret`
4. App abre Stripe Checkout (via URL ou SDK)
5. Cliente completa pagamento
6. Stripe webhook notifica backend
7. Backend atualiza invoice no Firestore
8. App sincroniza e mostra status atualizado

### PayPal Checkout

1. Cliente clica em "Pay Online" → escolhe PayPal
2. App chama backend → cria PayPal Order
3. Backend retorna `approval_url`
4. App abre WebView com URL do PayPal
5. Cliente aprova no PayPal
6. PayPal redireciona de volta
7. App confirma com backend usando `orderId`
8. Backend finaliza pagamento
9. Backend atualiza invoice no Firestore

## 🧪 Testes

### Stripe Test Cards

- Sucesso: `4242 4242 4242 4242`
- Falha: `4000 0000 0000 0002`
- 3D Secure: `4000 0027 6000 3184`

### PayPal Sandbox

- Use contas sandbox do PayPal Developer
- Teste com valores pequenos primeiro

## 📚 Recursos

- [Stripe Flutter SDK](https://stripe.dev/stripe-flutter/)
- [Stripe Checkout Docs](https://stripe.com/docs/payments/checkout)
- [PayPal Checkout Integration](https://developer.paypal.com/docs/checkout/)
- [Firebase Functions Example](https://github.com/stripe-samples/firebase-stripe-integration)

## ⚡ Quick Start (Desenvolvimento)

Para testar a UI sem backend:

1. A implementação atual já funciona com mocks
2. Você pode testar o fluxo de UI
3. Pagamentos não serão processados realmente
4. Configure o backend antes de ir para produção

## 🔐 Segurança

- ✅ Nunca commitar chaves secretas
- ✅ Usar variáveis de ambiente
- ✅ Validar todas as transações no backend
- ✅ Usar HTTPS sempre
- ✅ Implementar rate limiting
- ✅ Logar todas as transações
- ✅ Monitorar webhooks

