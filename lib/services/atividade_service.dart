import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/atividade.dart';

class AtividadeService {
  AtividadeService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<Atividade>> listarAtividades({required String turmaId}) async {
    final rows = await _client
        .from('atividades')
        .select()
        .eq('turma_id', turmaId)
        .order('data_entrega');

    return rows.map((row) => Atividade.fromMap(row)).toList(growable: false);
  }

  Future<Atividade> criarAtividade(Atividade atividade) async {
    final row = await _client
        .from('atividades')
        .insert(atividade.toMap())
        .select()
        .single();

    return Atividade.fromMap(row);
  }

  Future<Atividade> atualizarAtividade(Atividade atividade) async {
    final id = atividade.id;
    if (id == null) {
      throw ArgumentError('Nao e possivel atualizar uma atividade sem id.');
    }

    final row = await _client
        .from('atividades')
        .update(atividade.toMap())
        .eq('id', id)
        .select()
        .single();

    return Atividade.fromMap(row);
  }

  Future<void> excluirAtividade(String id) async {
    await _client.from('atividades').delete().eq('id', id);
  }
}

List<Atividade> proximasAtividades(
  List<Atividade> atividades, {
  DateTime? agora,
  TipoAtividade? tipo,
  int? limite,
}) {
  final referencia = agora ?? DateTime.now();
  final hoje = DateTime(referencia.year, referencia.month, referencia.day);
  final filtradas = atividades.where((atividade) {
    final data = DateTime(
      atividade.data.year,
      atividade.data.month,
      atividade.data.day,
    );
    return !data.isBefore(hoje) && (tipo == null || atividade.tipo == tipo);
  }).toList()..sort((a, b) => a.data.compareTo(b.data));

  if (limite == null || filtradas.length <= limite) {
    return filtradas;
  }

  return filtradas.take(limite).toList(growable: false);
}
