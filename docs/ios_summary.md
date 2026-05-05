# iOS Setup Summary - WidgetClass

## ✅ Que já foi feito (Automático)

### Código Flutter
- ✅ `WidgetSyncService.initialize()` configura App Group no iOS
- ✅ `NotificationService` suporta iOS
- ✅ `LocalSettingsService` usa SharedPreferences (compatível com iOS)
- ✅ Todas as dependências possuem suporte iOS

### Configuração do Projeto
- ✅ `ios/Runner/Runner.entitlements` - App Groups capability configurada
- ✅ `ios/Runner/Info.plist` - Configuração básica de iOS
- ✅ `ios/Runner/AppDelegate.swift` - Plugin registration

### Dependências
- ✅ `home_widget: ^0.9.1` - Suporta iOS com WidgetKit
- ✅ `flutter_local_notifications: ^21.0.0` - Suporta iOS
- ✅ `flutter_timezone: ^5.0.2` - Suporta iOS
- ✅ `supabase_flutter: ^2.12.4` - Suporta iOS
- ✅ `shared_preferences: ^2.5.5` - Suporta iOS

## ⚠️ O que precisa ser feito no Mac (MANUAL)

### 1. Ambiente
- [ ] Ter um Mac com Xcode instalado
- [ ] CocoaPods instalado: `sudo gem install cocoapods`

### 2. Terminal (Rápido)
```bash
bash scripts/setup_ios.sh
```

Ou manualmente:
```bash
flutter clean
cd ios && pod install --repo-update && cd ..
open ios/Runner.xcworkspace
```

### 3. Xcode (Main Part)
- [ ] Abrir `ios/Runner.xcworkspace` NO Xcode
- [ ] Adicionar App Groups no target Runner
- [ ] Criar 2 Widget Extensions (ClassScheduleWidget e ActivitiesWidget)
- [ ] Configurar App Groups em cada extension
- [ ] Copiar código Swift dos widgets (do `docs/ios_setup_guide.md`)

## 🎯 Resultado Final

Após completar todos os passos no Mac, você terá:

1. **App principal** - Sincroniza dados com UserDefaults
2. **ClassScheduleWidget** - Mostra próxima aula
3. **ActivitiesWidget** - Mostra próximas atividades

Os widgets serão visíveis na Home do iOS e se atualizarão automaticamente.

## 📱 Testando os Widgets

1. Executar o app: `flutter run`
2. Login com suas credenciais Supabase
3. Selecionar uma turma
4. Editar Home Screen do iOS
5. Clicar em "+" para adicionar widgets
6. Procurar por "WidgetClass"
7. Adicionar os widgets (ClassScheduleWidget e/ou ActivitiesWidget)

## 🔄 Sincronização de Dados

- Quando você seleciona uma turma no app, os dados são salvos em UserDefaults
- Os widgets lêem automaticamente de UserDefaults
- Não há comunicação direta com Supabase pelos widgets
- Atualizações: O app força reload dos widgets quando dados mudam

## ❓ Perguntas Frequentes

### P: Por que preciso do Xcode?
R: Porque precisamos criar Widget Extensions nativas do iOS (WidgetKit). Não é possível fazer isso apenas com Flutter.

### P: Posso fazer isso no Windows?
R: Não. Widget Extensions do iOS só podem ser criadas no Xcode, que é macOS only.

### P: E se não tiver Mac?
R: Você pode:
1. Usar um Mac emprestado/alugado por algumas horas
2. Usar serviços de CI/CD como GitHub Actions com Mac runners
3. Usar máquinas virtuais macOS (caras e complexas)

### P: Como testar sem enviar para App Store?
R: Use o simulador do iOS:
- Xcode abre automaticamente um simulator
- Ou use: `xcrun simctl launch booted com.example.widget-class`

### P: Os widgets funcionam offline?
R: Sim! Os widgets lêem de UserDefaults que é local. Eles funcionam sem internet.

## 📚 Próximos Passos

Após ter iOS funcionando:

1. Configurar bundle ID e team signing para deploy
2. Testar em dispositivos reais
3. Preparar para App Store (certificates, provisioning profiles)
4. Considerar background refresh dos widgets (Advanced)

## 🆘 Troubleshooting

### Erro: "WidgetKit requires Swift"
- Verificar que target de widget foi criado com SwiftUI (not UIKit)

### Erro: "App Groups not found"
- Verificar Team ID em Signing
- Confirmar que entitlements estão associados ao target

### Widgets não aparecem após adicionar
- Executar app primeiro
- Fechar e reabrir Settings
- Reiniciar simulador/device

### Pod install fails
```bash
cd ios
rm -rf Pods Podfile.lock .symlinks/ Flutter/Flutter.framework
pod repo update
pod install
cd ..
```

## 📞 Suporte

Para problemas específicos de plugins:

- **home_widget**: https://pub.dev/packages/home_widget/
- **flutter_local_notifications**: https://pub.dev/packages/flutter_local_notifications/
- **supabase_flutter**: https://pub.dev/packages/supabase_flutter/

Para questões gerais Flutter iOS:
- https://docs.flutter.dev/platform-integration/ios/
