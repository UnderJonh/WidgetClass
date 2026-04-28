class Turma {
  const Turma({required this.id, required this.nome, required this.curso});

  final String id;
  final String nome;
  final String curso;
}

const List<Turma> turmasDisponiveis = <Turma>[
  Turma(id: 'eletronica_1a', nome: 'Eletronica 1A', curso: 'Eletronica'),
  Turma(id: 'eletronica_2a', nome: 'Eletronica 2A', curso: 'Eletronica'),
  Turma(id: 'eletronica_3a', nome: 'Eletronica 3A', curso: 'Eletronica'),
  Turma(
    id: 'meio_ambiente_1a',
    nome: 'Meio Ambiente 1A',
    curso: 'Meio Ambiente',
  ),
  Turma(
    id: 'meio_ambiente_2a',
    nome: 'Meio Ambiente 2A',
    curso: 'Meio Ambiente',
  ),
  Turma(
    id: 'meio_ambiente_3a',
    nome: 'Meio Ambiente 3A',
    curso: 'Meio Ambiente',
  ),
];

Turma turmaById(String? id) {
  return turmasDisponiveis.firstWhere(
    (turma) => turma.id == id,
    orElse: () => turmasDisponiveis[2],
  );
}
