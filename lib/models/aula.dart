import 'package:intl/intl.dart';

class Aula {
  const Aula({
    this.id,
    required this.turmaId,
    required this.disciplina,
    required this.professor,
    required this.sala,
    required this.diaSemana,
    required this.horarioInicio,
    this.horarioFim,
    this.icone = '📘',
    this.corHex = '#00B8D9',
    this.imagemUrl,
  });

  final String? id;
  final String turmaId;
  final String disciplina;
  final String professor;
  final String sala;
  final int diaSemana;
  final Duration horarioInicio;
  final Duration? horarioFim;
  final String icone;
  final String corHex;
  final String? imagemUrl;

  factory Aula.fromMap(Map<String, dynamic> map) {
    return Aula(
      id: map['id'] as String?,
      turmaId: (map['turma_id'] as String?) ?? 'eletronica_3a',
      disciplina: (map['disciplina'] as String?) ?? '',
      professor: (map['professor'] as String?) ?? '',
      sala: (map['sala'] as String?) ?? '',
      diaSemana: (map['dia_semana'] as num).toInt(),
      horarioInicio: parseDatabaseTime(map['horario_inicio'].toString()),
      horarioFim: map['horario_fim'] == null
          ? null
          : parseDatabaseTime(map['horario_fim'].toString()),
      icone: (map['icone'] as String?)?.trim().isNotEmpty == true
          ? map['icone'] as String
          : '📘',
      corHex: (map['cor_hex'] as String?)?.trim().isNotEmpty == true
          ? map['cor_hex'] as String
          : '#00B8D9',
      imagemUrl: (map['imagem_url'] as String?)?.trim().isEmpty == true
          ? null
          : map['imagem_url'] as String?,
    );
  }

  Map<String, dynamic> toMap({bool includeId = false}) {
    return <String, dynamic>{
      if (includeId && id != null) 'id': id,
      'turma_id': turmaId,
      'disciplina': disciplina.trim(),
      'professor': professor.trim(),
      'sala': sala.trim(),
      'dia_semana': diaSemana,
      'horario_inicio': formatDatabaseTime(horarioInicio),
      'horario_fim': horarioFim == null
          ? null
          : formatDatabaseTime(horarioFim!),
      'icone': icone.trim().isEmpty ? '📘' : icone.trim(),
      'cor_hex': normalizeHex(corHex),
      'imagem_url': imagemUrl?.trim().isEmpty == true
          ? null
          : imagemUrl?.trim(),
    };
  }

  Aula copyWith({
    String? id,
    String? turmaId,
    String? disciplina,
    String? professor,
    String? sala,
    int? diaSemana,
    Duration? horarioInicio,
    Duration? horarioFim,
    String? icone,
    String? corHex,
    String? imagemUrl,
  }) {
    return Aula(
      id: id ?? this.id,
      turmaId: turmaId ?? this.turmaId,
      disciplina: disciplina ?? this.disciplina,
      professor: professor ?? this.professor,
      sala: sala ?? this.sala,
      diaSemana: diaSemana ?? this.diaSemana,
      horarioInicio: horarioInicio ?? this.horarioInicio,
      horarioFim: horarioFim ?? this.horarioFim,
      icone: icone ?? this.icone,
      corHex: corHex ?? this.corHex,
      imagemUrl: imagemUrl ?? this.imagemUrl,
    );
  }

  String get horarioFormatado => formatDisplayTime(horarioInicio);

  String get intervaloFormatado {
    if (horarioFim == null) {
      return horarioFormatado;
    }
    return '$horarioFormatado - ${formatDisplayTime(horarioFim!)}';
  }

  static Duration parseDatabaseTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) {
      throw FormatException('Horario invalido recebido do banco: $value');
    }

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final secondText = parts.length > 2 ? parts[2].split('.').first : '0';
    final second = int.tryParse(secondText) ?? 0;

    return Duration(hours: hour, minutes: minute, seconds: second);
  }

  static String formatDatabaseTime(Duration time) {
    final hours = time.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = time.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = time.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  static String formatDisplayTime(Duration time) {
    final dateTime = DateTime(
      2024,
      1,
      1,
      time.inHours.remainder(24),
      time.inMinutes.remainder(60),
    );
    return DateFormat('HH:mm').format(dateTime);
  }

  static String normalizeHex(String value) {
    final clean = value.trim().replaceFirst('#', '').toUpperCase();
    if (clean.length == 6 && RegExp(r'^[0-9A-F]{6}$').hasMatch(clean)) {
      return '#$clean';
    }
    return '#00B8D9';
  }
}

const Map<int, String> nomesDiasSemana = <int, String>{
  1: 'Segunda',
  2: 'Terca',
  3: 'Quarta',
  4: 'Quinta',
  5: 'Sexta',
  6: 'Sabado',
  7: 'Domingo',
};
