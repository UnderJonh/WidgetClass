# iOS Setup Guide - WidgetClass

## Overview
This project uses Flutter with native iOS Widget Extensions. The Flutter app communicates with the iOS widgets via shared UserDefaults.

## Prerequisites
- macOS 13 or later
- Xcode 15 or later
- iOS 14 or later deployment target
- CocoaPods

## Flutter Configuration (Already Done)

✅ **Already Configured:**
- `setAppGroupId('group.com.example.widgetclass')` is called in `WidgetSyncService.initialize()`
- `Runner.entitlements` has App Groups capability configured
- All Flutter code is iOS-compatible

## Steps to Make iOS Build Work

### Step 1: Clean Build Artifacts
```bash
flutter clean
cd ios
rm -rf Pods
rm Podfile.lock
cd ..
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Update Pods
```bash
cd ios
pod install --repo-update
cd ..
```

### Step 4: Open Xcode Project
```bash
open ios/Runner.xcworkspace
```

⚠️ **IMPORTANT:** Always open `.xcworkspace`, not `.xcodeproj`

### Step 5: Configure App Groups in Xcode

#### For Runner Target:
1. Select **Runner** target in Project Navigator
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Search for and add **App Groups**
5. Ensure the App Group identifier is: `group.com.example.widgetclass`

### Step 6: Create Widget Extensions

#### Create ClassScheduleWidget Extension:

1. In Xcode, select: **File > New > Target**
2. Choose **Widget Extension**
3. Set Product Name to: `ClassScheduleWidget`
4. Keep language as **SwiftUI**
5. Complete the creation

#### Configure the Widget Extension:
1. Select the new **ClassScheduleWidget** target
2. Go to **Signing & Capabilities**
3. Add **App Groups** capability
4. Set to: `group.com.example.widgetclass`

#### Implement ClassScheduleWidget (Replace the code in ClassScheduleWidgetView.swift):
```swift
import SwiftUI
import WidgetKit

struct ClassScheduleWidgetView: View {
  @State private var data: [String: String] = [:]
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(data["current_disciplina"] ?? "Sem aula")
          .font(.headline)
          .foregroundColor(.white)
        Spacer()
      }
      
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Label(data["current_professor"] ?? "Professor", systemImage: "person.fill")
            .font(.caption)
            .foregroundColor(.white)
          Label(data["current_sala"] ?? "Sala", systemImage: "door.left.hand.open")
            .font(.caption)
            .foregroundColor(.white)
          Label(data["current_horario"] ?? "--:--", systemImage: "clock.fill")
            .font(.caption)
            .foregroundColor(.white)
        }
        Spacer()
        Text(data["current_icone"] ?? "📘")
          .font(.system(size: 32))
      }
    }
    .padding()
    .background(Color(hex: data["current_cor_hex"] ?? "#1B9AAA"))
    .cornerRadius(12)
    .onAppear {
      loadData()
    }
  }
  
  private func loadData() {
    if let defaults = UserDefaults(suiteName: "group.com.example.widgetclass") {
      data["current_disciplina"] = defaults.string(forKey: "current_disciplina") ?? "Sem aula"
      data["current_professor"] = defaults.string(forKey: "current_professor") ?? "Professor"
      data["current_sala"] = defaults.string(forKey: "current_sala") ?? "Sala"
      data["current_horario"] = defaults.string(forKey: "current_horario") ?? "--:--"
      data["current_icone"] = defaults.string(forKey: "current_icone") ?? "📘"
      data["current_cor_hex"] = defaults.string(forKey: "current_cor_hex") ?? "#1B9AAA"
    }
  }
}

#Preview(as: .systemSmall) {
  ClassScheduleWidget()
} preview: {
  ClassScheduleWidgetView()
    .padding()
}

struct ClassScheduleWidget: Widget {
  let kind: String = "ClassScheduleWidget"
  
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: TimelineProvider()) { entry in
      ClassScheduleWidgetView()
    }
    .configurationDisplayName("Próxima Aula")
    .description("Mostra a próxima aula da turma selecionada")
    .supportedFamilies([.systemSmall])
  }
}

struct TimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date())
  }
  
  func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
    let entry = SimpleEntry(date: Date())
    completion(entry)
  }
  
  func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
    let entry = SimpleEntry(date: Date())
    let timeline = Timeline(entries: [entry], policy: .atEnd)
    completion(timeline)
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
}

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    let rgb = Int(hex, radix: 16) ?? 0
    let r = Double((rgb >> 16) & 0xFF) / 255.0
    let g = Double((rgb >> 8) & 0xFF) / 255.0
    let b = Double(rgb & 0xFF) / 255.0
    self.init(red: r, green: g, blue: b)
  }
}
```

#### Create ActivitiesWidget Extension:

1. Repeat Step 6 to create another Widget Extension
2. Set Product Name to: `ActivitiesWidget`
3. Configure App Groups same as ClassScheduleWidget

#### Implement ActivitiesWidget (Replace ActivitiesWidgetView.swift):
```swift
import SwiftUI
import WidgetKit

