# WidgetClass

Um aplicativo Flutter para gerenciar aulas, atividades e widgets nativos no iOS e Android.

## Características

- 📅 Gerenciamento de aulas e turmas
- 📝 Gerenciamento de atividades (trabalhos e avaliações)
- 🔔 Notificações locais com reminders
- 🏠 Widgets nativos para iOS (WidgetKit) e Android
- 🌙 Tema claro/escuro
- ☁️ Sincronização com Supabase

## Requisitos

- Flutter 3.10.7 ou posterior
- Dart 3.10.7 ou posterior
- Para iOS: macOS, Xcode 15+, iOS 14+
- Para Android: Android SDK, Kotlin

## Setup e Instalação

### Dependências

```bash
flutter pub get
```

### Para Android

O projeto já possui configuração nativa para widgets Android. Basta compilar:

```bash
flutter run --release
```

Consulte [docs/native_widget_setup.md](docs/native_widget_setup.md) para detalhes de configuração nativa Android.

### Para iOS

Para iOS, você precisará criar as Widget Extensions no Xcode. Siga o guia completo em [docs/ios_setup_guide.md](docs/ios_setup_guide.md).

**Quick Start no Mac:**

```bash
# Executar script de setup (se em Mac)
bash scripts/setup_ios.sh

# Ou fazer manualmente
flutter clean
cd ios
pod install --repo-update
cd ..

# Abrir no Xcode
open ios/Runner.xcworkspace

# Executar
flutter run
```

## Configuração Supabase

O app requer credenciais do Supabase. Configure as seguintes variáveis de ambiente:

- `SUPABASE_URL`: URL do seu projeto Supabase
- `SUPABASE_PUBLISHABLE_KEY`: Chave pública do Supabase

Arquivo de configuração: [lib/app_config.dart](lib/app_config.dart)

## Autenticação

O app requer login. Usuários devem ser criados manualmente no Supabase:

1. Acesse: **Authentication > Users**
2. Crie um novo usuário com email e senha

Para permissões administrativas, execute no SQL Editor do Supabase:

```sql
insert into public.usuarios_roles (email, role, nome)
values ('seu.email@gmail.com', 'admin', 'Seu Nome')
on conflict (email) do update set role = excluded.role, nome = excluded.nome;
```

Use `role = 'staff'` para usuários que podem apenas alterar sala.

## Estrutura do Projeto

```
lib/
  ├── main.dart                    # Ponto de entrada
  ├── models/
  │   ├── atividade.dart          # Modelo de atividades
  │   ├── aula.dart               # Modelo de aulas
  │   └── turma.dart              # Modelo de turmas
  ├── services/
  │   ├── atividade_service.dart
  │   ├── aula_service.dart
  │   ├── local_settings_service.dart
  │   ├── notification_service.dart
  │   ├── session_service.dart
  │   └── widget_sync_service.dart
  └── app_config.dart             # Configurações

docs/
  ├── native_widget_setup.md      # Setup nativo Android
  └── ios_setup_guide.md          # Setup completo iOS
```

## Desenvolvimento

### Hot Reload

```bash
flutter run
```

### Build Release

```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
```

## Documentação

- [Configuração Nativa (Android)](docs/native_widget_setup.md)
- [Guia Completo iOS](docs/ios_setup_guide.md)

## Suporte

Para questões sobre dependências específicas, consulte:

- [home_widget](https://pub.dev/packages/home_widget)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [supabase_flutter](https://pub.dev/packages/supabase_flutter)
- [shared_preferences](https://pub.dev/packages/shared_preferences)
