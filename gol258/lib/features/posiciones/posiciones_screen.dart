import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../partidos/partidos_provider.dart';
import '../jugadores/jugadores_provider.dart';
import '../equipos/equipos_provider.dart';
import '../../core/theme.dart';

class PosicionesScreen extends StatefulWidget {
  const PosicionesScreen({super.key});
  @override
  State<PosicionesScreen> createState() => _PosicionesScreenState();
}

class _PosicionesScreenState extends State<PosicionesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      if (!mounted) return;
      context.read<PartidosProvider>().fetchPartidos();
      context.read<JugadoresProvider>().fetchJugadores();
      context.read<EquiposProvider>().fetchEquipos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partidos = context.watch<PartidosProvider>();
    final jugadoresP = context.watch<JugadoresProvider>();
    final equiposP = context.watch<EquiposProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: Text('ESTADÍSTICAS',
            style: GoogleFonts.inter(
                color: AppColors.gold, fontSize: 20, letterSpacing: 2)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          indicatorWeight: 2,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
          tabs: const [
            Tab(text: 'POSICIONES'),
            Tab(text: 'GOLEADORES'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPosicionesTab(partidos, equiposP),
          _buildGoleadoresTab(jugadoresP),
        ],
      ),
    );
  }

  // ────────────────────────────── POSICIONES ──────────────────────────────
  Widget _buildPosicionesTab(PartidosProvider partidos, EquiposProvider equiposP) {
    final tablaConTendencia = partidos.obtenerTablaConTendencia(equiposP.equipos);

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.bgCard,
      onRefresh: () async {
        await context.read<PartidosProvider>().fetchPartidos();
        await context.read<EquiposProvider>().fetchEquipos();
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          final contentWidth = isDesktop ? 1000.0 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.all(isDesktop ? 32 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildHeader(),
                    const SizedBox(height: 6),
                    if (partidos.loading || equiposP.loading)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: AppColors.gold),
                      ))
                    else if (tablaConTendencia.isEmpty)
                      _buildEmptyState('Aún no hay equipos registrados.')
                    else
                      ...tablaConTendencia.asMap().entries.map((e) {
                        final pos = e.key + 1;
                        final entry = e.value;
                        return _buildRow(pos, entry['nombre'], entry['stats'], entry['tendencia']);
                      }),
                    const SizedBox(height: 24),
                    _buildLegend(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.goldGlow,
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: _headerStyle())),
          Expanded(child: Text('EQUIPO', style: _headerStyle())),
          SizedBox(width: 32, child: Text('PJ', textAlign: TextAlign.center, style: _headerStyle())),
          SizedBox(width: 32, child: Text('PG', textAlign: TextAlign.center, style: _headerStyle())),
          SizedBox(width: 32, child: Text('PE', textAlign: TextAlign.center, style: _headerStyle())),
          SizedBox(width: 32, child: Text('PP', textAlign: TextAlign.center, style: _headerStyle())),
          SizedBox(width: 32, child: Text('GD', textAlign: TextAlign.center, style: _headerStyle())),
          SizedBox(width: 36, child: Text('PTS', textAlign: TextAlign.center, style: _headerStyle())),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Text(msg,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 14, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildRow(int pos, String nombre, Map<String, dynamic> stats, int tendencia) {
    final gd = (stats['GF'] ?? 0) - (stats['GC'] ?? 0);
    final isTop3 = pos <= 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isTop3 ? AppColors.maroonDeep : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pos == 1 ? AppColors.gold.withValues(alpha: 0.5) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                pos == 1
                    ? const Text('🥇', style: TextStyle(fontSize: 16))
                    : pos == 2
                        ? const Text('🥈', style: TextStyle(fontSize: 16))
                        : pos == 3
                            ? const Text('🥉', style: TextStyle(fontSize: 16))
                            : Text('$pos',
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                if (tendencia != 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tendencia > 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: tendencia > 0 ? Colors.green : Colors.red,
                        size: 14,
                      ),
                      Text(
                        '${tendencia.abs()}',
                        style: GoogleFonts.inter(
                          color: tendencia > 0 ? Colors.green : Colors.red,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else
                   const Icon(Icons.remove, color: AppColors.textSecondary, size: 10),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.maroonDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(nombre,
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          SizedBox(width: 32, child: Text('${stats['PJ'] ?? 0}', textAlign: TextAlign.center, style: _cellStyle())),
          SizedBox(width: 32, child: Text('${stats['PG'] ?? 0}', textAlign: TextAlign.center, style: _cellStyle())),
          SizedBox(width: 32, child: Text('${stats['PE'] ?? 0}', textAlign: TextAlign.center, style: _cellStyle())),
          SizedBox(width: 32, child: Text('${stats['PP'] ?? 0}', textAlign: TextAlign.center, style: _cellStyle())),
          SizedBox(
            width: 32,
            child: Text(
              gd > 0 ? '+$gd' : '$gd',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: gd > 0
                    ? AppColors.success
                    : gd < 0
                        ? AppColors.error
                        : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text('${stats['Pts'] ?? 0}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LEYENDA',
              style: GoogleFonts.inter(
                  color: AppColors.gold,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 24,
            runSpacing: 6,
            children: [
              _legendItem('PJ', 'Partidos Jugados'),
              _legendItem('PG', 'Partidos Ganados'),
              _legendItem('PE', 'Partidos Empatados'),
              _legendItem('PP', 'Partidos Perdidos'),
              _legendItem('GD', 'Diferencia de Goles'),
              _legendItem('PTS', 'Puntos (G=3, E=1, P=0)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String abbr, String full) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(abbr,
            style: GoogleFonts.inter(
                color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Text('= $full',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  // ────────────────────────────── GOLEADORES ──────────────────────────────
  Widget _buildGoleadoresTab(JugadoresProvider jugadoresP) {
    final goleadores = jugadoresP.topGoleadores;

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.bgCard,
      onRefresh: () => context.read<JugadoresProvider>().fetchJugadores(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1000.0 : double.infinity),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.all(isDesktop ? 32 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // Header goleadores
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.goldGlow,
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 32, child: Text('#', style: _headerStyle())),
                          Expanded(child: Text('JUGADOR', style: _headerStyle())),
                          SizedBox(width: 60, child: Text('EQUIPO', textAlign: TextAlign.center, style: _headerStyle())),
                          SizedBox(width: 50, child: Text('GOLES', textAlign: TextAlign.center, style: _headerStyle())),
                          SizedBox(width: 50, child: Text('ASIST.', textAlign: TextAlign.center, style: _headerStyle())),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (jugadoresP.loading)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: AppColors.gold),
                      ))
                    else if (goleadores.isEmpty)
                      _buildEmptyState('Aún no hay goles registrados.')
                    else
                      ...goleadores.asMap().entries.map((e) {
                        final pos = e.key + 1;
                        final j = e.value;
                        return _buildGoleadorRow(pos, j);
                      }),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoleadorRow(int pos, dynamic jugador) {
    final isTop3 = pos <= 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isTop3 ? AppColors.maroonDeep : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pos == 1 ? AppColors.gold.withOpacity(0.5) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: pos == 1
                ? const Text('🥇', style: TextStyle(fontSize: 16))
                : pos == 2
                    ? const Text('🥈', style: TextStyle(fontSize: 16))
                    : pos == 3
                        ? const Text('🥉', style: TextStyle(fontSize: 16))
                        : Text('$pos',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.maroonDark,
                    border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text('#${jugador.numero}',
                        style: GoogleFonts.inter(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(jugador.nombre,
                          style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                      Text(jugador.posicion ?? 'Jugador',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              jugador.equipoNombre != null
                  ? _truncate(jugador.equipoNombre!, 6)
                  : 'N/A',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text('${jugador.goles}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ),
          SizedBox(
            width: 50,
            child: Text('${jugador.asistencias}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: AppColors.success, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}…' : s;

  TextStyle _headerStyle() => GoogleFonts.inter(
      color: AppColors.bgDark,
      fontSize: 11,
      letterSpacing: 1,
      fontWeight: FontWeight.w700);

  TextStyle _cellStyle() =>
      GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13);
}
