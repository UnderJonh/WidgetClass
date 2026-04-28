import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/aula.dart';

class AulaService {
  AulaService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Aula>> listarAulas() async {
    final rows = await _client
        .from('aulas')
        .select()
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
}

Aula? proximaAulaDoDia(List<Aula> aulas, {DateTime? agora}) {
  final referencia = agora ?? DateTime.now();
  final horarioAtual = Duration(
    hours: referencia.hour,
    minutes: referencia.minute,
    seconds: referencia.second,
  );

  final aulasRestantes =
      aulas
          .where(
            (aula) =>
                aula.diaSemana == referencia.weekday &&
                aula.horarioInicio >= horarioAtual,
          )
          .toList()
        ..sort((a, b) => a.horarioInicio.compareTo(b.horarioInicio));

  return aulasRestantes.isEmpty ? null : aulasRestantes.first;
}
