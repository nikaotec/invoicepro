# Fluxo de Pagamento de Invoices

## 📋 Visão Geral

O fluxo de pagamento no InvoicePro segue um processo estruturado que permite registrar pagamentos parciais ou totais, atualizar automaticamente o status da invoice e calcular valores pendentes.

## 🔄 Fluxo Completo

### 1. Estados da Invoice

As invoices podem ter os seguintes status:
- **`draft`**: Rascunho (ainda não enviada)
- **`sent`**: Enviada ao cliente (aguardando pagamento)
- **`paid`**: Totalmente paga
- **`overdue`**: Atrasada (vencida e não paga)
- **`cancelled`**: Cancelada

### 2. Fluxo de Pagamento

```
┌─────────────────┐
│  Invoice Criada │
│    (draft)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Invoice Enviada│
│     (sent)      │
└────────┬────────┘
         │
         │ Cliente recebe invoice
         │ (via link, email, etc)
         │
         ▼
┌─────────────────┐
│ Pagamento Parcial│
│   ou Total      │
└────────┬────────┘
         │
         │ Registrar Payment
         │ - amount: valor pago
         │ - method: método usado
         │ - date: data do pagamento
         │
         ▼
┌─────────────────┐
│ Verificar Total │
│   Pago vs Total │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌──────────┐
│Total   │ │Parcial   │
│Pago    │ │Pago      │
└───┬────┘ └────┬─────┘
    │           │
    ▼           │
┌──────────┐    │
│Status =  │    │
│  paid    │    │
└──────────┘    │
                │
                ▼
         ┌──────────────┐
         │Status = sent │
         │(mantém)      │
         └──────────────┘
```

### 3. Processo Detalhado

#### 3.1. Invoice Enviada (Status: `sent`)

- Invoice é criada e enviada ao cliente
- Status inicial: `sent`
- Valor total: ex: $1,000.00
- Valor pago: $0.00
- Valor pendente: $1,000.00

#### 3.2. Registro de Pagamento

Quando um pagamento é recebido, deve-se registrar:

```dart
Payment payment = Payment(
  id: 'unique_id',
  invoiceId: invoice.id,
  amount: 500.00,  // Valor do pagamento
  date: DateTime.now(),
  method: PaymentMethod.bankTransfer,
  notes: 'Transferência bancária',
  createdAt: DateTime.now(),
);
```

#### 3.3. Cálculo de Valores

Após registrar o pagamento:

1. **Buscar todos os pagamentos da invoice**
   ```dart
   List<Payment> payments = getPaymentsByInvoiceId(invoiceId);
   ```

2. **Calcular total pago**
   ```dart
   double totalPaid = payments.fold(0.0, (sum, payment) => sum + payment.amount);
   ```

3. **Calcular valor pendente**
   ```dart
   double pendingAmount = invoice.total - totalPaid;
   ```

4. **Atualizar status da invoice**
   ```dart
   if (totalPaid >= invoice.total) {
     invoice.status = InvoiceStatus.paid;
   } else if (invoice.dueDate.isBefore(DateTime.now())) {
     invoice.status = InvoiceStatus.overdue;
   } else {
     invoice.status = InvoiceStatus.sent; // Mantém como sent
   }
   ```

### 4. Métodos de Pagamento Suportados

O sistema suporta os seguintes métodos de pagamento:

- **Cash** - Dinheiro
- **Bank Transfer** - Transferência bancária
- **Credit Card** - Cartão de crédito
- **Debit Card** - Cartão de débito
- **Check** - Cheque
- **PayPal** - PayPal
- **Other** - Outros

### 5. Cenários de Pagamento

#### 5.1. Pagamento Total Único

```
Invoice Total: $1,000.00
Payment 1: $1,000.00 (Bank Transfer)
Resultado: Status = paid
```

#### 5.2. Pagamentos Parciais Múltiplos

```
Invoice Total: $1,000.00
Payment 1: $300.00 (Cash) - 30%
Payment 2: $400.00 (Bank Transfer) - 40%
Payment 3: $300.00 (Credit Card) - 30%
Resultado: Status = paid (total pago = $1,000.00)
```

#### 5.3. Pagamento Parcial (Não Completo)

```
Invoice Total: $1,000.00
Payment 1: $500.00 (Bank Transfer) - 50%
Status: sent (ainda pendente $500.00)
```

#### 5.4. Invoice Atrasada

```
Invoice Total: $1,000.00
Due Date: 2024-01-15
Current Date: 2024-01-20
Payment 1: $300.00 (Bank Transfer)
Status: overdue (vencida e parcialmente paga)
Pending: $700.00
```

### 6. Interface do Usuário

#### 6.1. Tela de Detalhes da Invoice

Na tela de detalhes (`InvoiceDetailScreen`), deve mostrar:

1. **Status da Invoice**
   - Badge com status atual
   - Cor indicativa (verde=paid, laranja=pending, vermelho=overdue)

2. **Resumo Financeiro**
   - Total da invoice: $1,000.00
   - Total pago: $500.00
   - Pendente: $500.00
   - Progress bar: 50% pago

