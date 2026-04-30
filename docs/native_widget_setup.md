# Configuracao nativa do home_widget

## Android

Os arquivos Android ja foram adicionados neste projeto:

- `android/app/src/main/kotlin/com/example/widget_class/ClassScheduleWidgetProvider.kt`
- `android/app/src/main/kotlin/com/example/widget_class/ActivitiesWidgetProvider.kt`
- `android/app/src/main/kotlin/com/example/widget_class/WidgetBackgroundSync.kt`
- `android/app/src/main/kotlin/com/example/widget_class/WidgetRefreshReceiver.kt`
- `android/app/src/main/kotlin/com/example/widget_class/WidgetRefreshScheduler.kt`
- `android/app/src/main/res/layout/class_schedule_widget.xml`
- `android/app/src/main/res/layout/activities_widget.xml`
- `android/app/src/main/res/xml/class_schedule_widget_info.xml`
- `android/app/src/main/res/xml/activities_widget_info.xml`
- `android/app/src/main/res/drawable/class_widget_background.xml`
- `android/app/src/main/res/drawable/class_widget_chip_background.xml`

O `AndroidManifest.xml` precisa registrar a action de abertura do
`home_widget` na `MainActivity`:

```xml
<intent-filter>
    <action android:name="es.antonborri.home_widget.action.LAUNCH" />
</intent-filter>
```

E precisa registrar o receiver do widget:

```xml
<receiver
    android:name=".ClassScheduleWidgetProvider"
    android:exported="true"
    android:label="WidgetClass">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/class_schedule_widget_info" />
</receiver>
```

O provider nativo le as chaves salvas pelo Flutter:

- `current_disciplina`
- `current_professor`
- `current_sala`
- `current_horario`
- `current_icone`
- `current_cor_hex`
- `work_title`
- `work_subject`
- `work_date`
- `eval_title`
- `eval_subject`
- `eval_date`
- `selected_turma_id`

O Android tambem agenda uma atualizacao em background a cada 15 minutos usando
`AlarmManager`. O receiver busca Supabase direto pelo REST, recalcula a aula
visivel por ate 30 minutos depois do inicio e redesenha os widgets sem abrir o
app.

## iOS

Para iOS, o app Flutter salva em `UserDefaults` compartilhado usando:

```dart
HomeWidget.setAppGroupId('group.com.example.widgetclass');
```

O arquivo `ios/Runner/Runner.entitlements` ja foi criado e associado ao target
`Runner`. No Xcode, confirme **Signing & Capabilities > App Groups** no target
`Runner` e adicione a mesma capacidade no target da Widget Extension:

```text
group.com.example.widgetclass
```

O `Info.plist` do app principal (`ios/Runner/Info.plist`) nao precisa de uma
chave especial para o `home_widget`. O compartilhamento fica nos arquivos
`.entitlements`. A Widget Extension, criada pelo Xcode com WidgetKit, deve ter
um `Info.plist` com `NSExtension` apontando para `com.apple.widgetkit-extension`.

Exemplo de leitura no widget iOS nativo:

```swift
let defaults = UserDefaults(suiteName: "group.com.example.widgetclass")
let disciplina = defaults?.string(forKey: "current_disciplina") ?? "Sem aula"
let professor = defaults?.string(forKey: "current_professor") ?? "Professor"
let sala = defaults?.string(forKey: "current_sala") ?? "Sala"
```

## Login administrativo por email

O app nao tem tela de cadastro. Crie os usuarios manualmente no Supabase em
**Authentication > Users** usando email e senha.

Para liberar permissao de administrador ou staff, rode no SQL Editor:

```sql
insert into public.usuarios_roles (email, role, nome)
values ('seu.email@gmail.com', 'admin', 'Seu Nome')
on conflict (email) do update set role = excluded.role, nome = excluded.nome;
```

Use `role = 'staff'` para usuarios que podem alterar somente a sala.