struct ActivitiesWidgetView: View {
  @State private var workData: [String: String] = [:]
  @State private var evalData: [String: String] = [:]
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Work Section
      VStack(alignment: .leading, spacing: 4) {
        Text("Trabalhos")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.gray)
        
        Text(workData["work_title"] ?? "Sem trabalhos")
          .font(.body)
          .fontWeight(.semibold)
        
        HStack(spacing: 8) {
          Text(workData["work_subject"] ?? "Agenda livre")
            .font(.caption)
          Spacer()
          Text(workData["work_date"] ?? "--")
            .font(.caption)
        }
        .foregroundColor(.gray)
      }
      .padding()
      .background(Color(hex: workData["work_color_hex"] ?? "#1B9AAA"))
      .cornerRadius(8)
      
      // Evaluation Section
      VStack(alignment: .leading, spacing: 4) {
        Text("Avaliações")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundColor(.gray)
        
        Text(evalData["eval_title"] ?? "Sem avaliações")
          .font(.body)
          .fontWeight(.semibold)
        
        HStack(spacing: 8) {
          Text(evalData["eval_subject"] ?? "Agenda livre")
            .font(.caption)
          Spacer()
          Text(evalData["eval_date"] ?? "--")
            .font(.caption)
        }
        .foregroundColor(.gray)
      }
      .padding()
      .background(Color(hex: evalData["eval_color_hex"] ?? "#5B7CFA"))
      .cornerRadius(8)
    }
    .padding()
    .onAppear {
      loadData()
    }
  }
  
  private func loadData() {
    if let defaults = UserDefaults(suiteName: "group.com.example.widgetclass") {
      workData["work_title"] = defaults.string(forKey: "work_title") ?? "Sem trabalhos"
      workData["work_subject"] = defaults.string(forKey: "work_subject") ?? "Agenda livre"
      workData["work_date"] = defaults.string(forKey: "work_date") ?? "--"
      workData["work_color_hex"] = defaults.string(forKey: "work_color_hex") ?? "#1B9AAA"
      
      evalData["eval_title"] = defaults.string(forKey: "eval_title") ?? "Sem avaliações"
      evalData["eval_subject"] = defaults.string(forKey: "eval_subject") ?? "Agenda livre"
      evalData["eval_date"] = defaults.string(forKey: "eval_date") ?? "--"
      evalData["eval_color_hex"] = defaults.string(forKey: "eval_color_hex") ?? "#5B7CFA"
    }
  }
}

#Preview(as: .systemMedium) {
  ActivitiesWidget()
} preview: {
  ActivitiesWidgetView()
    .padding()
}

struct ActivitiesWidget: Widget {
  let kind: String = "ActivitiesWidget"
  
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: TimelineProvider()) { entry in
      ActivitiesWidgetView()
    }
    .configurationDisplayName("Próximas Atividades")
    .description("Mostra o próximo trabalho e avaliação")
    .supportedFamilies([.systemMedium])
  }
}

struct TimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date())
  }
  
  func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
    let entry = SimpleEntry(date: Date())
    completion(entry)
  }
  
  func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
    let entry = SimpleEntry(date: Date())
    let timeline = Timeline(entries: [entry], policy: .atEnd)
    completion(timeline)
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
}

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    let rgb = Int(hex, radix: 16) ?? 0
    let r = Double((rgb >> 16) & 0xFF) / 255.0
    let g = Double((rgb >> 8) & 0xFF) / 255.0
    let b = Double(rgb & 0xFF) / 255.0
    self.init(red: r, green: g, blue: b)
  }
}
```

### Step 7: Build and Test

```bash
# Build for iOS
flutter build ios

# Or run on simulator
flutter run
```

## Troubleshooting

### "Pod install" fails
```bash
cd ios
pod cache clean --all
pod install --repo-update
cd ..
```

### Widget not appearing in iOS home screen
- Ensure app is running at least once
- Verify App Groups is set correctly in both targets
- Check UserDefaults are being saved with correct suite name

### Build errors with plugins
```bash
flutter clean
flutter pub get
cd ios
rm -rf Pods Podfile.lock .symlinks/ Flutter/Flutter.framework Flutter/Flutter.podspec
flutter pub get
cd ..
```

### Deployment target mismatch
In Xcode:
1. Select Runner project
2. Select Runner and Widget targets
3. In Build Settings, ensure deployment target is iOS 14.0 or later for all targets

## Flutter Build Commands

```bash
# For development/testing
flutter run

# For release
flutter build ios --release

# For iOS app store
flutter build ipa --release
```

## Additional Notes

- The Widget Extensions will automatically update when the app saves data via `HomeWidget.saveWidgetData()`
- Widget refresh is handled by iOS background refresh - ensure app has permission to refresh widgets
- All widget data is persisted in UserDefaults, not synced from Supabase directly

## Support

For issues specific to plugins:
- [home_widget](https://pub.dev/packages/home_widget)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [supabase_flutter](https://pub.dev/packages/supabase_flutter)