3. **Histórico de Pagamentos**
   - Lista de todos os pagamentos registrados
   - Data, método, valor
   - Botão para adicionar novo pagamento

4. **Ações Disponíveis**
   - **Registrar Pagamento**: Abre modal/form para registrar novo pagamento
   - **Resend Invoice**: Reenviar invoice ao cliente
   - **Download PDF**: Baixar PDF da invoice

#### 6.2. Modal de Registro de Pagamento

Formulário para registrar novo pagamento:

```
┌─────────────────────────────┐
│  Registrar Pagamento        │
├─────────────────────────────┤
│ Valor da Invoice: $1,000.00 │
│ Já pago: $500.00            │
│ Pendente: $500.00           │
│                             │
│ Valor do Pagamento *        │
│ [___________$500.00]        │
│                             │
│ Data do Pagamento *         │
│ [___DD/MM/YYYY___]          │
│                             │
│ Método de Pagamento *       │
│ [Bank Transfer ▼]           │
│                             │
│ Observações (opcional)      │
│ [___________________]       │
│                             │
│  [Cancelar]  [Registrar]    │
└─────────────────────────────┘
```

### 7. Regras de Negócio

1. **Validação de Valor**
   - Pagamento não pode ser maior que valor pendente
   - Pagamento deve ser maior que zero
   - Se pagamento = pendente, status muda para `paid`

2. **Atualização Automática de Status**
   - Se `totalPaid >= invoice.total` → Status = `paid`
   - Se `totalPaid < invoice.total` e `dueDate < now` → Status = `overdue`
   - Se `totalPaid < invoice.total` e `dueDate >= now` → Status = `sent`

3. **Pagamentos Múltiplos**
   - Uma invoice pode ter múltiplos pagamentos
   - Cada pagamento é registrado independentemente
   - Soma de todos os pagamentos determina status final

4. **Histórico**
   - Todos os pagamentos são mantidos no histórico
   - Não é possível deletar pagamentos (apenas cancelar invoice inteira)
   - Pagamentos podem ter notas/observações

### 8. Estrutura de Dados

#### 8.1. Tabela Payments

```sql
CREATE TABLE payments (
  id TEXT PRIMARY KEY,
  invoiceId TEXT NOT NULL,
  amount REAL NOT NULL,
  date INTEGER NOT NULL,
  method TEXT NOT NULL,
  notes TEXT,
  createdAt INTEGER NOT NULL,
  FOREIGN KEY (invoiceId) REFERENCES invoices (id) ON DELETE CASCADE
);
```

#### 8.2. Relacionamento

```
Invoice (1) ────< (N) Payments
```

- Uma invoice pode ter N pagamentos
- Pagamentos são deletados automaticamente se invoice for deletada (CASCADE)

### 9. Implementação Sugerida

#### 9.1. Repository Interface

```dart
abstract class PaymentRepository {
  Future<({List<Payment>? data, Failure? error})> getPaymentsByInvoiceId(String invoiceId);
  Future<({Payment? data, Failure? error})> createPayment(Payment payment);
  Future<({bool success, Failure? error})> deletePayment(String paymentId);
  Future<({double? totalPaid, Failure? error})> getTotalPaidByInvoiceId(String invoiceId);
}
```

#### 9.2. Use Case: Registrar Pagamento

```dart
class RecordPaymentUseCase {
  final PaymentRepository paymentRepository;
  final InvoiceRepository invoiceRepository;
  
  Future<({bool success, Failure? error})> execute({
    required String invoiceId,
    required double amount,
    required PaymentMethod method,
    required DateTime date,
    String? notes,
  }) async {
    // 1. Validar valor
    // 2. Criar payment
    // 3. Calcular total pago
    // 4. Atualizar status da invoice
    // 5. Salvar invoice atualizada
  }
}
```

#### 9.3. Provider de Pagamentos

```dart
final paymentProvider = StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier(
    paymentRepository: ref.read(paymentRepositoryProvider),
    invoiceRepository: ref.read(invoiceRepositoryProvider),
  );
});
```

### 10. Funcionalidades Adicionais (Futuras)

1. **Reembolsos/Estornos**
   - Registrar pagamento negativo
   - Atualizar status adequadamente

2. **Notificações**
   - Notificar quando invoice está próxima do vencimento
   - Notificar quando pagamento é recebido

3. **Relatórios**
   - Relatório de pagamentos recebidos
   - Previsão de recebimentos
   - Invoices pendentes

4. **Integração com Gateway de Pagamento**
   - Stripe, PayPal, etc
   - Pagamento online direto do link

5. **Pagamentos Recorrentes**
   - Invoices mensais recorrentes
   - Auto-registro de pagamentos

## 📝 Resumo

O fluxo de pagamento no InvoicePro permite:

✅ **Múltiplos pagamentos** por invoice  
✅ **Pagamentos parciais** ou totais  
✅ **Atualização automática** de status  
✅ **Histórico completo** de pagamentos  
✅ **Cálculo automático** de valores pendentes  
✅ **Suporte a vários métodos** de pagamento  

O sistema é flexível e permite que uma invoice seja paga em várias parcelas, atualizando automaticamente seu status conforme os pagamentos são registrados.

