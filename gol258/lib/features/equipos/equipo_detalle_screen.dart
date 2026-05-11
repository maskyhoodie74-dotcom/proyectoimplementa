import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/equipo.dart';
import '../../models/jugador.dart';
import '../../models/partido.dart';
import '../jugadores/jugadores_provider.dart';
import '../partidos/partidos_provider.dart';

class EquipoDetalleScreen extends StatefulWidget {
  final Equipo equipo;
  const EquipoDetalleScreen({super.key, required this.equipo});

  @override
  State<EquipoDetalleScreen> createState() => _EquipoDetalleScreenState();
}

class _EquipoDetalleScreenState extends State<EquipoDetalleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Jugador> _jugadores = [];
  bool _loadingJugadores = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loadingJugadores = true);
    final prov = context.read<JugadoresProvider>();
    final jugadores = await prov.fetchJugadoresPorEquipo(widget.equipo.id);
    // Ensure partidos are loaded
    final partidosProv = context.read<PartidosProvider>();
    if (partidosProv.partidos.isEmpty) {
      await partidosProv.fetchPartidos();
    }
    if (mounted) {
      setState(() {
        _jugadores = jugadores;
        _loadingJugadores = false;
      });
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eq = widget.equipo;
    final partidos = context.watch<PartidosProvider>().partidos;
    final partidosEquipo = partidos
        .where((p) =>
            p.equipoLocalId == eq.id || p.equipoVisitanteId == eq.id)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.maroonDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A0E1A), Color(0xFF000000)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Escudo / inicial
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.maroonGradient,
                          border: Border.all(
                              color: AppColors.gold.withOpacity(0.6),
                              width: 2),
                          boxShadow: AppColors.goldGlowSubtle,
                        ),
                        child: eq.escudoUrl != null
                            ? ClipOval(
                                child: Image.network(eq.escudoUrl!,
                                    fit: BoxFit.cover))
                            : Center(
                                child: Text(
                                  eq.nombre.isNotEmpty
                                      ? eq.nombre[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.inter(
                                    color: AppColors.gold,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                      ShaderMask(
                        shaderCallback: (b) =>
                            AppColors.goldGradient.createShader(b),
                        child: Text(
                          eq.nombre.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (eq.categoria != null)
                            _badge(eq.categoria!),
                          if (eq.entrenador != null) ...[
                            const SizedBox(width: 8),
                            _badge('DT: ${eq.entrenador!}',
                                icon: CupertinoIcons.person),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: AppColors.gold,
              labelColor: AppColors.gold,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1),
              tabs: const [
                Tab(text: 'PLANTILLA'),
                Tab(text: 'PARTIDOS'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _buildPlantilla(),
            _buildPartidos(partidosEquipo),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.textSecondary, size: 11),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ─── Plantilla ──────────────────────────────────────────────────────────────

  Widget _buildPlantilla() {
    if (_loadingJugadores) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.gold));
    }
    if (_jugadores.isEmpty) {
      return _emptyState('Sin jugadores registrados', '👥');
    }

    // Ordenar por goles desc
    final sorted = [..._jugadores]
      ..sort((a, b) => b.goles.compareTo(a.goles));

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.gold,
      backgroundColor: AppColors.bgCard,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _jugadorTile(sorted[i], i + 1),
      ),
    );
  }

  Widget _jugadorTile(Jugador j, int rank) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank == 1 && j.goles > 0
              ? AppColors.gold.withOpacity(0.4)
              : AppColors.divider,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: rank == 1 && j.goles > 0
                    ? AppColors.goldGradient
                    : AppColors.maroonGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '#${j.numero}',
                  style: GoogleFonts.inter(
                    color: rank == 1 && j.goles > 0
                        ? AppColors.bgDark
                        : AppColors.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          j.nombre,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          j.posicion ?? 'Sin posición',
          style: GoogleFonts.inter(
              color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statChip('⚽', j.goles.toString(), AppColors.gold),
            const SizedBox(width: 8),
            _statChip(
                '🏃', j.partidos.toString(), AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Partidos del equipo ─────────────────────────────────────────────────────

  Widget _buildPartidos(List<Partido> lista) {
    if (lista.isEmpty) {
      return _emptyState('Sin partidos registrados', '📅');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: lista.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _partidoTile(lista[i]),
    );
  }

  Widget _partidoTile(Partido p) {
    final esLocal = p.equipoLocalId == widget.equipo.id;
    final rival = esLocal
        ? (p.equipoVisitanteNombre ?? 'Visitante')
        : (p.equipoLocalNombre ?? 'Local');
    final condicion = esLocal ? 'Local' : 'Visitante';

    Color resultColor = AppColors.textSecondary;
    String resultLabel = 'Pendiente';

    if (p.jugado) {
      final gF = esLocal ? (p.golesLocal ?? 0) : (p.golesVisitante ?? 0);
      final gC = esLocal ? (p.golesVisitante ?? 0) : (p.golesLocal ?? 0);
      if (gF > gC) {
        resultColor = AppColors.success;
        resultLabel = 'Victoria';
      } else if (gF < gC) {
        resultColor = AppColors.error;
        resultLabel = 'Derrota';
      } else {
        resultColor = AppColors.warning;
        resultLabel = 'Empate';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: resultColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: resultColor.withOpacity(0.4)),
          ),
          child: Center(
            child: Text(
              p.jugado ? p.marcador : 'vs',
              style: GoogleFonts.inter(
                color: resultColor,
                fontSize: p.jugado ? 11 : 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        title: Text(
          'vs $rival',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          '${_formatFecha(p.fecha)} · $condicion${p.lugar != null ? " · ${p.lugar}" : ""}',
          style: GoogleFonts.inter(
              color: AppColors.textSecondary, fontSize: 11),
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: resultColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            resultLabel,
            style: GoogleFonts.inter(
              color: resultColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  String _formatFecha(DateTime f) {
    const meses = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${f.day} ${meses[f.month]} ${f.year}';
  }

  Widget _emptyState(String msg, String emoji) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            msg,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
