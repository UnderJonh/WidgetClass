import 'package:intl/intl.dart';

class Aula {
  const Aula({
    this.id,
    required this.disciplina,
    required this.professor,
    required this.sala,
    required this.diaSemana,
    required this.horarioInicio,
  });

  final String? id;
  final String disciplina;
  final String professor;
  final String sala;
  final int diaSemana;
  final Duration horarioInicio;

  factory Aula.fromMap(Map<String, dynamic> map) {
    return Aula(
      id: map['id'] as String?,
      disciplina: (map['disciplina'] as String?) ?? '',
      professor: (map['professor'] as String?) ?? '',
      sala: (map['sala'] as String?) ?? '',
      diaSemana: (map['dia_semana'] as num).toInt(),
      horarioInicio: parseDatabaseTime(map['horario_inicio'].toString()),
    );
  }

  Map<String, dynamic> toMap({bool includeId = false}) {
    return <String, dynamic>{
      if (includeId && id != null) 'id': id,
      'disciplina': disciplina.trim(),
      'professor': professor.trim(),
      'sala': sala.trim(),
      'dia_semana': diaSemana,
      'horario_inicio': formatDatabaseTime(horarioInicio),
    };
  }

  Aula copyWith({
    String? id,
    String? disciplina,
    String? professor,
    String? sala,
    int? diaSemana,
    Duration? horarioInicio,
  }) {
    return Aula(
      id: id ?? this.id,
      disciplina: disciplina ?? this.disciplina,
      professor: professor ?? this.professor,
      sala: sala ?? this.sala,
      diaSemana: diaSemana ?? this.diaSemana,
      horarioInicio: horarioInicio ?? this.horarioInicio,
    );
  }

  String get horarioFormatado => formatDisplayTime(horarioInicio);

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
