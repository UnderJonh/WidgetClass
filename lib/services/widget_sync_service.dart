import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../app_config.dart';
import '../models/atividade.dart';
import '../models/aula.dart';
import 'atividade_service.dart';

class WidgetSyncService {
  const WidgetSyncService._();

  static const String iOSAppGroupId = 'group.com.example.widgetclass';
  static const String iOSWidgetName = 'ClassScheduleWidget';
  static const String androidProviderName =
      'com.example.widget_class.ClassScheduleWidgetProvider';
  static const String androidActivitiesProviderName =
      'com.example.widget_class.ActivitiesWidgetProvider';

  static Future<void> initialize() async {
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(iOSAppGroupId);
    }
  }

  static Future<void> salvarConfiguracaoWidget({
    required String turmaId,
  }) async {
    await Future.wait(<Future<bool?>>[
      HomeWidget.saveWidgetData<String>('selected_turma_id', turmaId),
      HomeWidget.saveWidgetData<String>('supabase_url', supabaseUrl),
      HomeWidget.saveWidgetData<String>(
        'supabase_publishable_key',
        supabasePublishableKey,
      ),
    ]);
  }

  static Future<void> sincronizar({
    required Aula? proximaAula,
    required List<Atividade> atividades,
  }) async {
    await Future.wait(<Future<void>>[
      sincronizarProximaAula(proximaAula),
      sincronizarAtividades(atividades),
    ]);
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
      HomeWidget.saveWidgetData<String>(
        'current_horario',
        aula?.intervaloFormatado ?? '--:--',
      ),
      HomeWidget.saveWidgetData<String>('current_icone', aula?.icone ?? '📘'),
      HomeWidget.saveWidgetData<String>(
        'current_cor_hex',
        aula?.corHex ?? '#1B9AAA',
      ),
    ]);

    await HomeWidget.updateWidget(
      qualifiedAndroidName: androidProviderName,
      iOSName: iOSWidgetName,
    );
  }

  static Future<void> sincronizarAtividades(List<Atividade> atividades) async {
    final trabalhos = proximasAtividades(
      atividades,
      tipo: TipoAtividade.trabalho,
      limite: 1,
    );
    final avaliacoes = proximasAtividades(
      atividades,
      tipo: TipoAtividade.avaliacao,
      limite: 1,
    );
    final proximoTrabalho = trabalhos.isEmpty ? null : trabalhos.first;
    final proximaAvaliacao = avaliacoes.isEmpty ? null : avaliacoes.first;

    await Future.wait(<Future<bool?>>[
      HomeWidget.saveWidgetData<String>(
        'work_title',
        proximoTrabalho?.titulo ?? 'Sem trabalhos',
      ),
      HomeWidget.saveWidgetData<String>(
        'work_subject',
        proximoTrabalho?.materia ?? 'Agenda livre',
      ),
      HomeWidget.saveWidgetData<String>(
        'work_date',
        proximoTrabalho?.dataFormatada ?? '--',
      ),
      HomeWidget.saveWidgetData<String>(
        'work_color_hex',
        proximoTrabalho?.corHex ?? '#1B9AAA',
      ),
      HomeWidget.saveWidgetData<String>(
        'eval_title',
        proximaAvaliacao?.titulo ?? 'Sem avaliacoes',
      ),
      HomeWidget.saveWidgetData<String>(
        'eval_subject',
        proximaAvaliacao?.materia ?? 'Agenda livre',
      ),
      HomeWidget.saveWidgetData<String>(
        'eval_date',
        proximaAvaliacao?.dataFormatada ?? '--',
      ),
      HomeWidget.saveWidgetData<String>(
        'eval_color_hex',
        proximaAvaliacao?.corHex ?? '#5B7CFA',
      ),
    ]);

    await HomeWidget.updateWidget(
      qualifiedAndroidName: androidActivitiesProviderName,
      iOSName: 'ActivitiesWidget',
    );
  }
}
