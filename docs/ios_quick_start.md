# 🍎 iOS Setup - Quick Start

**Português:** Siga este guia para fazer o WidgetClass funcionar no iOS.

## 📋 Antes de Começar

- ✅ Você está em um Mac? (Obrigatório!)
- ✅ Tem Xcode instalado?
- ✅ Tem Flutter instalado?

Se não, não é possível continuar. iOS é exclusivo de macOS.

## 🚀 3 Passos Simples

### Passo 1: Preparar o Projeto (5 minutos)

Abra o terminal e vá até a pasta do projeto:

```bash
cd /caminho/para/WidgetClass
```

Execute este script:

```bash
bash scripts/setup_ios.sh
```

Se isso não funcionar, faça manualmente:

```bash
flutter clean
cd ios
pod install --repo-update
cd ..
```

### Passo 2: Abrir no Xcode (1 minuto)

```bash
open ios/Runner.xcworkspace
```

⚠️ **IMPORTANTE:** Abra `.xcworkspace` (com "workspace"), não `.xcodeproj`

### Passo 3: Configurar Widgets no Xcode (15-20 minutos)

Siga o guia passo a passo:

**👉 [docs/ios_checklist.md](ios_checklist.md)** ← Checklist rápido

Ou veja o guia completo:

**👉 [docs/ios_setup_guide.md](ios_setup_guide.md)** ← Guia detalhado

## ✨ Resultado

Após os 3 passos, você terá:

1. **App** - Funciona normalmente (login, aulas, atividades, etc)
2. **Widget de Aula** - Mostra a próxima aula na Home Screen
3. **Widget de Atividades** - Mostra próximos trabalhos e provas

## 🧪 Testar

No terminal:
```bash
flutter run
```

Ou em Xcode: Product → Run (⌘R)

A primeira vez leva alguns minutos para compilar.

## ⚡ Quick Setup Checklist

```
□ Mac com Xcode
□ Flutter instalado
□ Terminal: bash scripts/setup_ios.sh
□ Terminal: open ios/Runner.xcworkspace
□ Xcode: App Groups no Runner target
□ Xcode: Criar ClassScheduleWidget extension
□ Xcode: Criar ActivitiesWidget extension
□ Xcode: App Groups em cada extension
□ Xcode: Copiar código Swift dos widgets
□ Terminal: flutter run
```

## 🆘 Problemas?

**Pod install dá erro?**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
```

**Xcode não compila?**
- Verificar se todos os targets têm iOS 14.0+ em Build Settings
- Limpar build: Product → Clean Build Folder (⇧⌘K)

**Widgets não aparecem?**
- Executar app pelo menos uma vez
- Ir na Home → Editar → Procurar widgets "WidgetClass"
- Reiniciar simulador se necessário

**Ainda tendo problemas?**

Veja as seções de troubleshooting em:
- [ios_checklist.md](ios_checklist.md) - Checklist com troubleshooting
- [ios_setup_guide.md](ios_setup_guide.md) - Guia completo com troubleshooting
- [ios_summary.md](ios_summary.md) - FAQ e perguntas frequentes

## 📚 Documentação Completa

1. **[ios_checklist.md](ios_checklist.md)** - Checklist passo a passo
2. **[ios_setup_guide.md](ios_setup_guide.md)** - Guia detalhado com código
3. **[ios_summary.md](ios_summary.md)** - FAQ e informações gerais
4. **[native_widget_setup.md](native_widget_setup.md)** - Setup Android (para referência)
5. **[../../README.md](../../README.md)** - README do projeto

## 🔗 Links Úteis

- [Home Widget Plugin](https://pub.dev/packages/home_widget)
- [Flutter iOS Docs](https://docs.flutter.dev/platform-integration/ios/)
- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)

---

**Tempo estimado:** 30-45 minutos para primeira configuração

**Nível:** Intermediário (Precisa usar Xcode)

**Próximas vezes:** 5 minutos (apenas `flutter run`)

---

**Dica:** Salve este arquivo para referência futura! 📍
