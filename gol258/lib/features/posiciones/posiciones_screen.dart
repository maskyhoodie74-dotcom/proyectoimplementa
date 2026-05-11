import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
      backgroundColor: AppColors.bgDark,
      body: Column(
        children: [
          // Premium header with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A0610), Color(0xFF000000)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppColors.maroonGradient,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.gold.withOpacity(0.3), width: 0.5),
                        ),
                        child: const Icon(CupertinoIcons.chart_bar_fill,
                            color: AppColors.gold, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                AppColors.goldGradient.createShader(bounds),
                            child: Text(
                              'ESTADÍSTICAS',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          Text(
                            'Temporada 2025',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // iOS-style tab bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: AppColors.maroonGradient,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: AppColors.gold.withOpacity(0.3), width: 0.5),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.gold,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                    unselectedLabelStyle: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: 'POSICIONES'),
                      Tab(text: 'GOLEADORES'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPosicionesTab(partidos, equiposP),
                _buildGoleadoresTab(jugadoresP),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── POSICIONES ───────────────
  Widget _buildPosicionesTab(PartidosProvider partidos, EquiposProvider equiposP) {
    final tablaConTendencia = partidos.obtenerTablaConTendencia(equiposP.equipos);

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.bgCard,
      onRefresh: () async {
        await context.read<PartidosProvider>().fetchPartidos();
        await context.read<EquiposProvider>().fetchEquipos();
      },
      child: LayoutBuilder(builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 900.0 : double.infinity),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.all(isDesktop ? 28 : 16),
              child: Column(
                children: [
                  _buildStandingsHeader(),
                  const SizedBox(height: 4),
                  if (partidos.loading || equiposP.loading)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(color: AppColors.gold),
                    )
                  else if (tablaConTendencia.isEmpty)
                    _buildEmptyState('Aún no hay equipos registrados.')
                  else
                    ...tablaConTendencia.asMap().entries.map((e) {
                      final pos = e.key + 1;
                      final entry = e.value;
                      return _buildStandingsRow(
                          pos, entry['nombre'], entry['stats'], entry['tendencia']);
                    }),
                  const SizedBox(height: 16),
                  _buildLegend(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStandingsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text('#', style: _hStyle())),
          Expanded(child: Text('EQUIPO', style: _hStyle())),
          SizedBox(width: 30, child: Text('PJ', textAlign: TextAlign.center, style: _hStyle())),
          SizedBox(width: 30, child: Text('PG', textAlign: TextAlign.center, style: _hStyle())),
          SizedBox(width: 30, child: Text('PE', textAlign: TextAlign.center, style: _hStyle())),
          SizedBox(width: 30, child: Text('PP', textAlign: TextAlign.center, style: _hStyle())),
          SizedBox(width: 30, child: Text('GD', textAlign: TextAlign.center, style: _hStyle())),
          SizedBox(width: 38, child: Text('PTS', textAlign: TextAlign.center, style: _hStyle())),
        ],
      ),
    );
  }

  Widget _buildStandingsRow(int pos, String nombre, Map<String, dynamic> stats, int tendencia) {
    final gd = (stats['GF'] ?? 0) - (stats['GC'] ?? 0);
    final isTop3 = pos <= 3;
    final isFirst = pos == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isFirst
            ? const LinearGradient(
                colors: [Color(0xFF2D1A08), Color(0xFF1C1C1E)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isFirst ? null : (isTop3 ? AppColors.bgCard : AppColors.bgDark),
        borderRadius: pos == 1
            ? BorderRadius.zero
            : (pos == (pos) ? BorderRadius.zero : BorderRadius.zero),
        border: Border(
          left: isFirst
              ? const BorderSide(color: AppColors.gold, width: 3)
              : BorderSide(
                  color: isTop3
                      ? AppColors.maroon.withOpacity(0.5)
                      : Colors.transparent,
                  width: 3,
                ),
          bottom: BorderSide(color: AppColors.divider.withOpacity(0.3), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                pos == 1
                    ? const Text('🥇', style: TextStyle(fontSize: 18))
                    : pos == 2
                        ? const Text('🥈', style: TextStyle(fontSize: 18))
                        : pos == 3
                            ? const Text('🥉', style: TextStyle(fontSize: 18))
                            : Text(
                                '$pos',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                const SizedBox(height: 2),
                _buildTrendIcon(tendencia),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: isFirst ? AppColors.maroonGradient : null,
                    color: isFirst ? null : AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFirst
                          ? AppColors.gold.withOpacity(0.5)
                          : AppColors.divider,
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(
                        color: isFirst ? AppColors.gold : AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nombre,
                    style: GoogleFonts.inter(
                      color: isFirst ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 30, child: Text('${stats['PJ'] ?? 0}', textAlign: TextAlign.center, style: _cStyle())),
          SizedBox(width: 30, child: Text('${stats['PG'] ?? 0}', textAlign: TextAlign.center, style: _cStyle())),
          SizedBox(width: 30, child: Text('${stats['PE'] ?? 0}', textAlign: TextAlign.center, style: _cStyle())),
          SizedBox(width: 30, child: Text('${stats['PP'] ?? 0}', textAlign: TextAlign.center, style: _cStyle())),
          SizedBox(
            width: 30,
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '${stats['Pts'] ?? 0}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isFirst ? AppColors.gold : AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIcon(int tendencia) {
    if (tendencia == 0) {
      return Icon(CupertinoIcons.minus, color: AppColors.textTertiary, size: 10);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          tendencia > 0 ? CupertinoIcons.arrow_up : CupertinoIcons.arrow_down,
          color: tendencia > 0 ? AppColors.success : AppColors.error,
          size: 10,
        ),
        Text(
          '${tendencia.abs()}',
          style: GoogleFonts.inter(
            color: tendencia > 0 ? AppColors.success : AppColors.error,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(CupertinoIcons.info_circle, color: AppColors.gold, size: 14),
            const SizedBox(width: 6),
            Text('LEYENDA',
                style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 6,
            children: [
              _legendItem('PJ', 'Partidos Jugados'),
              _legendItem('PG', 'Ganados'),
              _legendItem('PE', 'Empatados'),
              _legendItem('PP', 'Perdidos'),
              _legendItem('GD', 'Diferencia Goles'),
              _legendItem('PTS', 'G=3, E=1, P=0'),
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
                color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700)),
        Text(' = $full',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(CupertinoIcons.sportscourt,
              color: AppColors.textTertiary, size: 48),
          const SizedBox(height: 16),
          Text(msg,
              style:
                  GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  // ─────────────── GOLEADORES ───────────────
  Widget _buildGoleadoresTab(JugadoresProvider jugadoresP) {
    final goleadores = jugadoresP.topGoleadores;

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.bgCard,
      onRefresh: () => context.read<JugadoresProvider>().fetchJugadores(),
      child: LayoutBuilder(builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        return Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isDesktop ? 900.0 : double.infinity),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.all(isDesktop ? 28 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGoleadoresHeader(),
                  const SizedBox(height: 4),
                  if (jugadoresP.loading)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(color: AppColors.gold),
                    )
                  else if (goleadores.isEmpty)
                    _buildEmptyState('Aún no hay goles registrados.')
                  else
                    ...goleadores.asMap().entries.map((e) =>
                        _buildGoleadorRow(e.key + 1, e.value)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGoleadoresHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          SizedBox(width: 42, child: Text('#', style: _hStyle())),
          Expanded(child: Text('JUGADOR', style: _hStyle())),
          SizedBox(width: 70, child: Text('EQUIPO', textAlign: TextAlign.center, style: _hStyle())),
          SizedBox(width: 52, child: Text('GOLES', textAlign: TextAlign.center, style: _hStyle())),
          SizedBox(width: 52, child: Text('ASIST.', textAlign: TextAlign.center, style: _hStyle())),
        ],
      ),
    );
  }

  Widget _buildGoleadorRow(int pos, dynamic jugador) {
    final isTop3 = pos <= 3;
    final isFirst = pos == 1;
    final maxGoles = jugador.goles > 0 ? jugador.goles : 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isTop3 ? AppColors.bgCard : AppColors.bgDark,
        border: Border(
          left: isFirst
              ? const BorderSide(color: AppColors.gold, width: 3)
              : BorderSide(
                  color: isTop3 ? AppColors.maroon.withOpacity(0.5) : Colors.transparent,
                  width: 3,
                ),
          bottom: BorderSide(color: AppColors.divider.withOpacity(0.3), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: pos == 1
                ? const Text('🥇', style: TextStyle(fontSize: 18))
                : pos == 2
                    ? const Text('🥈', style: TextStyle(fontSize: 18))
                    : pos == 3
                        ? const Text('🥉', style: TextStyle(fontSize: 18))
                        : Text(
                            '$pos',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: isFirst ? AppColors.maroonGradient : null,
                    color: isFirst ? null : AppColors.bgCardLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFirst
                          ? AppColors.gold.withOpacity(0.5)
                          : AppColors.divider,
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '#${jugador.numero}',
                      style: GoogleFonts.inter(
                        color: isFirst ? AppColors.gold : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jugador.nombre,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        jugador.posicion ?? 'Jugador',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              jugador.equipoNombre != null
                  ? _truncate(jugador.equipoNombre!, 8)
                  : 'N/A',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '${jugador.goles}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isFirst ? AppColors.gold : AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '${jugador.asistencias}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppColors.success, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}…' : s;

  TextStyle _hStyle() => GoogleFonts.inter(
      color: AppColors.bgDark,
      fontSize: 11,
      letterSpacing: 1,
      fontWeight: FontWeight.w800);

  TextStyle _cStyle() =>
      GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13);
}
