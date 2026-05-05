import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';
import 'models/atividade.dart';
import 'models/aula.dart';
import 'models/turma.dart';
import 'services/atividade_service.dart';
import 'services/aula_service.dart';
import 'services/local_settings_service.dart';
import 'services/notification_service.dart';
import 'services/session_service.dart';
import 'services/widget_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);
  await WidgetSyncService.initialize();
  await NotificationService.instance.initialize();

  runApp(const WidgetClassApp());
}

class WidgetClassApp extends StatefulWidget {
  const WidgetClassApp({super.key});

  @override
  State<WidgetClassApp> createState() => _WidgetClassAppState();
}

class _WidgetClassAppState extends State<WidgetClassApp> {
  final LocalSettingsService _settingsService = LocalSettingsService();
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final mode = await _settingsService.getThemeMode();
    if (!mounted) return;
    setState(() => _themeMode = mode);
  }

  Future<void> _handleThemeModeChange(ThemeMode mode) async {
    if (_themeMode == mode) return;
    setState(() => _themeMode = mode);
    await _settingsService.setThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WidgetClass',
      themeMode: _themeMode,
      theme: _buildAppTheme(Brightness.light),
      darkTheme: _buildAppTheme(Brightness.dark),
      home: SplashGate(
        child: ScheduleHomePage(
          themeMode: _themeMode,
          onThemeModeChanged: _handleThemeModeChange,
        ),
      ),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({required this.child, super.key});

  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 980),
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future<void>.delayed(const Duration(milliseconds: 1450), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: <Widget>[
        widget.child,
        IgnorePointer(
          ignoring: !_visible,
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const <Color>[
                          Color(0xFF07141D),
                          Color(0xFF101D2A),
                          Color(0xFF1A172B),
                        ]
                      : const <Color>[
                          Color(0xFFEAF8F8),
                          Color(0xFFF8FAFC),
                          Color(0xFFEFF4FF),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: ScaleTransition(
                      scale: _scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _SplashTextLine(
                            controller: _controller,
                            begin: 0.10,
                            end: 0.70,
                            text: 'WidgetClass',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _SplashTextLine(
                            controller: _controller,
                            begin: 0.24,
                            end: 0.82,
                            text: 'Sua rotina no ponto',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0,
                                ),
                          ),
                          const SizedBox(height: 6),
                          _SplashTextLine(
                            controller: _controller,
                            begin: 0.38,
                            end: 0.92,
                            text: '(26.4.3v)',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SplashTextLine extends StatelessWidget {
  const _SplashTextLine({
    required this.controller,
    required this.begin,
    required this.end,
    required this.text,
    required this.style,
  });

  final Animation<double> controller;
  final double begin;
  final double end;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      child: Text(text, textAlign: TextAlign.center, style: style),
      builder: (context, child) {
        final normalized = ((controller.value - begin) / (end - begin))
            .clamp(0.0, 1.0)
            .toDouble();
        final value = Curves.easeOutCubic.transform(normalized);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: Transform.scale(scale: 0.96 + 0.04 * value, child: child),
          ),
        );
      },
    );
  }
}

ThemeData _buildAppTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF1B9AAA),
    brightness: brightness,
  );
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF0B1320)
        : const Color(0xFFF2F5F8),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark
          ? const Color(0xFF0F1D2B).withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.88),
      indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.34 : 0.20),
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
        final active = states.contains(WidgetState.selected);
        return TextStyle(
          fontWeight: active ? FontWeight.w800 : FontWeight.w700,
          color: active ? scheme.onSurface : scheme.onSurfaceVariant,
        );
      }),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      extendedTextStyle: const TextStyle(fontWeight: FontWeight.w800),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.white.withValues(alpha: 0.72),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.60),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
    ),
  );
}

