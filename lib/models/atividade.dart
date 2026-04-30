import 'aula.dart';

enum TipoAtividade {
  trabalho('trabalho', 'Trabalho'),
  avaliacao('avaliacao', 'Avaliacao');

  const TipoAtividade(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  static TipoAtividade fromDatabase(String? value) {
    return switch (value) {
      'avaliacao' => TipoAtividade.avaliacao,
      _ => TipoAtividade.trabalho,
    };
  }
}

class Atividade {
  const Atividade({
    this.id,
    required this.turmaId,
    required this.materia,
    required this.titulo,
    required this.tipo,
    required this.data,
    this.descricao,
    this.corHex = '#1B9AAA',
  });

  final String? id;
  final String turmaId;
  final String materia;
  final String titulo;
  final TipoAtividade tipo;
  final DateTime data;
  final String? descricao;
  final String corHex;

  factory Atividade.fromMap(Map<String, dynamic> map) {
    return Atividade(
      id: map['id'] as String?,
      turmaId: (map['turma_id'] as String?) ?? 'eletronica_3a',
      materia: (map['materia'] as String?) ?? '',
      titulo: (map['titulo'] as String?) ?? '',
      tipo: TipoAtividade.fromDatabase(map['tipo'] as String?),
      data: DateTime.parse(map['data_entrega'].toString()),
      descricao: (map['descricao'] as String?)?.trim().isEmpty == true
          ? null
          : map['descricao'] as String?,
      corHex: (map['cor_hex'] as String?)?.trim().isNotEmpty == true
          ? map['cor_hex'] as String
          : '#1B9AAA',
    );
  }

  Map<String, dynamic> toMap({bool includeId = false}) {
    return <String, dynamic>{
      if (includeId && id != null) 'id': id,
      'turma_id': turmaId,
      'materia': materia.trim(),
      'titulo': titulo.trim(),
      'tipo': tipo.databaseValue,
      'data_entrega': formatDatabaseDate(data),
      'descricao': descricao?.trim().isEmpty == true ? null : descricao?.trim(),
      'cor_hex': Aula.normalizeHex(corHex),
    };
  }

  String get dataFormatada {
    final month = _monthNames[data.month - 1];
    return '${data.day} de $month';
  }

  bool aconteceEm(DateTime day) {
    return data.year == day.year &&
        data.month == day.month &&
        data.day == day.day;
  }

  static String formatDatabaseDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

const List<String> _monthNames = <String>[
  'janeiro',
  'fevereiro',
  'marco',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];
