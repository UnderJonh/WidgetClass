import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/aula.dart';
import 'models/turma.dart';
import 'services/aula_service.dart';
import 'services/local_settings_service.dart';
import 'services/session_service.dart';
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
      title: 'WidgetClass',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B9AAA),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F5F8),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.72),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF1B9AAA), width: 1.4),
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
  final LocalSettingsService _settingsService = LocalSettingsService();
  final SessionService _sessionService = SessionService();

  late StreamSubscription<AuthState> _authSubscription;

  Turma _turmaSelecionada = turmaById('eletronica_3a');
  AppRole _role = AppRole.aluno;
  User? _user;
  List<Aula> _aulas = <Aula>[];
  Aula? _proximaAula;
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
    if (!mounted) return;
    setState(() => _turmaSelecionada = turmaById(turmaId));
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
      final aulas = await _aulaService.listarAulas(
        turmaId: _turmaSelecionada.id,
      );
      final proxima = proximaAulaDoDia(aulas);
      await WidgetSyncService.sincronizarProximaAula(proxima);

      if (!mounted) return;
      setState(() {
        _aulas = aulas;
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

  Future<void> _salvarAula({Aula? aula}) async {
    if (!_role.canManageClasses) {
      _mostrarMensagem('Somente administradores podem editar o card completo.');
      return;
    }

    final resultado = await showModalBottomSheet<Aula>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AulaFormSheet(aula: aula, turmaInicial: _turmaSelecionada),
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

  @override
  Widget build(BuildContext context) {
    final canAdd = _role.canManageClasses;

    return Scaffold(
      drawer: AppDrawer(
        role: _role,
        user: _user,
        turma: _turmaSelecionada,
        onLogin: _entrarComEmail,
        onLogout: _sair,
        onSelectTurma: _selecionarTurma,
        onNewClass: canAdd ? () => _salvarAula() : null,
      ),
      appBar: AppBar(
        title: const Text('WidgetClass'),
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
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: _salvando ? null : () => _salvarAula(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova aula'),
            )
          : null,
      body: Stack(
        children: <Widget>[
          const AppBackdrop(),
          RefreshIndicator(
            onRefresh: _carregarAulas,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: <Widget>[
                ClassSelectorCard(
                  turma: _turmaSelecionada,
                  onTap: _selecionarTurma,
                ),
                const SizedBox(height: 16),
                NextClassPanel(aula: _proximaAula, carregando: _carregando),
                const SizedBox(height: 24),
                SectionHeader(
                  title: 'Aulas da semana',
                  count: _aulas.length,
                  subtitle: _turmaSelecionada.nome,
                ),
                if (_erro != null) ...<Widget>[
                  const SizedBox(height: 14),
                  ErrorBanner(message: _erro!),
                ],
                const SizedBox(height: 14),
                if (_carregando && _aulas.isEmpty)
                  const LoadingSchedule()
                else if (_aulas.isEmpty)
                  EmptySchedule(turma: _turmaSelecionada)
                else
                  for (final aula in _aulas)
                    AulaCard(
                      aula: aula,
                      canManage: _role.canManageClasses,
                      canEditRoom: _role.canEditRooms,
                      onEditCard: () => _salvarAula(aula: aula),
                      onEditRoom: () => _editarSala(aula),
                      onDelete: () => _excluirAula(aula),
                    ),
              ],
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

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Color(0xFFEAF8F8),
            Color(0xFFF4F0FF),
            Color(0xFFF8FAFC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SizedBox.expand(),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.055),
              blurRadius: 16,
              offset: const Offset(0, 8),
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
    required this.onLogin,
    required this.onLogout,
    required this.onSelectTurma,
    required this.onNewClass,
    super.key,
  });

  final AppRole role;
  final User? user;
  final Turma turma;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final VoidCallback onSelectTurma;
  final VoidCallback? onNewClass;

  @override
  Widget build(BuildContext context) {
    final email = user?.email;

    return Drawer(
      backgroundColor: const Color(0xFFF8FAFC),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            GlassPanel(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.grid_view_rounded, size: 34),
                  const SizedBox(height: 16),
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
                      color: const Color(0xFF526070),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
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
                  subtitle: 'Criar card na turma',
                  onTap: onNewClass,
                ),
              if (role == AppRole.staff)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Staff pode alterar apenas a sala dos cards.',
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
                  const Text(
                    'Turma selecionada',
                    style: TextStyle(
                      color: Color(0xFF526070),
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
    final foreground = dark ? Colors.white : const Color(0xFF17212B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (dark ? Colors.white : Colors.white).withValues(
          alpha: dark ? 0.20 : 0.56,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
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
                style: const TextStyle(
                  color: Color(0xFF526070),
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
                                  : const Color(0xFF111827),
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
                              : const Color(0xFF526070),
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
                          child: Text('Editar card'),
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
            const Text(
              'Entre com um usuario criado manualmente no Supabase.',
              style: TextStyle(
                color: Color(0xFF526070),
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
  const AulaFormSheet({required this.turmaInicial, this.aula, super.key});

  final Turma turmaInicial;
  final Aula? aula;

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
    _diaSemana = aula?.diaSemana ?? DateTime.now().weekday.clamp(1, 5);
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
              widget.aula == null ? 'Nova aula' : 'Editar card',
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
            style: const TextStyle(
              color: Color(0xFF526070),
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
        for (final hex in _cardColorHexes)
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onChanged(hex),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colorFromHex(hex),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedHex == hex ? Colors.black : Colors.white,
                  width: selectedHex == hex ? 3 : 2,
                ),
              ),
            ),
          ),
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
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFF8FAFC), Color(0xFFEAF8F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6DCE8),
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

const List<String> _cardColorHexes = <String>[
  '#1B9AAA',
  '#5B7CFA',
  '#FF4D6D',
  '#FFB703',
  '#00B894',
  '#7C3AED',
  '#FF7A00',
  '#111827',
];