class ScheduleHomePage extends StatefulWidget {
  const ScheduleHomePage({
    required this.themeMode,
    required this.onThemeModeChanged,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<ScheduleHomePage> createState() => _ScheduleHomePageState();
}

class _ScheduleHomePageState extends State<ScheduleHomePage> {
  final AulaService _aulaService = AulaService();
  final AtividadeService _atividadeService = AtividadeService();
  final LocalSettingsService _settingsService = LocalSettingsService();
  final SessionService _sessionService = SessionService();
  final NotificationService _notificationService = NotificationService.instance;

  late StreamSubscription<AuthState> _authSubscription;

  Turma _turmaSelecionada = turmaById('eletronica_3a');
  AppRole _role = AppRole.aluno;
  User? _user;
  List<Aula> _aulas = <Aula>[];
  List<Atividade> _atividades = <Atividade>[];
  Aula? _proximaAula;
  int _selectedTab = 0;
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _authSubscription = _sessionService.authChanges.listen((_) {
      _atualizarSessao();
    });
    _bootstrap();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final turmaId = await _settingsService.getTurmaId();
    await _notificationService.requestPermissionsIfNeeded();
    if (!mounted) return;
    setState(() => _turmaSelecionada = turmaById(turmaId));
    await WidgetSyncService.salvarConfiguracaoWidget(
      turmaId: _turmaSelecionada.id,
    );
    await _atualizarSessao();
    await _carregarAulas();
  }

  Future<void> _atualizarSessao() async {
    final role = await _sessionService.currentRole();
    if (!mounted) return;
    setState(() {
      _role = role;
      _user = _sessionService.currentUser;
    });
  }

  Future<void> _carregarAulas() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      await WidgetSyncService.salvarConfiguracaoWidget(
        turmaId: _turmaSelecionada.id,
      );
      final results = await Future.wait<Object>(<Future<Object>>[
        _aulaService.listarAulas(turmaId: _turmaSelecionada.id),
        _atividadeService.listarAtividades(turmaId: _turmaSelecionada.id),
      ]);
      final aulas = results[0] as List<Aula>;
      final atividades = results[1] as List<Atividade>;
      final proxima = proximaAulaDoDia(aulas);
      await WidgetSyncService.sincronizar(
        proximaAula: proxima,
        atividades: atividades,
      );
      await _notificationService.syncEvaluationReminders(
        turmaId: _turmaSelecionada.id,
        atividades: atividades,
      );

      if (!mounted) return;
      setState(() {
        _aulas = aulas;
        _atividades = atividades;
        _proximaAula = proxima;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _erro = _friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _selecionarTurma() async {
    final turma = await showModalBottomSheet<Turma>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TurmaPickerSheet(selecionada: _turmaSelecionada),
    );

    if (turma == null) return;
    await _settingsService.setTurmaId(turma.id);
    await WidgetSyncService.salvarConfiguracaoWidget(turmaId: turma.id);
    if (!mounted) return;
    setState(() => _turmaSelecionada = turma);
    await _carregarAulas();
  }

  Future<void> _entrarComEmail() async {
    final credentials = await showModalBottomSheet<EmailLoginCredentials>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EmailLoginSheet(),
    );

    if (credentials == null) return;

    try {
      setState(() => _salvando = true);
      await _sessionService.signInWithEmail(
        email: credentials.email,
        password: credentials.password,
      );
      await _atualizarSessao();
      _mostrarMensagem('Login realizado.');
    } catch (error) {
      _mostrarMensagem('Email ou senha invalidos.');
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  Future<void> _sair() async {
    await _sessionService.signOut();
    await _atualizarSessao();
  }

  Future<void> _salvarAula({Aula? aula, int? diaSemanaInicial}) async {
    if (!_role.canManageClasses) {
      _mostrarMensagem('Somente administradores podem editar a aula completa.');
      return;
    }

    final resultado = await showModalBottomSheet<Aula>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AulaFormSheet(
        aula: aula,
        turmaInicial: _turmaSelecionada,
        diaSemanaInicial: diaSemanaInicial,
      ),
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

  Future<void> _salvarAtividade({
    Atividade? atividade,
    TipoAtividade? tipoInicial,
    DateTime? dataInicial,
  }) async {
    if (!_role.canManageActivities) {
      _mostrarMensagem('Somente administradores podem editar atividades.');
      return;
    }

    final resultado = await showModalBottomSheet<Atividade>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AtividadeFormSheet(
        atividade: atividade,
        turmaInicial: _turmaSelecionada,
        tipoInicial: tipoInicial,
        dataInicial: dataInicial,
      ),
    );

    if (resultado == null) return;

    setState(() => _salvando = true);
    try {
      if (resultado.id == null) {
        await _atividadeService.criarAtividade(resultado);
      } else {
        await _atividadeService.atualizarAtividade(resultado);
      }
      await _carregarAulas();
      _mostrarMensagem('Atividade salva.');
    } catch (error) {
      _mostrarMensagem('Nao foi possivel salvar a atividade: $error');
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  Future<void> _excluirAtividade(Atividade atividade) async {
    if (!_role.canManageActivities) {
      _mostrarMensagem('Somente administradores podem excluir atividades.');
      return;
    }

    final id = atividade.id;
    if (id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir atividade'),
          content: Text('Remover ${atividade.titulo} da agenda?'),
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
      await _atividadeService.excluirAtividade(id);
      await _carregarAulas();
      _mostrarMensagem('Atividade excluida.');
    } catch (error) {
      _mostrarMensagem('Nao foi possivel excluir: $error');
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  Future<void> _editarSala(Aula aula) async {
    if (!_role.canEditRooms) {
      _mostrarMensagem(
        'Somente administradores ou staffs podem alterar salas.',
      );
      return;
    }

    final sala = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoomEditSheet(aula: aula),
    );

    if (sala == null) return;
    setState(() => _salvando = true);
    try {
      await _aulaService.atualizarSala(aula: aula, sala: sala);
      await _carregarAulas();
      _mostrarMensagem('Sala atualizada.');
    } catch (error) {
      _mostrarMensagem('Nao foi possivel alterar a sala: $error');
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  Future<void> _excluirAula(Aula aula) async {
    if (!_role.canManageClasses) {
      _mostrarMensagem('Somente administradores podem excluir aulas.');
      return;
    }

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

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('SocketException') ||
        message.contains('Failed host lookup')) {
      return 'Sem conexao com o Supabase. Confira a internet do aparelho e tente atualizar.';
    }
    return message;
  }

  int get _activeTab => _selectedTab == 1 ? 1 : 0;

  String get _tabTitle {
    return switch (_activeTab) {
      1 => 'Agenda',
      _ => 'WidgetClass',
    };
  }

  Widget _buildAulasPage() {
    final aulasOrdenadas = [..._aulas]
      ..sort((a, b) {
        final dayCompare = a.diaSemana.compareTo(b.diaSemana);
        if (dayCompare != 0) return dayCompare;
        return a.horarioInicio.compareTo(b.horarioInicio);
      });
    final children = <Widget>[
      StaggeredEntry(
        index: 0,
        child: ClassSelectorCard(
          turma: _turmaSelecionada,
          onTap: _selecionarTurma,
        ),
      ),
      const SizedBox(height: 16),
      StaggeredEntry(
        index: 1,
        child: NextClassPanel(aula: _proximaAula, carregando: _carregando),
      ),
      const SizedBox(height: 24),
      StaggeredEntry(
        index: 2,
        child: SectionHeader(
          title: 'Aulas da turma',
          count: aulasOrdenadas.length,
          subtitle: _turmaSelecionada.nome,
        ),
      ),
      if (_erro != null) ...<Widget>[
        const SizedBox(height: 14),
        ErrorBanner(message: _erro!),
      ],
      const SizedBox(height: 14),
    ];

    if (_carregando && _aulas.isEmpty) {
      children.add(const LoadingSchedule());
    } else if (_aulas.isEmpty) {
      children.add(EmptySchedule(turma: _turmaSelecionada));
    } else {
      for (var index = 0; index < aulasOrdenadas.length; index++) {
        final aula = aulasOrdenadas[index];
        children.add(
          StaggeredEntry(
            index: index + 3,
            child: AulaCard(
              aula: aula,
              canManage: _role.canManageClasses,
              canEditRoom: _role.canEditRooms,
              onEditCard: () => _salvarAula(aula: aula),
              onEditRoom: () => _editarSala(aula),
              onDelete: () => _excluirAula(aula),
            ),
          ),
        );
      }
    }

    return _PageList(children: children);
  }

  Widget _buildAtividadesPage() {
    final atividadesComuns = proximasAtividades(
      _atividades,
      tipo: TipoAtividade.atividade,
    );
    final trabalhos = proximasAtividades(
      _atividades,
      tipo: TipoAtividade.trabalho,
    );
    final avaliacoes = proximasAtividades(
      _atividades,
      tipo: TipoAtividade.avaliacao,
    );

    return _PageList(
      children: <Widget>[
        StaggeredEntry(
          index: 0,
          child: ClassSelectorCard(
            turma: _turmaSelecionada,
            onTap: _selecionarTurma,
          ),
        ),
        const SizedBox(height: 16),
        StaggeredEntry(
          index: 1,
          child: AgendaSummaryPanel(
            atividades: atividadesComuns,
            trabalhos: trabalhos,
            avaliacoes: avaliacoes,
          ),
        ),
        const SizedBox(height: 22),
        StaggeredEntry(
          index: 2,
          child: SectionHeader(
            title: 'Agenda e calendario',
            count: _atividades.length,
            subtitle: 'Entregas marcadas no calendario',
          ),
        ),
        if (_erro != null) ...<Widget>[
          const SizedBox(height: 14),
          ErrorBanner(message: _erro!),
        ],
        const SizedBox(height: 14),
        StaggeredEntry(
          index: 3,
          child: CalendarPanel(
            atividades: _atividades,
            canManage: _role.canManageCalendar,
            onEditAtividade: (atividade) =>
                _salvarAtividade(atividade: atividade),
            onDeleteAtividade: _excluirAtividade,
            onAddAtividade: (day) => _salvarAtividade(dataInicial: day),
          ),
        ),
        const SizedBox(height: 22),
        StaggeredEntry(
          index: 4,
          child: SectionHeader(
            title: 'Proximas atividades',
            count: _atividades.length,
            subtitle: 'Atividades, trabalhos e avaliacoes',
          ),
        ),
        const SizedBox(height: 14),
        if (_carregando && _atividades.isEmpty)
          const LoadingSchedule()
        else if (_atividades.isEmpty)
          const EmptyActivities()
        else ...<Widget>[
          StaggeredEntry(
            index: 5,
            child: ActivitySection(
              title: 'Atividades',
              icon: Icons.event_note_outlined,
              atividades: atividadesComuns,
              canManage: _role.canManageActivities,
              onCreate: () =>
                  _salvarAtividade(tipoInicial: TipoAtividade.atividade),
              onEdit: (atividade) => _salvarAtividade(atividade: atividade),
              onDelete: _excluirAtividade,
            ),
          ),
          const SizedBox(height: 16),
          StaggeredEntry(
            index: 6,
            child: ActivitySection(
              title: 'Proximos trabalhos',
              icon: Icons.assignment_outlined,
              atividades: trabalhos,
              canManage: _role.canManageActivities,
              onCreate: () =>
                  _salvarAtividade(tipoInicial: TipoAtividade.trabalho),
              onEdit: (atividade) => _salvarAtividade(atividade: atividade),
              onDelete: _excluirAtividade,
            ),
          ),
          const SizedBox(height: 16),
          StaggeredEntry(
            index: 7,
            child: ActivitySection(
              title: 'Proximas avaliacoes',
              icon: Icons.fact_check_outlined,
              atividades: avaliacoes,
              canManage: _role.canManageActivities,
              onCreate: () =>
                  _salvarAtividade(tipoInicial: TipoAtividade.avaliacao),
              onEdit: (atividade) => _salvarAtividade(atividade: atividade),
              onDelete: _excluirAtividade,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedPage() {
    return switch (_activeTab) {
      1 => _buildAtividadesPage(),
      _ => _buildAulasPage(),
    };
  }

  Widget _buildFab({
    required bool canAddClasses,
    required bool canAddActivities,
  }) {
    if (_salvando) {
      return const SizedBox(key: ValueKey<String>('fab_none'));
    }
    if (_activeTab == 0 && canAddClasses) {
      return FloatingActionButton.extended(
        key: const ValueKey<String>('fab_aulas'),
        onPressed: () => _salvarAula(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova aula'),
      );
    }
    if (_activeTab == 1 && canAddActivities) {
      return FloatingActionButton.extended(
        key: const ValueKey<String>('fab_atividades'),
        onPressed: () => _salvarAtividade(),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Nova atividade'),
      );
    }
    return const SizedBox(key: ValueKey<String>('fab_none'));
  }

  @override
  Widget build(BuildContext context) {
    final canAddClasses = _role.canManageClasses;
    final canAddActivities = _role.canManageActivities;

    return Scaffold(
      drawer: AppDrawer(
        role: _role,
        user: _user,
        turma: _turmaSelecionada,
        themeMode: widget.themeMode,
        onLogin: _entrarComEmail,
        onLogout: _sair,
        onSelectTurma: _selecionarTurma,
        onThemeModeChanged: widget.onThemeModeChanged,
        onNewClass: canAddClasses ? () => _salvarAula() : null,
        onNewActivity: canAddActivities ? () => _salvarAtividade() : null,
      ),
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: Text(_tabTitle, key: ValueKey<String>(_tabTitle)),
        ),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _activeTab,
        onDestinationSelected: (value) => setState(() => _selectedTab = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'Aulas',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_turned_in_rounded),
            label: 'Agenda',
          ),
        ],
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeInCubic,
        child: _buildFab(
          canAddClasses: canAddClasses,
          canAddActivities: canAddActivities,
        ),
      ),
      body: Stack(
        children: <Widget>[
          const AppBackdrop(),
          RefreshIndicator(
            onRefresh: _carregarAulas,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.04, 0.02),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_activeTab),
                child: _buildSelectedPage(),
              ),
            ),
          ),
          if (_salvando)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.10),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class AppBackdrop extends StatefulWidget {
  const AppBackdrop({super.key});

  @override
  State<AppBackdrop> createState() => _AppBackdropState();
}

class _AppBackdropState extends State<AppBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final begin = Alignment.lerp(
          Alignment.topLeft,
          Alignment.topRight,
          _controller.value,
        )!;
        final end = Alignment.lerp(
          Alignment.bottomRight,
          Alignment.bottomLeft,
          _controller.value,
        )!;
        final blobA = Alignment.lerp(
          const Alignment(-0.8, -0.8),
          const Alignment(0.9, 0.1),
          _controller.value,
        )!;
        final blobB = Alignment.lerp(
          const Alignment(0.9, 0.95),
          const Alignment(-0.6, -0.2),
          _controller.value,
        )!;
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const <Color>[
                          Color(0xFF0A1522),
                          Color(0xFF111C2B),
                          Color(0xFF1A1B33),
                        ]
                      : const <Color>[
                          Color(0xFFEAF8F8),
                          Color(0xFFF4F0FF),
                          Color(0xFFF8FAFC),
                        ],
                  begin: begin,
                  end: end,
                ),
              ),
            ),
            Align(
              alignment: blobA,
              child: _BackdropBlob(
                color: isDark
                    ? const Color(0xFF1B9AAA).withValues(alpha: 0.22)
                    : const Color(0xFF1B9AAA).withValues(alpha: 0.17),
                size: 240,
              ),
            ),
            Align(
              alignment: blobB,
              child: _BackdropBlob(
                color: isDark
                    ? const Color(0xFF5B7CFA).withValues(alpha: 0.16)
                    : const Color(0xFF7C3AED).withValues(alpha: 0.13),
                size: 280,
              ),
            ),
            const SizedBox.expand(),
          ],
        );
      },
    );
  }
}

class _BackdropBlob extends StatelessWidget {
  const _BackdropBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color,
              blurRadius: size * 0.40,
              spreadRadius: size * 0.05,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageList extends StatelessWidget {
  const _PageList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: children,
    );
  }
}

