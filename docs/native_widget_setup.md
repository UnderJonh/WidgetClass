# Configuracao nativa do home_widget

## Android

Os arquivos Android ja foram adicionados neste projeto:

- `android/app/src/main/kotlin/com/example/widget_class/ClassScheduleWidgetProvider.kt`
- `android/app/src/main/res/layout/class_schedule_widget.xml`
- `android/app/src/main/res/xml/class_schedule_widget_info.xml`
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
    android:label="Widget Class">
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
