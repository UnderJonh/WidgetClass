import 'package:flutter_test/flutter_test.dart';
import 'package:widget_class/models/aula.dart';
import 'package:widget_class/services/aula_service.dart';

void main() {
  test('proximaAulaDoDia retorna a aula restante mais proxima de hoje', () {
    final aulas = <Aula>[
      const Aula(
        id: '1',
        turmaId: 'eletronica_3a',
        disciplina: 'Calculo',
        professor: 'Ana',
        sala: 'A101',
        diaSemana: 2,
        horarioInicio: Duration(hours: 8),
      ),
      const Aula(
        id: '2',
        turmaId: 'eletronica_3a',
        disciplina: 'Fisica',
        professor: 'Bruno',
        sala: 'B204',
        diaSemana: 2,
        horarioInicio: Duration(hours: 14),
      ),
      const Aula(
        id: '3',
        turmaId: 'eletronica_3a',
        disciplina: 'Historia',
        professor: 'Carla',
        sala: 'C12',
        diaSemana: 3,
        horarioInicio: Duration(hours: 9),
      ),
    ];

    final proxima = proximaAulaDoDia(aulas, agora: DateTime(2026, 4, 28, 10));

    expect(proxima?.disciplina, 'Fisica');
  });

  test('proximaAulaDoDia mantem aula por 30 minutos depois do inicio', () {
    final aulas = <Aula>[
      const Aula(
        id: '1',
        turmaId: 'eletronica_3a',
        disciplina: 'Portugues',
        professor: 'Elaine',
        sala: 'F104',
        diaSemana: 2,
        horarioInicio: Duration(hours: 12),
      ),
      const Aula(
        id: '2',
        turmaId: 'eletronica_3a',
        disciplina: 'Matematica',
        professor: 'Ladeisa',
        sala: 'F104',
        diaSemana: 2,
        horarioInicio: Duration(hours: 14),
      ),
    ];

    final duranteJanela = proximaAulaDoDia(
      aulas,
      agora: DateTime(2026, 4, 28, 12, 30),
    );
    final depoisJanela = proximaAulaDoDia(
      aulas,
      agora: DateTime(2026, 4, 28, 12, 31),
    );

    expect(duranteJanela?.disciplina, 'Portugues');
    expect(depoisJanela?.disciplina, 'Matematica');
  });

  test('Aula converte horario do banco para exibicao', () {
    final aula = Aula.fromMap(<String, dynamic>{
      'id': '6fb90fa9-0c6c-48db-b804-22b4c86ad641',
      'turma_id': 'eletronica_3a',
      'disciplina': 'Algoritmos',
      'professor': 'Dra. Lima',
      'sala': 'Lab 2',
      'dia_semana': 1,
      'horario_inicio': '07:30:00',
    });

    expect(aula.horarioInicio, const Duration(hours: 7, minutes: 30));
    expect(aula.toMap()['horario_inicio'], '07:30:00');
  });
}