class StaggeredEntry extends StatelessWidget {
  const StaggeredEntry({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - value)),
            child: Transform.scale(scale: 0.98 + (0.02 * value), child: child),
          ),
        );
      },
      child: child,
    );
  }
}

class AulaGrupo {
  const AulaGrupo({required this.disciplina, required this.aulas});

  final String disciplina;
  final List<Aula> aulas;

  Aula get principal => aulas.first;

  String get professores {
    final names = aulas.map((aula) => aula.professor).toSet().toList();
    return names.join(' / ');
  }

  String get salas {
    final rooms = aulas.map((aula) => aula.sala).toSet().toList();
    return rooms.join(' / ');
  }
}

List<AulaGrupo> agruparAulasPorMateria(List<Aula> aulas) {
  final grouped = <String, List<Aula>>{};
  for (final aula in aulas) {
    final key = aula.disciplina.trim().toLowerCase();
    grouped.putIfAbsent(key, () => <Aula>[]).add(aula);
  }

  final grupos = grouped.entries.map((entry) {
    final aulasOrdenadas = [...entry.value]
      ..sort((a, b) {
        final dayCompare = a.diaSemana.compareTo(b.diaSemana);
        if (dayCompare != 0) return dayCompare;
        return a.horarioInicio.compareTo(b.horarioInicio);
      });
    return AulaGrupo(
      disciplina: aulasOrdenadas.first.disciplina,
      aulas: aulasOrdenadas,
    );
  }).toList()..sort((a, b) => a.disciplina.compareTo(b.disciplina));

  return grupos;
}

