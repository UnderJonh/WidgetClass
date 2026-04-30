import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/atividade.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _avaliacaoChannelId = 'avaliacoes_reminders';
  static const String _avaliacaoChannelName = 'Lembretes de avaliacoes';
  static const String _avaliacaoPayloadPrefix = 'avaliacao_3dias';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) {
      return;
    }

    tz_data.initializeTimeZones();
    await _configureLocalTimezone();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher_wc'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(settings: initializationSettings);
    _initialized = true;
  }

  Future<void> requestPermissionsIfNeeded() async {
    if (kIsWeb) return;
    if (!_initialized) {
      await initialize();
    }

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
      return;
    }

    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> syncEvaluationReminders({
    required String turmaId,
    required List<Atividade> atividades,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) {
      await initialize();
    }

    await _cancelScheduledForClass(turmaId);

    final avaliacoes =
        atividades
            .where((atividade) => atividade.tipo == TipoAtividade.avaliacao)
            .toList()
          ..sort((a, b) => a.data.compareTo(b.data));

    final now = DateTime.now();
    final baseId = 800000 + (turmaId.hashCode.abs() % 100000);
    var index = 0;

    for (final avaliacao in avaliacoes) {
      final reminderDate = _buildReminderDate(avaliacao.data);
      if (!reminderDate.isAfter(now)) {
        continue;
      }

      final notificationId = baseId + index;
      index++;
      final payload = _buildPayload(turmaId: turmaId, atividade: avaliacao);

      await _plugin.zonedSchedule(
        id: notificationId,
        title: 'Avaliacao chegando',
        body:
            '${avaliacao.titulo} (${avaliacao.materia}) em 3 dias. Se prepara!',
        scheduledDate: tz.TZDateTime.from(reminderDate, tz.local),
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
  }

  Future<void> _cancelScheduledForClass(String turmaId) async {
    final prefix = '$_avaliacaoPayloadPrefix|$turmaId|';
    final pending = await _plugin.pendingNotificationRequests();

    for (final item in pending) {
      final payload = item.payload ?? '';
      if (payload.startsWith(prefix)) {
        await _plugin.cancel(id: item.id);
      }
    }
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  DateTime _buildReminderDate(DateTime evaluationDate) {
    final base = DateTime(
      evaluationDate.year,
      evaluationDate.month,
      evaluationDate.day,
    );
    final threeDaysBefore = base.subtract(const Duration(days: 3));
    return DateTime(
      threeDaysBefore.year,
      threeDaysBefore.month,
      threeDaysBefore.day,
      8,
      0,
    );
  }

  String _buildPayload({
    required String turmaId,
    required Atividade atividade,
  }) {
    return '$_avaliacaoPayloadPrefix|$turmaId|${atividade.id ?? atividade.titulo}|${Atividade.formatDatabaseDate(atividade.data)}';
  }

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _avaliacaoChannelId,
      _avaliacaoChannelName,
      channelDescription: 'Lembrete automatico 3 dias antes das avaliacoes.',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
}
