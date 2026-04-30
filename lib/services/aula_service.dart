import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/aula.dart';

const Duration defaultTempoVisivelDepoisDoInicio = Duration(minutes: 30);

class AulaService {
  AulaService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Aula>> listarAulas({required String turmaId}) async {
    final rows = await _client
        .from('aulas')
        .select()
        .eq('turma_id', turmaId)
        .order('dia_semana')
        .order('horario_inicio');

    return rows.map((row) => Aula.fromMap(row)).toList(growable: false);
  }

  Future<Aula> criarAula(Aula aula) async {
    final row = await _client
        .from('aulas')
        .insert(aula.toMap())
        .select()
        .single();

    return Aula.fromMap(row);
  }

  Future<Aula> atualizarAula(Aula aula) async {
    final id = aula.id;
    if (id == null) {
      throw ArgumentError('Nao e possivel atualizar uma aula sem id.');
    }

    final row = await _client
        .from('aulas')
        .update(aula.toMap())
        .eq('id', id)
        .select()
        .single();

    return Aula.fromMap(row);
  }

  Future<void> excluirAula(String id) async {
    await _client.from('aulas').delete().eq('id', id);
  }

  Future<Aula> atualizarSala({required Aula aula, required String sala}) async {
    final id = aula.id;
    if (id == null) {
      throw ArgumentError('Nao e possivel atualizar uma aula sem id.');
    }

    final row = await _client
        .from('aulas')
        .update(<String, dynamic>{'sala': sala.trim()})
        .eq('id', id)
        .select()
        .single();

    return Aula.fromMap(row);
  }
}

Aula? proximaAulaDoDia(
  List<Aula> aulas, {
  DateTime? agora,
  Duration tempoVisivelDepoisDoInicio = defaultTempoVisivelDepoisDoInicio,
}) {
  final referencia = agora ?? DateTime.now();
  final horarioAtual = Duration(
    hours: referencia.hour,
    minutes: referencia.minute,
    seconds: referencia.second,
  );

  final aulasDeHoje =
      aulas.where((aula) => aula.diaSemana == referencia.weekday).toList()
        ..sort((a, b) => a.horarioInicio.compareTo(b.horarioInicio));

  final aulasEmExibicao = aulasDeHoje.where((aula) {
    final fimDaJanela = aula.horarioInicio + tempoVisivelDepoisDoInicio;
    return aula.horarioInicio <= horarioAtual && horarioAtual <= fimDaJanela;
  }).toList();

  if (aulasEmExibicao.isNotEmpty) {
    return aulasEmExibicao.last;
  }

  for (final aula in aulasDeHoje) {
    if (aula.horarioInicio >= horarioAtual) {
      return aula;
    }
  }

  return null;
}
