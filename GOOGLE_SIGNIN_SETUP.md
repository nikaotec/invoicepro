# Configuração do Google Sign In - Firebase

## ⚠️ Erro ApiException: 10 (DEVELOPER_ERROR)

Este erro ocorre quando o SHA-1 fingerprint não está registrado no Firebase Console.

## 🔧 Solução: Adicionar SHA-1 no Firebase Console

### Passo 1: Obter o SHA-1 Fingerprint

O SHA-1 do seu projeto é:
```
SHA-1: 98:50:38:3F:1F:2B:BC:F8:C2:B7:4C:99:9D:54:0E:4A:9A:7D:BC:EE
SHA-256: 08:6A:27:12:27:12:D3:63:82:D0:2E:17:6F:F0:30:50:E9:0E:07:60:D7:52:25:BF:55:DE:56:0C:C5:D8:B6:37
```

### Passo 2: Adicionar no Firebase Console

1. Acesse: https://console.firebase.google.com/
2. Selecione o projeto: **invoicepro-c063a**
3. Vá em **Project Settings** (ícone de engrenagem)
4. Role até a seção **Your apps**
5. Clique no app Android: **avs.com.invoicepro**
6. Clique em **Add fingerprint**
7. Cole o SHA-1: `98:50:38:3F:1F:2B:BC:F8:C2:B7:4C:99:9D:54:0E:4A:9A:7D:BC:EE`
8. Clique em **Save**

### Passo 3: Baixar o google-services.json atualizado

1. Após adicionar o SHA-1, baixe o novo `google-services.json`
2. Substitua o arquivo em `android/app/google-services.json`
3. Execute `flutter clean` e `flutter run`

### Passo 4: Habilitar Google Sign In

1. No Firebase Console, vá em **Authentication**
2. Clique em **Sign-in method**
3. Clique em **Google**
4. Ative o toggle **Enable**
5. Configure o email de suporte (opcional)
6. Clique em **Save**

## 📋 Verificações

- [x] SHA-1 fingerprint obtido
- [ ] SHA-1 adicionado no Firebase Console
- [ ] google-services.json atualizado
- [ ] Google Sign In habilitado no Firebase Authentication
- [ ] Package name correto: `avs.com.invoicepro`

## 🔄 Após Configurar

1. Execute `flutter clean`
2. Execute `flutter pub get`
3. Execute `flutter run`
4. Teste o Google Sign In novamente

## 📝 Notas

- O SHA-1 é o mesmo para debug e release quando usando a mesma keystore
- Se você usar uma keystore diferente para release, precisará adicionar o SHA-1 da keystore de release também
- Após adicionar o SHA-1, pode levar alguns minutos para propagar

