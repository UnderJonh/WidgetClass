import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../models/aula.dart';

class WidgetSyncService {
  const WidgetSyncService._();

  static const String iOSAppGroupId = 'group.com.example.widgetclass';
  static const String iOSWidgetName = 'ClassScheduleWidget';
  static const String androidProviderName =
      'com.example.widget_class.ClassScheduleWidgetProvider';

  static Future<void> initialize() async {
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(iOSAppGroupId);
    }
  }

  static Future<void> sincronizarProximaAula(Aula? aula) async {
    await Future.wait(<Future<bool?>>[
      HomeWidget.saveWidgetData<String>(
        'current_disciplina',
        aula?.disciplina ?? 'Sem aula restante',
      ),
      HomeWidget.saveWidgetData<String>(
        'current_professor',
        aula?.professor ?? 'Nenhum professor',
      ),
      HomeWidget.saveWidgetData<String>(
        'current_sala',
        aula?.sala ?? 'Sem sala',
      ),
    ]);

    await HomeWidget.updateWidget(
      qualifiedAndroidName: androidProviderName,
      iOSName: iOSWidgetName,
    );
  }
}