class AulaGrupoCard extends StatelessWidget {
  const AulaGrupoCard({
    required this.grupo,
    required this.canManage,
    required this.canEditRoom,
    required this.onEditCard,
    required this.onEditRoom,
    required this.onDelete,
    super.key,
  });

  final AulaGrupo grupo;
  final bool canManage;
  final bool canEditRoom;
  final ValueChanged<Aula> onEditCard;
  final ValueChanged<Aula> onEditRoom;
  final ValueChanged<Aula> onDelete;

  @override
  Widget build(BuildContext context) {
    final aula = grupo.principal;
    final color = colorFromHex(aula.corHex);
    final hasImage = aula.imagemUrl?.isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(scale: 0.96 + value * 0.04, child: child);
        },
        child: GlassPanel(
          borderRadius: 26,
          padding: EdgeInsets.zero,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              image: hasImage
                  ? DecorationImage(
                      image: NetworkImage(aula.imagemUrl!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.25),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: hasImage
                          ? Colors.white.withValues(alpha: 0.22)
                          : color,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: Text(
                        aula.icone,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          grupo.disciplina,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: hasImage
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w900,
                                height: 1.08,
                              ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          grupo.professores,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: hasImage
                                ? Colors.white.withValues(alpha: 0.86)
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            GlassChip(
                              icon: Icons.meeting_room_outlined,
                              text: grupo.salas,
                              dark: hasImage,
                            ),
                            for (final item in grupo.aulas)
                              GlassChip(
                                icon: Icons.schedule_rounded,
                                text:
                                    '${nomesDiasSemana[item.diaSemana] ?? 'Dia ${item.diaSemana}'} ${item.intervaloFormatado}',
                                dark: hasImage,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (canManage || canEditRoom)
                    PopupMenuButton<String>(
                      tooltip: 'Editar',
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: hasImage ? Colors.white : null,
                      ),
                      onSelected: (value) {
                        final parts = value.split('|');
                        if (parts.length != 2) return;
                        final target = grupo.aulas.firstWhere(
                          (aula) => aula.id == parts[1],
                          orElse: () => grupo.principal,
                        );
                        if (parts[0] == 'card') onEditCard(target);
                        if (parts[0] == 'room') onEditRoom(target);
                        if (parts[0] == 'delete') onDelete(target);
                      },
                      itemBuilder: (context) {
                        return <PopupMenuEntry<String>>[
                          for (final item
                              in grupo.aulas) ...<PopupMenuEntry<String>>[
                            if (canManage)
                              PopupMenuItem<String>(
                                value: 'card|${item.id}',
                                child: Text(
                                  'Editar aula ${item.intervaloFormatado}',
                                ),
                              ),
                            if (canEditRoom)
                              PopupMenuItem<String>(
                                value: 'room|${item.id}',
                                child: Text('Sala ${item.intervaloFormatado}'),
                              ),
                            if (canManage)
                              PopupMenuItem<String>(
                                value: 'delete|${item.id}',
                                child: Text(
                                  'Excluir ${item.intervaloFormatado}',
                                ),
                              ),
                          ],
                        ];
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 28,
    this.color = Colors.white,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? color.withValues(alpha: 0.22)
        : color.withValues(alpha: 0.72);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.70),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.055),
              blurRadius: isDark ? 22 : 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    required this.role,
    required this.user,
    required this.turma,
    required this.themeMode,
    required this.onLogin,
    required this.onLogout,
    required this.onSelectTurma,
    required this.onThemeModeChanged,
    required this.onNewClass,
    required this.onNewActivity,
    super.key,
  });

  final AppRole role;
  final User? user;
  final Turma turma;
  final ThemeMode themeMode;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final VoidCallback onSelectTurma;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final VoidCallback? onNewClass;
  final VoidCallback? onNewActivity;

  ThemeMode get _nextThemeMode {
    return switch (themeMode) {
      ThemeMode.system => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.system,
    };
  }

  String get _themeModeLabel {
    return switch (themeMode) {
      ThemeMode.system => 'Automatico',
      ThemeMode.dark => 'Escuro',
      ThemeMode.light => 'Claro',
    };
  }

  IconData get _themeModeIcon {
    return switch (themeMode) {
      ThemeMode.system => Icons.brightness_auto_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.light => Icons.light_mode_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final email = user?.email;

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            GlassPanel(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'WidgetClass',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    turma.nome,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GlassPanel(
              borderRadius: 22,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Tema',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => onThemeModeChanged(_nextThemeMode),
                      icon: Icon(_themeModeIcon),
                      label: Text(_themeModeLabel),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            DrawerActionTile(
              icon: Icons.school_outlined,
              title: 'Selecionar turma',
              subtitle: turma.curso,
              onTap: () {
                Navigator.pop(context);
                onSelectTurma();
              },
            ),
            const SizedBox(height: 10),
            DrawerActionTile(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Area administrativa',
              subtitle: email == null ? 'Login com email e senha' : role.label,
              onTap: email == null
                  ? () {
                      Navigator.pop(context);
                      onLogin();
                    }
                  : null,
            ),
            if (email != null) ...<Widget>[
              const SizedBox(height: 10),
              GlassPanel(
                borderRadius: 22,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: const Color(0xFF1B9AAA),
                      child: Text(
                        email.characters.first.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        email,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (role == AppRole.admin)
                DrawerActionTile(
                  icon: Icons.add_rounded,
                  title: 'Adicionar aula',
                  subtitle: 'Criar aula na turma',
                  onTap: () {
                    Navigator.pop(context);
                    onNewClass?.call();
                  },
                ),
              if (role == AppRole.admin) const SizedBox(height: 10),
              if (role == AppRole.admin)
                DrawerActionTile(
                  icon: Icons.add_task_rounded,
                  title: 'Adicionar atividade',
                  subtitle: 'Criar item no calendario',
                  onTap: () {
                    Navigator.pop(context);
                    onNewActivity?.call();
                  },
                ),
              if (role == AppRole.staff)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Staff pode alterar apenas a sala das aulas.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 10),
              DrawerActionTile(
                icon: Icons.logout_rounded,
                title: 'Sair',
                subtitle: role.label,
                onTap: () {
                  Navigator.pop(context);
                  onLogout();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DrawerActionTile extends StatelessWidget {
  const DrawerActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 22,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class ClassSelectorCard extends StatelessWidget {
  const ClassSelectorCard({
    required this.turma,
    required this.onTap,
    super.key,
  });

  final Turma turma;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1B9AAA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.school_outlined, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Turma selecionada',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    turma.nome,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
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
    final horario = aula?.intervaloFormatado ?? '--:--';
    final color = aula == null
        ? const Color(0xFF1B9AAA)
        : colorFromHex(aula!.corHex);

    return GlassPanel(
      borderRadius: 30,
      padding: EdgeInsets.zero,
      child: Container(
        constraints: const BoxConstraints(minHeight: 198),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: <Color>[color, color.withValues(alpha: 0.62)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                GlassChip(
                  icon: Icons.auto_awesome_rounded,
                  text: 'Proxima aula',
                  dark: true,
                ),
                const Spacer(),
                Text(aula?.icone ?? '📘', style: const TextStyle(fontSize: 34)),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 31,
                height: 1.04,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                GlassChip(
                  icon: Icons.schedule_rounded,
                  text: horario,
                  dark: true,
                ),
                GlassChip(
                  icon: Icons.person_outline_rounded,
                  text: professor,
                  dark: true,
                ),
                GlassChip(
                  icon: Icons.meeting_room_outlined,
                  text: sala,
                  dark: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GlassChip extends StatelessWidget {
  const GlassChip({
    required this.icon,
    required this.text,
    this.dark = false,
    super.key,
  });

  final IconData icon;
  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final hasDarkSurface = dark || isDarkTheme;
    final foreground = hasDarkSurface
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: dark
              ? 0.20
              : isDarkTheme
              ? 0.14
              : 0.56,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: dark ? 0.35 : 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: foreground, size: 17),
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class AgendaSummaryPanel extends StatelessWidget {
  const AgendaSummaryPanel({
    required this.atividades,
    required this.trabalhos,
    required this.avaliacoes,
    super.key,
  });

  final List<Atividade> atividades;
  final List<Atividade> trabalhos;
  final List<Atividade> avaliacoes;

  @override
  Widget build(BuildContext context) {
    final atividade = atividades.isEmpty ? null : atividades.first;
    final trabalho = trabalhos.isEmpty ? null : trabalhos.first;
    final avaliacao = avaliacoes.isEmpty ? null : avaliacoes.first;

    return Column(
      children: <Widget>[
        _AgendaSummaryCard(
          icon: Icons.event_note_outlined,
          title: 'Atividades',
          count: atividades.length,
          atividade: atividade,
          color: activityTypeCalendarColor(TipoAtividade.atividade),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _AgendaSummaryCard(
                icon: Icons.assignment_outlined,
                title: 'Trabalhos',
                count: trabalhos.length,
                atividade: trabalho,
                color: activityTypeCalendarColor(TipoAtividade.trabalho),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AgendaSummaryCard(
                icon: Icons.fact_check_outlined,
                title: 'Avaliacoes',
                count: avaliacoes.length,
                atividade: avaliacao,
                color: activityTypeCalendarColor(TipoAtividade.avaliacao),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AgendaSummaryCard extends StatelessWidget {
  const _AgendaSummaryCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.atividade,
    required this.color,
  });

  final IconData icon;
  final String title;
  final int count;
  final Atividade? atividade;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final details = atividade == null
        ? 'Agenda livre'
        : '${atividade!.materia} - ${atividade!.dataFormatada}';

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: GlassPanel(
        borderRadius: 24,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              atividade?.titulo ?? 'Nada marcado',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              details,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivitySection extends StatelessWidget {
  const ActivitySection({
    required this.title,
    required this.icon,
    required this.atividades,
    required this.canManage,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final String title;
  final IconData icon;
  final List<Atividade> atividades;
  final bool canManage;
  final VoidCallback onCreate;
  final ValueChanged<Atividade> onEdit;
  final ValueChanged<Atividade> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: title,
          subtitle: atividades.isEmpty ? 'Nada marcado' : 'Em ordem de data',
          count: atividades.length,
        ),
        const SizedBox(height: 12),
        if (canManage)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Adicionar item'),
              ),
            ),
          ),
        if (atividades.isEmpty)
          GlassPanel(
            borderRadius: 22,
            child: Row(
              children: <Widget>[
                Icon(icon),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Sem itens proximos.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          )
        else
          for (var index = 0; index < atividades.length; index++)
            ActivityCard(
              atividade: atividades[index],
              index: index,
              canManage: canManage,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
      ],
    );
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    required this.atividade,
    required this.index,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Atividade atividade;
  final int index;
  final bool canManage;
  final ValueChanged<Atividade> onEdit;
  final ValueChanged<Atividade> onDelete;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(atividade.corHex);
    final status = _daysUntilText(atividade.data);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 360 + index * 50),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(18 * (1 - value), 0),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: GlassPanel(
          borderRadius: 22,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[color, color.withValues(alpha: 0.68)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  activityTypeIcon(atividade.tipo),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            atividade.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (canManage)
                          PopupMenuButton<String>(
                            tooltip: 'Editar atividade',
                            icon: const Icon(Icons.more_vert_rounded),
                            onSelected: (value) {
                              if (value == 'edit') onEdit(atividade);
                              if (value == 'delete') onDelete(atividade);
                            },
                            itemBuilder: (context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Excluir'),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (atividade.descricao?.isNotEmpty == true) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        atividade.descricao!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        GlassChip(
                          icon: Icons.menu_book_outlined,
                          text: atividade.materia,
                        ),
                        GlassChip(
                          icon: Icons.event_outlined,
                          text: atividade.dataFormatada,
                        ),
                        GlassChip(
                          icon: activityTypeIcon(atividade.tipo),
                          text: atividade.tipo.label,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CalendarPanel extends StatefulWidget {
  const CalendarPanel({
    required this.atividades,
    required this.canManage,
    required this.onEditAtividade,
    required this.onDeleteAtividade,
    required this.onAddAtividade,
    super.key,
  });

  final List<Atividade> atividades;
  final bool canManage;
  final ValueChanged<Atividade> onEditAtividade;
  final ValueChanged<Atividade> onDeleteAtividade;
  final ValueChanged<DateTime> onAddAtividade;

  @override
  State<CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<CalendarPanel> {
  late DateTime _month;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _month = DateTime(today.year, today.month);
    _selectedDay = DateTime(today.year, today.month, today.day);
  }

  void _moveMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDay = DateTime(_month.year, _month.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    final firstDay = DateTime(_month.year, _month.month);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = firstDay.weekday - 1;
    final cells = <DateTime?>[
      for (var i = 0; i < leadingBlanks; i++) null,
      for (var day = 1; day <= daysInMonth; day++)
        DateTime(_month.year, _month.month, day),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final atividadesDoDia =
        widget.atividades
            .where((atividade) => atividade.aconteceEm(_selectedDay))
            .toList()
          ..sort((a, b) => a.data.compareTo(b.data));

    return GlassPanel(
      borderRadius: 30,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                tooltip: 'Mes anterior',
                onPressed: () => _moveMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: Text(
                    '${_monthName(_month.month)} ${_month.year}',
                    key: ValueKey<String>('${_month.month}-${_month.year}'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Proximo mes',
                onPressed: () => _moveMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const <Widget>[
              _WeekdayLabel('S'),
              _WeekdayLabel('T'),
              _WeekdayLabel('Q'),
              _WeekdayLabel('Q'),
              _WeekdayLabel('S'),
              _WeekdayLabel('S'),
              _WeekdayLabel('D'),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: cells.length,
            itemBuilder: (context, index) {
              final day = cells[index];
              if (day == null) return const SizedBox.shrink();
              final activityTypes =
                  widget.atividades
                      .where((atividade) => atividade.aconteceEm(day))
                      .map((atividade) => atividade.tipo)
                      .toSet()
                      .toList()
                    ..sort((a, b) => a.index.compareTo(b.index));
              final selected = _sameDate(day, _selectedDay);
              final today = _sameDate(day, DateTime.now());
              return AnimatedCalendarDay(
                day: day,
                selected: selected,
                today: today,
                activityTypes: activityTypes,
                onTap: () => setState(() => _selectedDay = day),
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            'Dia ${_selectedDay.day}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Column(
              key: ValueKey<String>(
                '${_selectedDay.year}-${_selectedDay.month}-${_selectedDay.day}',
              ),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (atividadesDoDia.isEmpty)
                  Text(
                    'Nenhuma atividade marcada para esse dia.',
                    style: TextStyle(
                      color: onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else ...<Widget>[
                  for (final atividade in atividadesDoDia)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CalendarEventTile(
                        icon: activityTypeIcon(atividade.tipo),
                        title: atividade.titulo,
                        subtitle:
                            '${atividade.tipo.label} - entrega ${atividade.dataFormatada} - ${atividade.materia}',
                        canManage: widget.canManage,
                        color: activityTypeCalendarColor(atividade.tipo),
                        onEdit: () => widget.onEditAtividade(atividade),
                        onDelete: () => widget.onDeleteAtividade(atividade),
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (widget.canManage) ...<Widget>[
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () => widget.onAddAtividade(_selectedDay),
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('Nova atividade no dia'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CalendarEventTile extends StatelessWidget {
  const _CalendarEventTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.canManage,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool canManage;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'edit', child: Text('Editar')),
                PopupMenuItem<String>(value: 'delete', child: Text('Excluir')),
              ],
            ),
        ],
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class AnimatedCalendarDay extends StatelessWidget {
  const AnimatedCalendarDay({
    required this.day,
    required this.selected,
    required this.today,
    required this.activityTypes,
    required this.onTap,
    super.key,
  });

  final DateTime day;
  final bool selected;
  final bool today;
  final List<TipoAtividade> activityTypes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final color = selected
        ? const Color(0xFF1B9AAA)
        : today
        ? Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: isDark ? 0.28 : 0.16)
        : (isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.54));

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 180 + day.day * 8),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0).toDouble(),
          child: Transform.scale(scale: 0.88 + 0.12 * value, child: child),
        );
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(selected ? 18 : 14),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1B9AAA)
                  : Colors.white.withValues(alpha: 0.8),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '${day.day}',
                style: TextStyle(
                  color: selected ? Colors.white : onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (
                    var index = 0;
                    index < activityTypes.length;
                    index++
                  ) ...[
                    if (index > 0) const SizedBox(width: 3),
                    _CalendarDot(
                      color: activityTypeCalendarColor(activityTypes[index]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarDot extends StatelessWidget {
  const _CalendarDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class EmptyActivities extends StatelessWidget {
  const EmptyActivities({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassPanel(
      borderRadius: 24,
      child: Row(
        children: <Widget>[
          Icon(Icons.event_available_outlined),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nenhuma atividade, trabalho ou avaliacao cadastrada.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

bool _sameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _daysUntilText(DateTime target) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(target.year, target.month, target.day);
  final days = date.difference(today).inDays;
  if (days == 0) return 'Hoje';
  if (days == 1) return 'Amanha';
  if (days < 0) return 'Passou';
  return '${days}d';
}

String _monthName(int month) {
  const names = <String>[
    'Janeiro',
    'Fevereiro',
    'Marco',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return names[month - 1];
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    required this.subtitle,
    required this.count,
    super.key,
  });

  final String title;
  final String subtitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        GlassChip(icon: Icons.view_agenda_outlined, text: '$count itens'),
      ],
    );
  }
}

class AulaCard extends StatelessWidget {
  const AulaCard({
    required this.aula,
    required this.canManage,
    required this.canEditRoom,
    required this.onEditCard,
    required this.onEditRoom,
    required this.onDelete,
    super.key,
  });

  final Aula aula;
  final bool canManage;
  final bool canEditRoom;
  final VoidCallback onEditCard;
  final VoidCallback onEditRoom;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final day = nomesDiasSemana[aula.diaSemana] ?? 'Dia ${aula.diaSemana}';
    final color = colorFromHex(aula.corHex);
    final hasImage = aula.imagemUrl?.isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassPanel(
        borderRadius: 26,
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            image: hasImage
                ? DecorationImage(
                    image: NetworkImage(aula.imagemUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.25),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: hasImage
                        ? Colors.white.withValues(alpha: 0.22)
                        : color,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Text(
                      aula.icone,
                      style: const TextStyle(fontSize: 30),
                    ),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: hasImage
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w900,
                              height: 1.08,
                            ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          GlassChip(
                            icon: Icons.calendar_month_outlined,
                            text: day,
                            dark: hasImage,
                          ),
                          GlassChip(
                            icon: Icons.schedule_rounded,
                            text: aula.intervaloFormatado,
                            dark: hasImage,
                          ),
                          GlassChip(
                            icon: Icons.meeting_room_outlined,
                            text: aula.sala,
                            dark: hasImage,
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        aula.professor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasImage
                              ? Colors.white.withValues(alpha: 0.86)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canManage || canEditRoom)
                  PopupMenuButton<String>(
                    tooltip: 'Editar',
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: hasImage ? Colors.white : null,
                    ),
                    onSelected: (value) {
                      if (value == 'card') onEditCard();
                      if (value == 'room') onEditRoom();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      if (canManage)
                        const PopupMenuItem<String>(
                          value: 'card',
                          child: Text('Editar aula'),
                        ),
                      if (canEditRoom)
                        const PopupMenuItem<String>(
                          value: 'room',
                          child: Text('Alterar sala'),
                        ),
                      if (canManage)
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Excluir'),
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
}

class EmailLoginCredentials {
  const EmailLoginCredentials({required this.email, required this.password});

  final String email;
  final String password;
}

class EmailLoginSheet extends StatefulWidget {
  const EmailLoginSheet({super.key});

  @override
  State<EmailLoginSheet> createState() => _EmailLoginSheetState();
}

class _EmailLoginSheetState extends State<EmailLoginSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      EmailLoginCredentials(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Area administrativa',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Entre com um usuario criado manualmente no Supabase.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const <String>[AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (!email.contains('@') || !email.contains('.')) {
                  return 'Informe um email valido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if ((value ?? '').isEmpty) return 'Informe a senha';
                return null;
              },
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.login_rounded),
                label: const Text('Entrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TurmaPickerSheet extends StatelessWidget {
  const TurmaPickerSheet({required this.selecionada, super.key});

  final Turma selecionada;

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Escolha sua turma',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          for (final turma in turmasDisponiveis)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassPanel(
                borderRadius: 20,
                padding: EdgeInsets.zero,
                child: ListTile(
                  onTap: () => Navigator.pop(context, turma),
                  leading: Icon(
                    turma.id == selecionada.id
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: turma.id == selecionada.id
                        ? const Color(0xFF1B9AAA)
                        : null,
                  ),
                  title: Text(
                    turma.nome,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(turma.curso),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AulaFormSheet extends StatefulWidget {
  const AulaFormSheet({
    required this.turmaInicial,
    this.aula,
    this.diaSemanaInicial,
    super.key,
  });

  final Turma turmaInicial;
  final Aula? aula;
  final int? diaSemanaInicial;

  @override
  State<AulaFormSheet> createState() => _AulaFormSheetState();
}

class _AulaFormSheetState extends State<AulaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _disciplinaController;
  late final TextEditingController _professorController;
  late final TextEditingController _salaController;
  late final TextEditingController _iconeController;
  late final TextEditingController _imagemUrlController;
  late String _turmaId;
  late int _diaSemana;
  late Duration _horarioInicio;
  late Duration _horarioFim;
  late String _corHex;

  @override
  void initState() {
    super.initState();
    final aula = widget.aula;
    _disciplinaController = TextEditingController(text: aula?.disciplina ?? '');
    _professorController = TextEditingController(text: aula?.professor ?? '');
    _salaController = TextEditingController(text: aula?.sala ?? 'F104');
    _iconeController = TextEditingController(text: aula?.icone ?? '📘');
    _imagemUrlController = TextEditingController(text: aula?.imagemUrl ?? '');
    _turmaId = aula?.turmaId ?? widget.turmaInicial.id;
    _diaSemana =
        aula?.diaSemana ??
        (widget.diaSemanaInicial?.clamp(1, 7) ?? DateTime.now().weekday);
    _horarioInicio = aula?.horarioInicio ?? const Duration(hours: 7);
    _horarioFim = aula?.horarioFim ?? const Duration(hours: 8, minutes: 40);
    _corHex = Aula.normalizeHex(aula?.corHex ?? '#1B9AAA');
  }

  @override
  void dispose() {
    _disciplinaController.dispose();
    _professorController.dispose();
    _salaController.dispose();
    _iconeController.dispose();
    _imagemUrlController.dispose();
    super.dispose();
  }

  Future<void> _selecionarHorario({required bool fim}) async {
    final atual = fim ? _horarioFim : _horarioInicio;
    final selecionado = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: atual.inHours.remainder(24),
        minute: atual.inMinutes.remainder(60),
      ),
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (selecionado == null) return;
    setState(() {
      final novo = Duration(
        hours: selecionado.hour,
        minutes: selecionado.minute,
      );
      if (fim) {
        _horarioFim = novo;
      } else {
        _horarioInicio = novo;
      }
    });
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      Aula(
        id: widget.aula?.id,
        turmaId: _turmaId,
        disciplina: _disciplinaController.text,
        professor: _professorController.text,
        sala: _salaController.text,
        diaSemana: _diaSemana,
        horarioInicio: _horarioInicio,
        horarioFim: _horarioFim,
        icone: _iconeController.text,
        corHex: _corHex,
        imagemUrl: _imagemUrlController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.aula == null ? 'Nova aula' : 'Editar aula',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _turmaId,
              decoration: const InputDecoration(
                labelText: 'Turma',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: turmasDisponiveis
                  .map(
                    (turma) => DropdownMenuItem<String>(
                      value: turma.id,
                      child: Text(turma.nome),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _turmaId = value);
              },
            ),
            const SizedBox(height: 12),
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
                  .where((entry) => entry.key <= 5)
                  .map(
                    (entry) => DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _diaSemana = value);
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: () => _selecionarHorario(fim: false),
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(
                    'Inicio ${Aula.formatDisplayTime(_horarioInicio)}',
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _selecionarHorario(fim: true),
                  icon: const Icon(Icons.timelapse_rounded),
                  label: Text('Fim ${Aula.formatDisplayTime(_horarioFim)}'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _iconeController,
              decoration: const InputDecoration(
                labelText: 'Icone ou emoji',
                prefixIcon: Icon(Icons.emoji_symbols_outlined),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imagemUrlController,
              decoration: const InputDecoration(
                labelText: 'Imagem URL opcional',
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
            const SizedBox(height: 14),
            ColorPickerRow(
              selectedHex: _corHex,
              onChanged: (value) => setState(() => _corHex = value),
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
    );
  }

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo obrigatorio' : null;
  }
}

class AtividadeFormSheet extends StatefulWidget {
  const AtividadeFormSheet({
    required this.turmaInicial,
    this.atividade,
    this.tipoInicial,
    this.dataInicial,
    super.key,
  });

  final Turma turmaInicial;
  final Atividade? atividade;
  final TipoAtividade? tipoInicial;
  final DateTime? dataInicial;

  @override
  State<AtividadeFormSheet> createState() => _AtividadeFormSheetState();
}

class _AtividadeFormSheetState extends State<AtividadeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final AulaService _aulaService = AulaService();
  late final TextEditingController _tituloController;
  late final TextEditingController _descricaoController;
  late String _turmaId;
  String? _materia;
  late TipoAtividade _tipo;
  late DateTime _data;
  late String _corHex;
  List<String> _materiasDisponiveis = <String>[];
  bool _carregandoMaterias = false;

  @override
  void initState() {
    super.initState();
    final atividade = widget.atividade;
    _materia = atividade?.materia.trim().isEmpty == true
        ? null
        : atividade?.materia.trim();
    _tituloController = TextEditingController(text: atividade?.titulo ?? '');
    _descricaoController = TextEditingController(
      text: atividade?.descricao ?? '',
    );
    _turmaId = atividade?.turmaId ?? widget.turmaInicial.id;
    _tipo = atividade?.tipo ?? widget.tipoInicial ?? TipoAtividade.atividade;
    _data =
        atividade?.data ??
        DateTime(
          (widget.dataInicial ?? DateTime.now()).year,
          (widget.dataInicial ?? DateTime.now()).month,
          (widget.dataInicial ?? DateTime.now()).day,
        );
    _corHex = atividade?.corHex ?? '#1B9AAA';
    _carregarMateriasDaTurma();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarMateriasDaTurma() async {
    final turmaId = _turmaId;
    setState(() => _carregandoMaterias = true);

    try {
      final aulas = await _aulaService.listarAulas(turmaId: turmaId);
      final materias =
          aulas
              .map((aula) => aula.disciplina.trim())
              .where((materia) => materia.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

      if (!mounted || turmaId != _turmaId) return;
      setState(() {
        _materiasDisponiveis = materias;
        if (_materia != null && !materias.contains(_materia)) {
          _materia = null;
        }
        if (_materia == null && materias.length == 1) {
          _materia = materias.first;
        }
      });
    } catch (_) {
      if (!mounted || turmaId != _turmaId) return;
      setState(() => _materiasDisponiveis = <String>[]);
    } finally {
      if (mounted && turmaId == _turmaId) {
        setState(() => _carregandoMaterias = false);
      }
    }
  }

  void _alterarTurma(String turmaId) {
    if (turmaId == _turmaId) return;
    setState(() {
      _turmaId = turmaId;
      _materia = null;
      _materiasDisponiveis = <String>[];
    });
    _carregarMateriasDaTurma();
  }

  Future<void> _selecionarData() async {
    final base = DateTime.now();
    final firstDate = DateTime(base.year - 1);
    final lastDate = DateTime(base.year + 3, 12, 31);
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (selecionada == null) return;
    setState(() {
      _data = DateTime(selecionada.year, selecionada.month, selecionada.day);
    });
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      Atividade(
        id: widget.atividade?.id,
        turmaId: _turmaId,
        materia: _materia ?? '',
        titulo: _tituloController.text,
        tipo: _tipo,
        data: _data,
        descricao: _descricaoController.text,
        corHex: _corHex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.atividade == null ? 'Nova atividade' : 'Editar atividade',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _turmaId,
              decoration: const InputDecoration(
                labelText: 'Turma',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: turmasDisponiveis
                  .map(
                    (turma) => DropdownMenuItem<String>(
                      value: turma.id,
                      child: Text(turma.nome),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) _alterarTurma(value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TipoAtividade>(
              initialValue: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                prefixIcon: Icon(Icons.assignment_outlined),
              ),
              items: TipoAtividade.values
                  .map(
                    (tipo) => DropdownMenuItem<TipoAtividade>(
                      value: tipo,
                      child: Text(tipo.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _tipo = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey<String>(
                'materia-$_turmaId-${_materia ?? ''}-${_materiasDisponiveis.length}',
              ),
              initialValue: _materiasDisponiveis.contains(_materia)
                  ? _materia
                  : null,
              decoration: InputDecoration(
                labelText: 'Materia',
                prefixIcon: const Icon(Icons.menu_book_outlined),
                helperText: _carregandoMaterias
                    ? 'Carregando materias da turma'
                    : null,
              ),
              hint: Text(
                _carregandoMaterias
                    ? 'Carregando'
                    : _materiasDisponiveis.isEmpty
                    ? 'Cadastre aulas nessa turma'
                    : 'Escolha a materia',
              ),
              items: _materiasDisponiveis
                  .map(
                    (materia) => DropdownMenuItem<String>(
                      value: materia,
                      child: Text(materia),
                    ),
                  )
                  .toList(),
              onChanged: _carregandoMaterias || _materiasDisponiveis.isEmpty
                  ? null
                  : (value) => setState(() => _materia = value),
              validator: (value) {
                if (_materiasDisponiveis.isEmpty) {
                  return 'Cadastre aulas para escolher a materia';
                }
                return value == null || value.trim().isEmpty
                    ? 'Escolha uma materia'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tituloController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Titulo',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _selecionarData,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                'Entrega ${_data.day.toString().padLeft(2, '0')}/${_data.month.toString().padLeft(2, '0')}/${_data.year}',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descricaoController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descricao (opcional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 14),
            ColorPickerRow(
              selectedHex: _corHex,
              onChanged: (value) => setState(() => _corHex = value),
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
    );
  }

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo obrigatorio' : null;
  }
}

class RoomEditSheet extends StatefulWidget {
  const RoomEditSheet({required this.aula, super.key});

  final Aula aula;

  @override
  State<RoomEditSheet> createState() => _RoomEditSheetState();
}

class _RoomEditSheetState extends State<RoomEditSheet> {
  late final TextEditingController _salaController;

  @override
  void initState() {
    super.initState();
    _salaController = TextEditingController(text: widget.aula.sala);
  }

  @override
  void dispose() {
    _salaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Alterar sala',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            widget.aula.disciplina,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _salaController,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Sala',
              prefixIcon: Icon(Icons.meeting_room_outlined),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context, _salaController.text),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Salvar sala'),
            ),
          ),
        ],
      ),
    );
  }
}

class ColorPickerRow extends StatelessWidget {
  const ColorPickerRow({
    required this.selectedHex,
    required this.onChanged,
    super.key,
  });

  final String selectedHex;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        for (final hex in _cardColorHexes) ...[
          Builder(
            builder: (context) {
              final selected = selectedHex == hex;
              return AnimatedScale(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                scale: selected ? 1.12 : 1,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onChanged(hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorFromHex(hex),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.white,
                        width: selected ? 3 : 2,
                      ),
                      boxShadow: selected
                          ? <BoxShadow>[
                              BoxShadow(
                                color: colorFromHex(
                                  hex,
                                ).withValues(alpha: 0.38),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class SheetShell extends StatelessWidget {
  const SheetShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const <Color>[Color(0xFF102234), Color(0xFF0B1625)]
                : const <Color>[Color(0xFFF8FAFC), Color(0xFFEAF8F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.24)
                      : const Color(0xFFD6DCE8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 22),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 20,
      color: const Color(0xFFFFE8E8),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline, color: Color(0xFFB42318)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7A271A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptySchedule extends StatelessWidget {
  const EmptySchedule({required this.turma, super.key});

  final Turma turma;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      borderRadius: 24,
      child: Row(
        children: <Widget>[
          const Icon(Icons.event_busy_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Nenhuma aula cadastrada para ${turma.nome}.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
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

Color colorFromHex(String hex) {
  final clean = Aula.normalizeHex(hex).replaceFirst('#', '');
  return Color(int.parse('FF$clean', radix: 16));
}

Color activityTypeCalendarColor(TipoAtividade tipo) {
  return switch (tipo) {
    TipoAtividade.atividade => const Color(0xFF2563EB),
    TipoAtividade.trabalho => const Color(0xFF7C3AED),
    TipoAtividade.avaliacao => const Color(0xFFFF3B5C),
  };
}

IconData activityTypeIcon(TipoAtividade tipo) {
  return switch (tipo) {
    TipoAtividade.atividade => Icons.event_note_outlined,
    TipoAtividade.trabalho => Icons.assignment_outlined,
    TipoAtividade.avaliacao => Icons.fact_check_outlined,
  };
}

const List<String> _cardColorHexes = <String>[
  '#1B9AAA',
  '#5B7CFA',
  '#FF4D6D',
  '#FFB703',
  '#00B894',
  '#7C3AED',
  '#FF7A00',
  '#111827',
  '#2563EB',
  '#14B8A6',
  '#0EA5E9',
  '#84CC16',
  '#EF4444',
  '#EC4899',
  '#A855F7',
  '#F97316',
  '#64748B',
  '#0F172A',
];
