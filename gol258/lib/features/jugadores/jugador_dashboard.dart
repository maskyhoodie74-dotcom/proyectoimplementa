import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../partidos/partidos_provider.dart';
import '../jugadores/jugadores_provider.dart';
import '../equipos/equipos_provider.dart';
import '../../core/theme.dart';
import 'package:flutter/services.dart';
import '../ia/ia_chat_screen.dart';

class JugadorDashboard extends StatefulWidget {
  const JugadorDashboard({super.key});

  @override
  State<JugadorDashboard> createState() => _JugadorDashboardState();
}

class _JugadorDashboardState extends State<JugadorDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final auth = context.watch<AuthProvider>();
    final jugadoresP = context.watch<JugadoresProvider>();
    final partidos = context.watch<PartidosProvider>();
    final equiposP = context.watch<EquiposProvider>();

    // Find this player's data
    final miJugador = auth.jugadorId != null
        ? jugadoresP.jugadores.where((j) => j.id == auth.jugadorId).firstOrNull
        : null;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      floatingActionButton: _buildIaFab(context),
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.gold, size: 20),
          onPressed: () => context.go('/home'),
        ),
        title: Row(children: [
          Image.asset(
            'assets/images/logo_no_bg.png',
            width: 32, height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Text('MI PERFIL',
              style: GoogleFonts.inter(
                  color: AppColors.gold, fontSize: 20, letterSpacing: 2)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: AppColors.error),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go('/');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          indicatorWeight: 2,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
          tabs: const [
            Tab(text: 'MI PERFIL'),
            Tab(text: 'POSICIONES'),
            Tab(text: 'GOLEADORES'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPerfilTab(auth, miJugador, partidos, equiposP),
          _buildPosicionesTab(partidos, equiposP),
          _buildGoleadoresTab(jugadoresP),
        ],
      ),
    );
  }

  Widget _buildPerfilTab(AuthProvider auth, dynamic miJugador,
      PartidosProvider partidos, EquiposProvider equiposP) {
    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.bgCard,
      onRefresh: () async {
        await context.read<PartidosProvider>().fetchPartidos();
        await context.read<JugadoresProvider>().fetchJugadores();
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player Card
            _buildPlayerHeroCard(auth, miJugador, equiposP),
            const SizedBox(height: 20),
            // Stats
            if (miJugador != null) ...[
              _buildSectionTitle('MIS ESTADÍSTICAS'),
              const SizedBox(height: 12),
              _buildStatsGrid(miJugador),
              const SizedBox(height: 20),
            ],
            // Próximos partidos de su equipo
            _buildSectionTitle('PRÓXIMOS PARTIDOS'),
            const SizedBox(height: 12),
            if (auth.equipoId != null)
              _buildProximosPartidos(partidos, auth.equipoId!)
            else
              _buildInfoBox('No estás asignado a ningún equipo aún.'),
            const SizedBox(height: 20),
            // Últimos resultados del equipo
            _buildSectionTitle('ÚLTIMOS RESULTADOS'),
            const SizedBox(height: 12),
            if (auth.equipoId != null)
              _buildResultadosEquipo(partidos, auth.equipoId!)
            else
              _buildInfoBox('Sin resultados disponibles.'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerHeroCard(AuthProvider auth, dynamic jugador, EquiposProvider equiposP) {
    final equipoNombre = jugador?.equipoNombre ??
        (auth.equipoId != null
            ? equiposP.equipos.where((e) => e.id == auth.equipoId).firstOrNull?.nombre
            : null) ??
        'Sin equipo';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.maroonDark, AppColors.maroon],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold.withOpacity(0.4)),
            boxShadow: AppColors.goldGlow,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.bgDark,
                  border: Border.all(color: AppColors.gold, width: 3),
                  boxShadow: AppColors.goldGlow,
                ),
                child: Center(
                  child: jugador != null
                      ? Text(
                          '#${jugador.numero}',
                          style: GoogleFonts.inter(
                              color: AppColors.gold,
                              fontSize: 24,
                              fontWeight: FontWeight.w900),
                        )
                      : const Icon(Icons.person, color: AppColors.gold, size: 40),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                jugador?.nombre ?? auth.userName,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  equipoNombre.toUpperCase(),
                  style: GoogleFonts.inter(
                      color: AppColors.bgDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5),
                ),
              ),
              if (jugador?.posicion != null) ...[
                const SizedBox(height: 8),
                Text(
                  jugador!.posicion!.toUpperCase(),
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      letterSpacing: 2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(dynamic jugador) {
    return Row(
      children: [
        _buildStatCard('⚽', '${jugador.goles}', 'Goles', AppColors.gold),
        const SizedBox(width: 12),
        _buildStatCard('🎯', '${jugador.asistencias}', 'Asistencias', AppColors.success),
        const SizedBox(width: 12),
        _buildStatCard('📋', '${jugador.partidos}', 'Partidos', AppColors.textSecondary),
      ],
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.inter(
                    color: color, fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildProximosPartidos(PartidosProvider partidos, String equipoId) {
    final proximos = partidos.proximosPartidosDeEquipo(equipoId);
    if (partidos.loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(color: AppColors.gold),
      ));
    }
    if (proximos.isEmpty) {
      return _buildInfoBox('No hay partidos próximos programados para tu equipo.');
    }
    return Column(
      children: proximos.take(3).map((p) => _buildPartidoCard(p, false)).toList(),
    );
  }

  Widget _buildResultadosEquipo(PartidosProvider partidos, String equipoId) {
    final resultados = partidos.resultados
        .where((p) => p.equipoLocalId == equipoId || p.equipoVisitanteId == equipoId)
        .take(3)
        .toList();
    if (resultados.isEmpty) return _buildInfoBox('Tu equipo aún no tiene resultados registrados.');
    return Column(
      children: resultados.map((p) => _buildPartidoCard(p, true)).toList(),
    );
  }

  Widget _buildPartidoCard(dynamic partido, bool showScore) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  partido.equipoLocalNombre ?? 'Local',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: showScore ? AppColors.maroonDark : AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: showScore ? AppColors.gold.withOpacity(0.5) : AppColors.divider),
                ),
                child: Text(
                  showScore
                      ? '${partido.golesLocal ?? 0} - ${partido.golesVisitante ?? 0}'
                      : 'VS',
                  style: GoogleFonts.inter(
                      color: showScore ? AppColors.gold : AppColors.textSecondary,
                      fontSize: showScore ? 18 : 13,
                      fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(
                child: Text(
                  partido.equipoVisitanteNombre ?? 'Visitante',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatDate(partido.fecha)}${partido.lugar != null ? " • ${partido.lugar}" : ""}',
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPosicionesTab(PartidosProvider partidos, EquiposProvider equiposP) {
    final tablaConTendencia = partidos.obtenerTablaConTendencia(equiposP.equipos);

    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.bgCard,
      onRefresh: () async {
        await context.read<PartidosProvider>().fetchPartidos();
        await context.read<EquiposProvider>().fetchEquipos();
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('TABLA DE POSICIONES'),
            const SizedBox(height: 12),
            _buildTablaHeader(),
            const SizedBox(height: 4),
            if (partidos.loading || equiposP.loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.gold),
              ))
            else if (tablaConTendencia.isEmpty)
              _buildInfoBox('No hay equipos registrados.')
            else
              ...tablaConTendencia.asMap().entries.map((e) {
                final pos = e.key + 1;
                final entry = e.value;
                return _buildTablaRow(pos, entry['nombre'], entry['stats'], entry['tendencia']);
              }),
            const SizedBox(height: 16),
            _buildTablaLeyenda(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: _headerStyle())),
          Expanded(child: Text('EQUIPO', style: _headerStyle())),
          SizedBox(width: 30, child: Text('PJ', textAlign: TextAlign.center, style: _headerStyle())),
          SizedBox(width: 30, child: Text('PG', textAlign: TextAlign.center, style: _headerStyle())),
          SizedBox(width: 30, child: Text('PE', textAlign: TextAlign.center, style: _headerStyle())),
          SizedBox(width: 30, child: Text('PP', textAlign: TextAlign.center, style: _headerStyle())),
          SizedBox(width: 30, child: Text('GD', textAlign: TextAlign.center, style: _headerStyle())),
          SizedBox(width: 36, child: Text('PTS', textAlign: TextAlign.center, style: _headerStyle())),
        ],
      ),
    );
  }

  Widget _buildTablaRow(int pos, String nombre, Map<String, dynamic> stats, int tendencia) {
    final gd = (stats['GF'] ?? 0) - (stats['GC'] ?? 0);
    final isTop3 = pos <= 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
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
            width: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                pos == 1
                    ? const Text('🥇', style: TextStyle(fontSize: 14))
                    : pos == 2
                        ? const Text('🥈', style: TextStyle(fontSize: 14))
                        : pos == 3
                            ? const Text('🥉', style: TextStyle(fontSize: 14))
                            : Text('$pos',
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(nombre,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(width: 30, child: Text('${stats['PJ'] ?? 0}', textAlign: TextAlign.center, style: _cellStyle())),
          SizedBox(width: 30, child: Text('${stats['PG'] ?? 0}', textAlign: TextAlign.center, style: _cellStyle())),
          SizedBox(width: 30, child: Text('${stats['PE'] ?? 0}', textAlign: TextAlign.center, style: _cellStyle())),
          SizedBox(width: 30, child: Text('${stats['PP'] ?? 0}', textAlign: TextAlign.center, style: _cellStyle())),
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
                  fontSize: 12),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text('${stats['Pts'] ?? 0}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: AppColors.gold, fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaLeyenda() {
    return Container(
      padding: const EdgeInsets.all(12),
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
                  color: AppColors.gold, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _legendItem('PJ', 'Partidos Jugados'),
          _legendItem('PG', 'Partidos Ganados'),
          _legendItem('PE', 'Partidos Empatados'),
          _legendItem('PP', 'Partidos Perdidos'),
          _legendItem('GD', 'Diferencia de Goles'),
          _legendItem('PTS', 'Puntos'),
        ],
      ),
    );
  }

  Widget _legendItem(String abbr, String full) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 40,
              child: Text(abbr,
                  style: GoogleFonts.inter(
                      color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600))),
          Text(full,
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildGoleadoresTab(JugadoresProvider jugadoresP) {
    final goleadores = jugadoresP.topGoleadores;
    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.bgCard,
      onRefresh: () => context.read<JugadoresProvider>().fetchJugadores(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('TABLA DE GOLEADORES'),
            const SizedBox(height: 12),
            if (jugadoresP.loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppColors.gold),
              ))
            else if (goleadores.isEmpty)
              _buildInfoBox('Aún no hay goles registrados.')
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
    );
  }

  Widget _buildGoleadorRow(int pos, dynamic jugador) {
    final isTop3 = pos <= 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isTop3 ? AppColors.maroonDeep : AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pos == 1 ? AppColors.gold.withOpacity(0.5) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: pos == 1
                ? const Text('🥇', style: TextStyle(fontSize: 18))
                : pos == 2
                    ? const Text('🥈', style: TextStyle(fontSize: 18))
                    : pos == 3
                        ? const Text('🥉', style: TextStyle(fontSize: 18))
                        : Text('$pos',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 14)),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.maroonDark,
              border: Border.all(color: AppColors.gold.withOpacity(0.4)),
            ),
            child: Center(
              child: Text('#${jugador.numero}',
                  style: GoogleFonts.inter(
                      color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(jugador.nombre,
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(
                  '${jugador.equipoNombre ?? "Sin equipo"} • ${jugador.posicion ?? "Jugador"}',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                const Text('⚽', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text('${jugador.goles}',
                    style: GoogleFonts.inter(
                        color: AppColors.gold,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ]),
              Text('goles',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(children: [
      Container(width: 3, height: 20, color: AppColors.gold,
          margin: const EdgeInsets.only(right: 10)),
      Text(title,
          style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5)),
    ]);
  }

  Widget _buildInfoBox(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Text(message,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} • $h:$m';
  }

  TextStyle _headerStyle() => GoogleFonts.inter(
      color: AppColors.bgDark, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w700);

  TextStyle _cellStyle() =>
      GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12);

  Widget _buildIaFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => const IaChatScreen(),
            transitionsBuilder: (_, anim, __, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: anim,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          ),
        );
      },
      backgroundColor: Colors.transparent,
      elevation: 0,
      label: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppColors.maroonGradient,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.5),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.maroon.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🤖', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'Asistente IA',
              style: GoogleFonts.inter(
                color: AppColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
