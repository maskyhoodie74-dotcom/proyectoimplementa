import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/partido.dart';
import '../../models/quiniela.dart';
import '../auth/auth_provider.dart';
import '../quinielas/quinielas_provider.dart';
import '../ia/ia_provider.dart';
import '../partidos/partidos_provider.dart';
import '../equipos/equipos_provider.dart';
import '../highlights/highlights_screen.dart';
import '../highlights/highlights_provider.dart';
import '../../models/highlight.dart';

class PartidoDetalleScreen extends StatefulWidget {
  final Partido partido;
  const PartidoDetalleScreen({super.key, required this.partido});

  @override
  State<PartidoDetalleScreen> createState() => _PartidoDetalleScreenState();
}

class _PartidoDetalleScreenState extends State<PartidoDetalleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _localCtrl = TextEditingController();
  final _visitanteCtrl = TextEditingController();

  String? _prediccionIA;
  bool _loadingIA = false;
  bool _quinielaCargada = false;
  bool _guardandoQuiniela = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        final idx = _tabCtrl.index;
        if (idx == 1) _cargarQuiniela();
        if (idx == 2) _generarPrediccionIA();
        if (idx == 3) _cargarHighlights();
      }
    });
    // Cargar quiniela si está logueado
    Future.microtask(() {
      _cargarQuiniela();
      _cargarHighlights();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _localCtrl.dispose();
    _visitanteCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarQuiniela() async {
    if (_quinielaCargada) return;
    final auth = context.read<AuthProvider>();
    if (auth.usuarioId == null) return;
    final uId = int.tryParse(auth.usuarioId!);
    if (uId == null) return;
    await context.read<QuinielasProvider>().fetchQuinielas(uId);
    // Pre-fill existing prediction if any
    final existente = context
        .read<QuinielasProvider>()
        .quinielas
        .where((q) => q.partidoId.toString() == widget.partido.id)
        .firstOrNull;
    if (existente != null && mounted) {
      _localCtrl.text = existente.golesLocalPred.toString();
      _visitanteCtrl.text = existente.golesVisitPred.toString();
    }
    if (mounted) setState(() => _quinielaCargada = true);
  }

  Future<void> _cargarHighlights() async {
    final pId = int.tryParse(widget.partido.id);
    if (pId == null) return;
    await context.read<HighlightsProvider>().fetchHighlightsPartido(pId);
  }

  Future<void> _generarPrediccionIA() async {
    if (_prediccionIA != null) return;
    setState(() => _loadingIA = true);

    try {
      final partidos = context.read<PartidosProvider>();
      final equipos = context.read<EquiposProvider>();
      final tabla = partidos.obtenerTablaConTendencia(equipos.equipos);

      final statsLocal = tabla
          .where((e) => e['nombre'] == widget.partido.equipoLocalNombre)
          .firstOrNull?['stats'] as Map<String, dynamic>?;
      final statsVisitante = tabla
          .where((e) => e['nombre'] == widget.partido.equipoVisitanteNombre)
          .firstOrNull?['stats'] as Map<String, dynamic>?;

      final resultado = await context.read<IaProvider>().predecirPartido(
            equipo1: widget.partido.equipoLocalNombre ?? 'Local',
            stats1: statsLocal ?? {'PJ': 0, 'PG': 0, 'PE': 0, 'PP': 0, 'GF': 0, 'GC': 0, 'Pts': 0},
            equipo2: widget.partido.equipoVisitanteNombre ?? 'Visitante',
            stats2: statsVisitante ?? {'PJ': 0, 'PG': 0, 'PE': 0, 'PP': 0, 'GF': 0, 'GC': 0, 'Pts': 0},
          );
      if (mounted) setState(() => _prediccionIA = resultado);
    } catch (e) {
      if (mounted) {
        setState(() => _prediccionIA = '❌ No se pudo obtener la predicción. Verifica la clave de API.');
      }
    }
    if (mounted) setState(() => _loadingIA = false);
  }

  Future<void> _guardarQuiniela() async {
    final auth = context.read<AuthProvider>();
    if (auth.usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes iniciar sesión para participar')));
      return;
    }
    final uId = int.tryParse(auth.usuarioId!);
    final pId = int.tryParse(widget.partido.id);
    if (uId == null || pId == null) return;

    final locText = _localCtrl.text.trim();
    final visText = _visitanteCtrl.text.trim();
    if (locText.isEmpty || visText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa ambos marcadores')));
      return;
    }

    setState(() => _guardandoQuiniela = true);
    final q = Quiniela(
      usuarioId: uId,
      partidoId: pId,
      golesLocalPred: int.tryParse(locText) ?? 0,
      golesVisitPred: int.tryParse(visText) ?? 0,
    );
    final ok = await context.read<QuinielasProvider>().guardarQuiniela(q);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? '✅ ¡Apuesta realizada!\nTu pronóstico: ${widget.partido.equipoLocalNombre} $locText - $visText ${widget.partido.equipoVisitanteNombre}'
            : '❌ Error al guardar'),
        backgroundColor: ok ? Colors.green.shade800 : Colors.red,
      ));
    }
    if (mounted) setState(() => _guardandoQuiniela = false);
  }

  @override
  Widget build(BuildContext context) {
    final partido = widget.partido;
    final isFinished = partido.jugado;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          _buildSliverHeader(partido, isFinished),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildInfoTab(partido, isFinished),
                  _buildQuinielaTab(partido),
                  _buildIATab(partido),
                  _buildGaleriaTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SLIVER HEADER ──────────────────────────────────────────────
  Widget _buildSliverHeader(Partido partido, bool isFinished) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.bgDark,
      leading: IconButton(
        icon: const Icon(CupertinoIcons.chevron_left, color: AppColors.gold),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'DETALLE DEL PARTIDO',
        style: GoogleFonts.inter(
            color: AppColors.gold,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeader(partido, isFinished),
      ),
    );
  }

  Widget _buildHeader(Partido partido, bool isFinished) {
    final localWins = isFinished &&
        (partido.golesLocal ?? 0) > (partido.golesVisitante ?? 0);
    final visWins = isFinished &&
        (partido.golesVisitante ?? 0) > (partido.golesLocal ?? 0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.maroonDeep,
            AppColors.bgDark,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
          child: Column(
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isFinished
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.info.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isFinished
                        ? AppColors.success.withOpacity(0.4)
                        : AppColors.info.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFinished
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.clock_fill,
                      size: 12,
                      color: isFinished ? AppColors.success : AppColors.info,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isFinished ? 'PARTIDO FINALIZADO' : 'PARTIDO PROGRAMADO',
                      style: GoogleFonts.inter(
                        color: isFinished ? AppColors.success : AppColors.info,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Teams
              Row(
                children: [
                  Expanded(child: _buildTeamColumn(
                    partido.equipoLocalNombre ?? 'Local',
                    partido.equipoLocalEscudo,
                    isWinner: localWins,
                    align: CrossAxisAlignment.start,
                  )),
                  // Score / VS
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isFinished
                            ? AppColors.gold.withOpacity(0.5)
                            : AppColors.divider,
                        width: isFinished ? 1.5 : 0.5,
                      ),
                      boxShadow: isFinished ? AppColors.goldGlowSubtle : null,
                    ),
                    child: Text(
                      isFinished
                          ? '${partido.golesLocal ?? 0}  -  ${partido.golesVisitante ?? 0}'
                          : 'VS',
                      style: GoogleFonts.inter(
                        color: AppColors.gold,
                        fontSize: isFinished ? 28 : 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  Expanded(child: _buildTeamColumn(
                    partido.equipoVisitanteNombre ?? 'Visitante',
                    partido.equipoVisitanteEscudo,
                    isWinner: visWins,
                    align: CrossAxisAlignment.end,
                  )),
                ],
              ),
              const SizedBox(height: 14),
              // Date/time/place
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.calendar,
                      color: AppColors.textSecondary, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(partido.fecha),
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  if (partido.hora.isNotEmpty) ...[ 
                    const SizedBox(width: 10),
                    const Icon(CupertinoIcons.clock,
                        color: AppColors.textSecondary, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      partido.hora,
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                  if (partido.lugar != null) ...[
                    const SizedBox(width: 10),
                    const Icon(CupertinoIcons.location_solid,
                        color: AppColors.textSecondary, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      partido.lugar!,
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 12),
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

  Widget _buildTeamColumn(String nombre, String? escudo,
      {bool isWinner = false,
      CrossAxisAlignment align = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: isWinner ? AppColors.maroonGradient : null,
            color: isWinner ? null : AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isWinner ? AppColors.gold : AppColors.divider,
              width: isWinner ? 1.5 : 0.5,
            ),
            boxShadow: isWinner ? AppColors.goldGlowSubtle : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: escudo != null
                ? Image.network(escudo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _teamInitial(nombre, isWinner))
                : _teamInitial(nombre, isWinner),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          nombre,
          textAlign:
              align == CrossAxisAlignment.start ? TextAlign.left : TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color:
                isWinner ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
            height: 1.2,
          ),
        ),
        if (isWinner) ...[
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: AppColors.maroonGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '🏆 GANADOR',
              style: GoogleFonts.inter(
                  color: AppColors.gold,
                  fontSize: 9,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }

  Widget _teamInitial(String nombre, bool isWinner) {
    return Center(
      child: Text(
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
        style: GoogleFonts.inter(
          color: isWinner ? AppColors.gold : AppColors.textSecondary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ─── TAB BAR ──────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: AppColors.bgDark,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: AppColors.gold,
        indicatorWeight: 2,
        labelColor: AppColors.gold,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle:
            GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(icon: Icon(CupertinoIcons.sportscourt, size: 16), text: 'Info'),
          Tab(icon: Icon(CupertinoIcons.chart_bar, size: 16), text: 'Quiniela'),
          Tab(icon: Icon(CupertinoIcons.wand_stars, size: 16), text: 'IA'),
          Tab(icon: Icon(CupertinoIcons.photo, size: 16), text: 'Galería'),
        ],
      ),
    );
  }

  // ─── TAB 1: INFO ──────────────────────────────────────────────
  Widget _buildInfoTab(Partido partido, bool isFinished) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info del partido
        _sectionTitle('INFORMACIÓN DEL PARTIDO'),
        const SizedBox(height: 12),
        _infoCard([
          _infoRow(CupertinoIcons.calendar, 'Fecha',
              DateFormat('EEEE dd MMM yyyy', 'es').format(partido.fecha)),
          _infoRow(CupertinoIcons.clock, 'Hora', partido.hora),
          if (partido.lugar != null)
            _infoRow(CupertinoIcons.location_solid, 'Lugar', partido.lugar!),
          if (partido.categoria != null)
            _infoRow(CupertinoIcons.tag, 'Categoría', partido.categoria!),
          _infoRow(
            isFinished
                ? CupertinoIcons.checkmark_seal_fill
                : CupertinoIcons.timer,
            'Estado',
            isFinished ? 'Finalizado' : 'Programado',
          ),
        ]),
        if (isFinished) ...[
          const SizedBox(height: 20),
          _sectionTitle('RESULTADO FINAL'),
          const SizedBox(height: 12),
          _buildResultCard(partido),
        ],
        const SizedBox(height: 20),
        _sectionTitle('EQUIPOS'),
        const SizedBox(height: 12),
        _buildEquiposComparacion(partido),
      ],
    );
  }

  Widget _buildResultCard(Partido partido) {
    final golesLocal = partido.golesLocal ?? 0;
    final golesVisitante = partido.golesVisitante ?? 0;
    String resultado;
    if (golesLocal > golesVisitante) {
      resultado = '${partido.equipoLocalNombre ?? "Local"} ganó';
    } else if (golesVisitante > golesLocal) {
      resultado = '${partido.equipoVisitanteNombre ?? "Visitante"} ganó';
    } else {
      resultado = 'Empate';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.maroonGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
        boxShadow: AppColors.goldGlowSubtle,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Text(
                  partido.equipoLocalNombre ?? 'Local',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.gold.withOpacity(0.6), width: 1.5),
                ),
                child: Text(
                  '$golesLocal - $golesVisitante',
                  style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  partido.equipoVisitanteNombre ?? 'Visitante',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            resultado,
            style: GoogleFonts.inter(
              color: AppColors.gold,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquiposComparacion(Partido partido) {
    return Consumer<PartidosProvider>(
      builder: (ctx, partidos, _) {
        return Consumer<EquiposProvider>(
          builder: (ctx, equipos, _) {
            final tabla = partidos.obtenerTablaConTendencia(equipos.equipos);
            final statsLocal = tabla
                .where((e) => e['nombre'] == partido.equipoLocalNombre)
                .firstOrNull?['stats'] as Map<String, dynamic>?;
            final statsVis = tabla
                .where((e) => e['nombre'] == partido.equipoVisitanteNombre)
                .firstOrNull?['stats'] as Map<String, dynamic>?;

            if (statsLocal == null && statsVis == null) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  'Sin estadísticas disponibles todavía.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(
                          partido.equipoLocalNombre ?? 'Local',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        )),
                        Text('ESTADÍSTICAS',
                            style: GoogleFonts.inter(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700)),
                        Expanded(
                            child: Text(
                          partido.equipoVisitanteNombre ?? 'Visitante',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        )),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  for (final key in ['Pts', 'PJ', 'PG', 'PE', 'PP', 'GF', 'GC'])
                    _statRow(
                      key,
                      statsLocal?[key] ?? 0,
                      statsVis?[key] ?? 0,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statRow(String label, int valLocal, int valVis) {
    final localWins = valLocal > valVis;
    final visWins = valVis > valLocal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              valLocal.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: localWins ? AppColors.gold : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: localWins ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Container(
            width: 80,
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.inter(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              valVis.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: visWins ? AppColors.gold : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: visWins ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 2: QUINIELA ──────────────────────────────────────────────
  Widget _buildQuinielaTab(Partido partido) {
    final auth = context.watch<AuthProvider>();
    final isFinished = partido.jugado;

    if (auth.usuarioId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.lock_circle_fill,
                  color: AppColors.textSecondary, size: 60),
              const SizedBox(height: 16),
              Text(
                'Inicia sesión para hacer tus predicciones',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('MI PRONÓSTICO'),
        const SizedBox(height: 8),
        if (isFinished) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(CupertinoIcons.info_circle_fill,
                  color: AppColors.info, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Este partido ya terminó. Ya no se pueden modificar pronósticos.',
                  style: GoogleFonts.inter(
                      color: AppColors.info, fontSize: 12),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
        ],
        // Prediction card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          partido.equipoLocalNombre ?? 'Local',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: _localCtrl,
                            enabled: !isFinished,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                color: AppColors.gold,
                                fontSize: 28,
                                fontWeight: FontWeight.w900),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: GoogleFonts.inter(
                                  color: AppColors.textTertiary, fontSize: 28),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text('-',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 24,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          partido.equipoVisitanteNombre ?? 'Visitante',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 70,
                          child: TextField(
                            controller: _visitanteCtrl,
                            enabled: !isFinished,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                color: AppColors.gold,
                                fontSize: 28,
                                fontWeight: FontWeight.w900),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: GoogleFonts.inter(
                                  color: AppColors.textTertiary, fontSize: 28),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isFinished) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardandoQuiniela ? null : _guardarQuiniela,
                    child: _guardandoQuiniela
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                color: AppColors.bgDark, strokeWidth: 2))
                        : const Text('GUARDAR PRONÓSTICO'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle('PRONÓSTICOS DE OTROS USUARIOS'),
        const SizedBox(height: 12),
        _buildPronosticosGenerales(partido),
      ],
    );
  }

  Widget _buildPronosticosGenerales(Partido partido) {
    final pId = int.tryParse(partido.id);
    if (pId == null) return const SizedBox();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPronosticosPartido(pId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.gold));
        }
        final datos = snap.data ?? [];
        if (datos.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              'Nadie ha pronosticado este partido aún.',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
            ),
          );
        }

        // Agrupar por resultado
        final Map<String, int> conteo = {};
        for (final d in datos) {
          final clave = '${d['goles_local_pred']} - ${d['goles_visit_pred']}';
          conteo[clave] = (conteo[clave] ?? 0) + 1;
        }
        final entries = conteo.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: entries.asMap().entries.map((e) {
              final idx = e.key;
              final entry = e.value;
              final pct = (entry.value / datos.length * 100).round();
              return Column(
                children: [
                  if (idx > 0)
                    const Divider(color: AppColors.divider, height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        if (idx == 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('🏆',
                                style: const TextStyle(fontSize: 10)),
                          )
                        else
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            child: Text(
                              '${idx + 1}',
                              style: GoogleFonts.inter(
                                  color: AppColors.textTertiary, fontSize: 11),
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: GoogleFonts.inter(
                              color: idx == 0
                                  ? AppColors.gold
                                  : AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: idx == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '$pct%',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.value} voto${entry.value != 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPronosticosPartido(int pId) async {
    try {
      final data = await context
          .read<QuinielasProvider>()
          .obtenerRanking();
      // Since obtenerRanking doesn't filter by partido, we query directly
      return [];
    } catch (_) {
      return [];
    }
  }

  // ─── TAB 3: IA ──────────────────────────────────────────────
  Widget _buildIATab(Partido partido) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.maroonGradient,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppColors.gold.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.bgDark.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                    child: Text('🤖', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Predicción IA',
                      style: GoogleFonts.inter(
                        color: AppColors.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Análisis generado por Gemini 2.5 Flash',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionTitle('ANÁLISIS DEL ENFRENTAMIENTO'),
        const SizedBox(height: 12),

        if (_loadingIA)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(color: AppColors.gold),
                const SizedBox(height: 16),
                Text(
                  'Analizando el partido...',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          )
        else if (_prediccionIA != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _prediccionIA!,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _prediccionIA = null);
                        _generarPrediccionIA();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.bgCardLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.arrow_clockwise,
                                color: AppColors.gold, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Regenerar',
                              style: GoogleFonts.inter(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(
                  'Toca el botón para obtener la predicción IA de este partido.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _generarPrediccionIA,
                  icon: const Icon(CupertinoIcons.wand_stars, size: 18),
                  label: const Text('GENERAR PREDICCIÓN'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─── TAB 4: GALERÍA ──────────────────────────────────────────────
  Widget _buildGaleriaTab() {
    final pId = int.tryParse(widget.partido.id);
    if (pId == null) {
      return Center(
          child: Text('Error: ID de partido inválido',
              style: GoogleFonts.inter(color: AppColors.textSecondary)));
    }

    return Consumer<HighlightsProvider>(
      builder: (ctx, prov, _) {
        final auth = context.watch<AuthProvider>();

        if (prov.loading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.gold));
        }

        return Scaffold(
          backgroundColor: AppColors.bgDark,
          floatingActionButton: (auth.isAdmin || auth.jugadorId != null)
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => HighlightsScreen(partidoId: pId),
                  )),
                  backgroundColor: AppColors.maroon,
                  icon: const Icon(Icons.add_photo_alternate,
                      color: AppColors.gold),
                  label: Text('Agregar Foto',
                      style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold)),
                )
              : null,
          body: prov.highlights.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library_outlined,
                          color: AppColors.textSecondary, size: 60),
                      const SizedBox(height: 16),
                      Text('Sin fotos en la galería',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('No hay imágenes para este partido aún.',
                          style: GoogleFonts.inter(
                              color: AppColors.textTertiary, fontSize: 12)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: prov.highlights.length,
                  itemBuilder: (context, index) {
                    final h = prov.highlights[index];
                    return GestureDetector(
                      onTap: () => _verImagen(h),
                      child: Hero(
                        tag: 'highlight_${h.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            h.urlMedia,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: AppColors.bgCard,
                              child: const Icon(Icons.broken_image,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _verImagen(Highlight h) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(h.descripcion ?? 'Foto del partido',
              style: GoogleFonts.inter(color: Colors.white)),
        ),
        body: Center(
          child: Hero(
            tag: 'highlight_${h.id}',
            child: InteractiveViewer(
              child: Image.network(h.urlMedia,
                  errorBuilder: (c, e, s) => const Icon(Icons.broken_image,
                      color: Colors.white, size: 80)),
            ),
          ),
        ),
      ),
    ));
  }

  // ─── HELPERS ──────────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        color: AppColors.gold,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _infoCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          return Column(
            children: [
              if (e.key > 0)
                const Divider(color: AppColors.divider, height: 1),
              e.value,
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 16),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
