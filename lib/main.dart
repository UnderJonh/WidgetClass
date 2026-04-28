import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/aula.dart';
import 'services/aula_service.dart';
import 'services/widget_sync_service.dart';

const supabaseUrl = 'https://ssvuyaolsawcyordeyzw.supabase.co';
const supabasePublishableKey = 'sb_publishable_AI0L1R5fzKVxqWQ8LFIq4w_q2tGn7E_';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);
  await WidgetSyncService.initialize();

  runApp(const WidgetClassApp());
}

class WidgetClassApp extends StatelessWidget {
  const WidgetClassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Widget Class',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B8D9),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF00B8D9), width: 1.4),
          ),
        ),
      ),
      home: const ScheduleHomePage(),
    );
  }
}

class ScheduleHomePage extends StatefulWidget {
  const ScheduleHomePage({super.key});

  @override
  State<ScheduleHomePage> createState() => _ScheduleHomePageState();
}

class _ScheduleHomePageState extends State<ScheduleHomePage> {
  final AulaService _aulaService = AulaService();

  List<Aula> _aulas = <Aula>[];
  Aula? _proximaAula;
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarAulas();
  }

  Future<void> _carregarAulas() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final aulas = await _aulaService.listarAulas();
      final proxima = proximaAulaDoDia(aulas);
      await WidgetSyncService.sincronizarProximaAula(proxima);

      if (!mounted) return;
      setState(() {
        _aulas = aulas;
        _proximaAula = proxima;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _erro = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _salvarAula({Aula? aula}) async {
    final resultado = await showModalBottomSheet<Aula>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AulaFormSheet(aula: aula),
    );

    if (resultado == null) return;

    setState(() => _salvando = true);
    try {
      if (resultado.id == null) {
        await _aulaService.criarAula(resultado);
      } else {
        await _aulaService.atualizarAula(resultado);
      }
      await _carregarAulas();
      _mostrarMensagem('Aula salva.');
    } catch (error) {
      _mostrarMensagem('Nao foi possivel salvar: $error');
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  Future<void> _excluirAula(Aula aula) async {
    final id = aula.id;
    if (id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir aula'),
          content: Text('Remover ${aula.disciplina} da grade?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    setState(() => _salvando = true);
    try {
      await _aulaService.excluirAula(id);
      await _carregarAulas();
      _mostrarMensagem('Aula excluida.');
    } catch (error) {
      _mostrarMensagem('Nao foi possivel excluir: $error');
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Class'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: <Widget>[
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _carregarAulas,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _salvando ? null : () => _salvarAula(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova aula'),
      ),
      body: Stack(
        children: <Widget>[
          RefreshIndicator(
            onRefresh: _carregarAulas,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              children: <Widget>[
                NextClassPanel(aula: _proximaAula, carregando: _carregando),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    Text(
                      'Aulas da semana',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_aulas.length} itens',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
                if (_erro != null) ...<Widget>[
                  const SizedBox(height: 14),
                  ErrorBanner(message: _erro!),
                ],
                const SizedBox(height: 14),
                if (_carregando && _aulas.isEmpty)
                  const LoadingSchedule()
                else if (_aulas.isEmpty)
                  const EmptySchedule()
                else
                  for (var index = 0; index < _aulas.length; index++)
                    AulaCard(
                      aula: _aulas[index],
                      color: _Palette
                          .cardColors[index % _Palette.cardColors.length],
                      onEdit: () => _salvarAula(aula: _aulas[index]),
                      onDelete: () => _excluirAula(_aulas[index]),
                    ),
              ],
            ),
          ),
          if (_salvando)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.08),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class NextClassPanel extends StatelessWidget {
  const NextClassPanel({
    required this.aula,
    required this.carregando,
    super.key,
  });

  final Aula? aula;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    final title = carregando
        ? 'Carregando'
        : aula?.disciplina ?? 'Sem aula restante';
    final professor = aula?.professor ?? 'Agenda livre';
    final sala = aula?.sala ?? 'Hoje';
    final horario = aula?.horarioFormatado ?? '--:--';

    return Container(
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF00B8D9), Color(0xFF5B7CFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF00B8D9).withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Proxima aula',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                horario,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              height: 1.03,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              InfoPill(icon: Icons.person_outline_rounded, text: professor),
              InfoPill(icon: Icons.meeting_room_outlined, text: sala),
            ],
          ),
        ],
      ),
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AulaCard extends StatelessWidget {
  const AulaCard({
    required this.aula,
    required this.color,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Aula aula;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final day = nomesDiasSemana[aula.diaSemana] ?? 'Dia ${aula.diaSemana}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  aula.horarioFormatado,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  day.substring(0, 3).toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  aula.disciplina,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$day  |  ${aula.professor}  |  Sala ${aula.sala}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5D667A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            children: <Widget>[
              IconButton(
                tooltip: 'Editar',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Excluir',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AulaFormSheet extends StatefulWidget {
  const AulaFormSheet({this.aula, super.key});

  final Aula? aula;

  @override
  State<AulaFormSheet> createState() => _AulaFormSheetState();
}

class _AulaFormSheetState extends State<AulaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _disciplinaController;
  late final TextEditingController _professorController;
  late final TextEditingController _salaController;
  late int _diaSemana;
  late Duration _horarioInicio;

  @override
  void initState() {
    super.initState();
    final aula = widget.aula;
    _disciplinaController = TextEditingController(text: aula?.disciplina ?? '');
    _professorController = TextEditingController(text: aula?.professor ?? '');
    _salaController = TextEditingController(text: aula?.sala ?? '');
    _diaSemana = aula?.diaSemana ?? DateTime.now().weekday;
    _horarioInicio = aula?.horarioInicio ?? const Duration(hours: 8);
  }

  @override
  void dispose() {
    _disciplinaController.dispose();
    _professorController.dispose();
    _salaController.dispose();
    super.dispose();
  }

  Future<void> _selecionarHorario() async {
    final selecionado = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _horarioInicio.inHours.remainder(24),
        minute: _horarioInicio.inMinutes.remainder(60),
      ),
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (selecionado == null) return;
    setState(() {
      _horarioInicio = Duration(
        hours: selecionado.hour,
        minutes: selecionado.minute,
      );
    });
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      Aula(
        id: widget.aula?.id,
        disciplina: _disciplinaController.text,
        professor: _professorController.text,
        sala: _salaController.text,
        diaSemana: _diaSemana,
        horarioInicio: _horarioInicio,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6DCE8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  widget.aula == null ? 'Nova aula' : 'Editar aula',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _disciplinaController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Disciplina',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _professorController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Professor',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _salaController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Sala',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _diaSemana,
                  decoration: const InputDecoration(
                    labelText: 'Dia da semana',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  items: nomesDiasSemana.entries
                      .map(
                        (entry) => DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _diaSemana = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _selecionarHorario,
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(
                    'Horario: ${Aula.formatDisplayTime(_horarioInicio)}',
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _salvar,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo obrigatorio' : null;
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8E8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline, color: Color(0xFFB42318)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7A271A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptySchedule extends StatelessWidget {
  const EmptySchedule({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.event_busy_outlined),
          SizedBox(width: 12),
          Expanded(child: Text('Nenhuma aula cadastrada.')),
        ],
      ),
    );
  }
}

class LoadingSchedule extends StatelessWidget {
  const LoadingSchedule({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 34),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _Palette {
  static const List<Color> cardColors = <Color>[
    Color(0xFFFF4D6D),
    Color(0xFFFFB703),
    Color(0xFF00B894),
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
    Color(0xFFFF7A00),
  ];
}
