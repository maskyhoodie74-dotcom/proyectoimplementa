import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../jugadores/jugadores_provider.dart';
import '../../core/theme.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});
  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _progressAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    Future.microtask(() async {
      await context.read<JugadoresProvider>().fetchJugadores();
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jugadores = context.watch<JugadoresProvider>();
    final top = jugadores.topGoleadores;
    final topAsist = ([...jugadores.jugadores]
          ..sort((a, b) => b.asistencias.compareTo(a.asistencias)))
        .take(5)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A0610), Color(0xFF000000)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                  child: const Icon(CupertinoIcons.flame_fill,
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
                      'Rendimiento de jugadores',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: jugadores.loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold))
                : RefreshIndicator(
                    color: AppColors.gold,
                    backgroundColor: AppColors.bgCard,
                    onRefresh: () async {
                      _animCtrl.reset();
                      await context
                          .read<JugadoresProvider>()
                          .fetchJugadores();
                      _animCtrl.forward();
                    },
                    child: LayoutBuilder(builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 800;
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth:
                                  isDesktop ? 900.0 : double.infinity),
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                                isDesktop ? 28 : 16,
                                16,
                                isDesktop ? 28 : 16,
                                100),
                            physics: const BouncingScrollPhysics(
                                parent:
                                    AlwaysScrollableScrollPhysics()),
                            children: [
                              _buildSectionTitle(
                                  '🏆 TOP GOLEADORES',
                                  CupertinoIcons.sportscourt_fill),
                              const SizedBox(height: 12),
                              if (top.isEmpty)
                                _buildEmptyState()
                              else
                                ...top.asMap().entries.map((e) {
                                  final j = e.value;
                                  final pos = e.key + 1;
                                  final maxGoles =
                                      top.first.goles > 0
                                          ? top.first.goles
                                          : 1;
                                  return _buildGoleadorCard(
                                      j, pos, maxGoles);
                                }),
                              const SizedBox(height: 28),
                              _buildSectionTitle(
                                  '🎯 TOP ASISTIDORES',
                                  CupertinoIcons.arrow_right_arrow_left),
                              const SizedBox(height: 12),
                              if (topAsist.isEmpty)
                                _buildEmptyState()
                              else
                                ...topAsist.asMap().entries.map((e) {
                                  final j = e.value;
                                  final pos = e.key + 1;
                                  final maxAsist =
                                      topAsist.first.asistencias > 0
                                          ? topAsist.first.asistencias
                                          : 1;
                                  return _buildAsistidorCard(
                                      j, pos, maxAsist);
                                }),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: AppColors.maroonGradient,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.gold.withOpacity(0.3), width: 0.5),
          ),
          child: Icon(icon, color: AppColors.gold, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGoleadorCard(dynamic j, int pos, int maxGoles) {
    final isFirst = pos == 1;
    final isTop3 = pos <= 3;

    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: isFirst
                ? const LinearGradient(
                    colors: [Color(0xFF2D1A08), Color(0xFF1C1C1E)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: isFirst ? null : AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFirst
                  ? AppColors.gold.withOpacity(0.4)
                  : AppColors.divider,
              width: isFirst ? 1 : 0.5,
            ),
            boxShadow: isFirst ? AppColors.goldGlowSubtle : AppColors.cardShadow,
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isTop3 ? AppColors.maroonDark : AppColors.bgCardLight,
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
                    pos == 1
                        ? '🥇'
                        : pos == 2
                            ? '🥈'
                            : pos == 3
                                ? '🥉'
                                : '$pos',
                    style: TextStyle(
                      fontSize: isTop3 ? 18 : 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Player info + bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            j.nombre,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${j.goles}',
                              style: GoogleFonts.inter(
                                color: isFirst
                                    ? AppColors.gold
                                    : AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'goles',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      j.equipoNombre ?? 'Sin equipo',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    // Animated progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _progressAnim.value * (j.goles / maxGoles),
                        backgroundColor: AppColors.bgCardLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isFirst ? AppColors.gold : AppColors.maroonAccent,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAsistidorCard(dynamic j, int pos, int maxAsist) {
    final isFirst = pos == 1;

    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFirst
                  ? AppColors.success.withOpacity(0.3)
                  : AppColors.divider,
              width: 0.5,
            ),
            boxShadow: AppColors.cardShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                pos == 1
                    ? '🎯'
                    : pos == 2
                        ? '🥈'
                        : pos == 3
                            ? '🥉'
                            : ' $pos',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      j.nombre,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      j.equipoNombre ?? 'Sin equipo',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _progressAnim.value *
                            (j.asistencias / maxAsist),
                        backgroundColor: AppColors.bgCardLight,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.success),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${j.asistencias}',
                    style: GoogleFonts.inter(
                      color: AppColors.success,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'asist.',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(CupertinoIcons.chart_bar,
                color: AppColors.textTertiary, size: 40),
            const SizedBox(height: 12),
            Text(
              'AÚN NO HAY DATOS',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
