# Configuração do Firebase - Android

## ✅ Configurações Realizadas

### 1. Arquivos Gradle

#### `android/settings.gradle.kts`
- ✅ Plugin do Google Services adicionado: `id("com.google.gms.google-services") version "4.4.2"`

#### `android/app/build.gradle.kts`
- ✅ Plugin do Google Services aplicado: `id("com.google.gms.google-services")`
- ✅ Localização: Dentro do bloco `plugins {}`

### 2. Arquivo de Configuração

#### `android/app/google-services.json`
- ✅ Arquivo presente e configurado
- ✅ Package name correto: `avs.com.invoicepro`
- ✅ Project ID: `invoicepro-c063a`

### 3. AndroidManifest.xml

#### `android/app/src/main/AndroidManifest.xml`
- ✅ Permissão de Internet adicionada: `<uses-permission android:name="android.permission.INTERNET"/>`

### 4. Código Flutter

#### `lib/main.dart`
- ✅ Firebase.initializeApp() chamado no main()
- ✅ Tratamento de erros implementado

#### `lib/presentation/providers/auth_provider.dart`
- ✅ Modo demo removido
- ✅ Funciona apenas com Firebase
- ✅ Tratamento de erros do Firebase Auth

## 📋 Checklist de Verificação

Antes de executar o app, verifique:

- [x] `google-services.json` está em `android/app/`
- [x] Plugin do Google Services no `settings.gradle.kts`
- [x] Plugin do Google Services aplicado no `app/build.gradle.kts`
- [x] Permissão de Internet no `AndroidManifest.xml`
- [x] Firebase inicializado no `main.dart`

## 🚀 Próximos Passos

1. **Limpar e reconstruir o projeto:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Se ainda houver erros, verifique:**
   - O arquivo `google-services.json` está atualizado
   - O package name no `build.gradle.kts` corresponde ao do Firebase
   - O Firebase Authentication está habilitado no Console do Firebase

3. **Habilitar Authentication no Firebase Console:**
   - Acesse: https://console.firebase.google.com/
   - Selecione o projeto `invoicepro-c063a`
   - Vá em Authentication > Sign-in method
   - Habilite "Email/Password"

## ⚠️ Notas Importantes

- O plugin do Google Services **deve** ser aplicado no final do arquivo `build.gradle.kts` do app
- O arquivo `google-services.json` **deve** estar em `android/app/` (não em `android/`)
- Após adicionar o plugin, execute `flutter clean` antes de rodar novamente

