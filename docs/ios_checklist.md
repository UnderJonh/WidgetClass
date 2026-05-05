# iOS Setup Checklist - WidgetClass

Use esta lista como referência rápida para configurar o iOS. Para mais detalhes, veja `docs/ios_setup_guide.md`.

## 📋 Pré-requisitos

- [ ] macOS 13+
- [ ] Xcode 15+
- [ ] CocoaPods instalado
- [ ] Flutter 3.10.7+

## 🔧 Preparação (Terminal)

- [ ] `flutter clean`
- [ ] `flutter pub get`
- [ ] `cd ios && pod install --repo-update && cd ..`
- [ ] `open ios/Runner.xcworkspace`

## 📱 Configuração no Xcode

### Runner Target

- [ ] Selecionar target **Runner**
- [ ] Abrir aba **Signing & Capabilities**
- [ ] Clicar **+ Capability**
- [ ] Adicionar **App Groups**
- [ ] Verificar ID: `group.com.example.widgetclass`

### Widget Extension: ClassScheduleWidget

- [ ] File → New → Target
- [ ] Escolher **Widget Extension**
- [ ] Nome: `ClassScheduleWidget`
- [ ] Linguagem: SwiftUI
- [ ] Finish

#### Configurar ClassScheduleWidget

- [ ] Selecionar target **ClassScheduleWidget**
- [ ] Abrir aba **Signing & Capabilities**
- [ ] Adicionar **App Groups**
- [ ] ID: `group.com.example.widgetclass`
- [ ] Abrir `ClassScheduleWidget/ClassScheduleWidgetView.swift`
- [ ] Copiar código do `docs/ios_setup_guide.md` (ClassScheduleWidget section)
- [ ] Colar substituindo o código existente

### Widget Extension: ActivitiesWidget

- [ ] File → New → Target
- [ ] Escolher **Widget Extension**
- [ ] Nome: `ActivitiesWidget`
- [ ] Linguagem: SwiftUI
- [ ] Finish

#### Configurar ActivitiesWidget

- [ ] Selecionar target **ActivitiesWidget**
- [ ] Abrir aba **Signing & Capabilities**
- [ ] Adicionar **App Groups**
- [ ] ID: `group.com.example.widgetclass`
- [ ] Abrir `ActivitiesWidget/ActivitiesWidgetView.swift`
- [ ] Copiar código do `docs/ios_setup_guide.md` (ActivitiesWidget section)
- [ ] Colar substituindo o código existente

## ✅ Verificação Final

- [ ] Todos os 3 targets tem App Groups capability
- [ ] App Group ID é `group.com.example.widgetclass` em todos
- [ ] Widget code foi copiado e compilado sem erros
- [ ] Xcode compila sem erros (⌘B)

## 🚀 Teste

```bash
# Terminal
flutter run

# Ou em Xcode: Product → Run (⌘R)
```

## 🐛 Troubleshooting

Se houver erro de compilação:

1. **Pod install falhou?**
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install --repo-update
   cd ..
   ```

2. **Erro de deployment target?**
   - Verificar todos os targets têm iOS 14.0+ em Build Settings

3. **Widget não aparece?**
   - Executar app pelo menos uma vez
   - Não precisa fazer nada, iOS automaticamente descobre os widgets
   - Ir em Home → Editar → Procurar por "WidgetClass"

4. **Build error em Xcode?**
   ```bash
   flutter clean
   cd ios && rm -rf Pods Podfile.lock && pod install --repo-update && cd ..
   ```

## 📚 Referências

- [ios_setup_guide.md](ios_setup_guide.md) - Guia completo
- [native_widget_setup.md](native_widget_setup.md) - Setup Android

## 💡 Dicas

- Sempre abrir `.xcworkspace`, nunca `.xcodeproj`
- Testar em simulator primeiro: `xcrun simctl list` para listar devices
- Verificar console do widget em Xcode para debug
- Widgets atualizam automaticamente quando app salva dados via `HomeWidget.saveWidgetData()`
