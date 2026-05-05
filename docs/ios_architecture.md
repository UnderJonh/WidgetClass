# iOS Architecture - WidgetClass

## 📊 System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    iOS Home Screen                           │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────────────┐      ┌──────────────────────────┐ │
│  │  ClassScheduleWidget │      │  ActivitiesWidget        │ │
│  │  (WidgetKit Native)  │      │  (WidgetKit Native)      │ │
│  │                      │      │                          │ │
│  │  📚 Próxima Aula     │      │  📝 Próximas Atividades  │ │
│  │  • Disciplina        │      │  • Trabalhos             │ │
│  │  • Professor         │      │  • Avaliações            │ │
│  │  • Sala              │      │                          │ │
│  │  • Horário           │      │                          │ │
│  └──────────────────────┘      └──────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
           ▲                              ▲
           │ Lê dados                     │ Lê dados
           │                              │
    ┌──────┴──────────────────────────────┴──────┐
    │     iOS UserDefaults (Shared)              │
    │  group.com.example.widgetclass             │
    │  ┌────────────────────────────────────┐    │
    │  │ current_disciplina                 │    │
    │  │ current_professor                  │    │
    │  │ current_sala                       │    │
    │  │ current_horario                    │    │
    │  │ current_icone                      │    │
    │  │ current_cor_hex                    │    │
    │  │ work_title, work_subject, ...      │    │
    │  │ eval_title, eval_subject, ...      │    │
    │  └────────────────────────────────────┘    │
    └────────────────▲─────────────────────────┘
                     │ Salva dados
                     │
    ┌────────────────┴─────────────────┐
    │                                  │
    │   Flutter App (Main App)         │
    │   ┌──────────────────────────┐   │
    │   │  main.dart               │   │
    │   │  • Login                 │   │
    │   │  • Selecionar turma      │   │
    │   │  • Ver aulas             │   │
    │   │  • Ver atividades        │   │
    │   └──────────────────────────┘   │
    │            │                     │
    │            ▼                     │
    │   ┌──────────────────────────┐   │
    │   │ WidgetSyncService        │   │
    │   │ • Salva em UserDefaults  │   │
    │   │ • Atualiza widgets       │   │
    │   └──────────────────────────┘   │
    │            │                     │
    │            ▼                     │
    │   ┌──────────────────────────┐   │
    │   │ HomeWidget.saveWidgetData│   │
    │   └──────────────────────────┘   │
    └────────────────────────────────┘
                     │
                     ▼
    ┌────────────────────────────┐
    │   Supabase (Remote)        │
    │   • Autenticação           │
    │   • Aulas                  │
    │   • Atividades             │
    │   • Turmas                 │
    └────────────────────────────┘
```

## 🔄 Data Flow

### 1. Startup
```
App Start
  ↓
NotificationService.initialize()
  ↓
WidgetSyncService.initialize() → setAppGroupId()
  ↓
Load user from SharedPreferences
  ↓
Load aulas from Supabase
  ↓
WidgetSyncService.sincronizar() → Save to UserDefaults
  ↓
Widgets update automatically
```

### 2. When User Selects Class (Turma)
```
User selects class
  ↓
WidgetSyncService.salvarConfiguracaoWidget()
  ↓
Save to UserDefaults + Supabase
  ↓
Load aulas for that class
  ↓
WidgetSyncService.sincronizar()
  ↓
Save current/next aula to UserDefaults
  ↓
Save activities to UserDefaults
  ↓
Widget.updateWidget()
  ↓
iOS widgets refresh automatically
```

### 3. When Activities Change
```
App detects new activities
  ↓
NotificationService.syncEvaluationReminders()
  ↓
WidgetSyncService.sincronizarAtividades()
  ↓
Save to UserDefaults
  ↓
HomeWidget.updateWidget()
  ↓
Widgets show new data
```

## 📁 File Structure (iOS)

```
WidgetClass/
├── ios/
│   ├── Runner/
│   │   ├── AppDelegate.swift         ← App entry point
│   │   ├── Runner.entitlements       ← App Groups capability
│   │   └── Info.plist                ← iOS configuration
│   │
│   ├── ClassScheduleWidget/          ← Created in Xcode
│   │   ├── ClassScheduleWidget.swift
│   │   ├── ClassScheduleWidgetView.swift
│   │   └── Info.plist
│   │
│   ├── ActivitiesWidget/             ← Created in Xcode
│   │   ├── ActivitiesWidget.swift
│   │   ├── ActivitiesWidgetView.swift
│   │   └── Info.plist
│   │
│   └── Runner.xcworkspace/           ← Main workspace
│
└── lib/
    └── services/
        └── widget_sync_service.dart  ← Sync logic
```

## 🔐 App Groups

App Groups permite que o app principal compartilhe dados com extensions:

```
┌──────────────────────────────────┐
│   App Group: group.com.example.widgetclass
├──────────────────────────────────┤
│ Runner App                       │
│   • Read/Write UserDefaults      │
│                                  │
│ ClassScheduleWidget              │
│   • Read UserDefaults            │
│                                  │
│ ActivitiesWidget                 │
│   • Read UserDefaults            │
└──────────────────────────────────┘
```

## 🎯 Key Points

1. **Widgets são nativos** - Código Swift, não Flutter
2. **Comunicação via UserDefaults** - Simples e rápido
3. **Sem acesso a Supabase** - Widgets só lêem dados locais
4. **Sincronização one-way** - App → Widgets (não há feedback)
5. **Background refresh** - iOS gerencia quando atualizar

## 📋 Configuration Files

### Runner.entitlements
```xml
<?xml version="1.0" encoding="UTF-8"?>
<dict>
  <key>com.apple.security.application-groups</key>
  <array>
    <string>group.com.example.widgetclass</string>
  </array>
</dict>
```

### Widget Extension Info.plist
```xml
<dict>
  <key>NSExtension</key>
  <dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.widgetkit-extension</string>
  </dict>
</dict>
```

## 🔄 Widget Update Triggers

Widgets se atualizam quando:

1. **App salva dados** → `HomeWidget.saveWidgetData()`
2. **App força update** → `HomeWidget.updateWidget()`
3. **iOS background refresh** → Automático (configurável)
4. **User edita Home Screen** → Widget reload

## 💾 Data Persistence

```
Supabase (Remote Database)
        ↓
App loads data
        ↓
SharedPreferences (Local, App only)
        ↓
WidgetSyncService saves to UserDefaults
        ↓
UserDefaults with App Group (Shared between app + widgets)
        ↓
Widgets read and display
```

## 🛠️ Development Workflow

```
1. Editar Flutter code
   ↓
2. Editar WidgetSyncService (data to sync)
   ↓
3. Flutter run (testa no iPhone/simulador)
   ↓
4. Se mudar widget UI:
   - Editar Swift code
   - Xcode: Product → Run (⌘R)
   ↓
5. Ambos precisam ser testados juntos
```

## 📱 Testing Checklist

- [ ] App executa e faz login
- [ ] Selecionar turma salva em UserDefaults
- [ ] Widget refresh aparece (após seleção)
- [ ] Widget mostra dados corretos
- [ ] Mudar de turma atualiza widget
- [ ] Notificações funcionam
- [ ] Dark mode funciona em widgets

---

**Diagrama criado em:** 2025-01-26
**Versão:** 1.0
