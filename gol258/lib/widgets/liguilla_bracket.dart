import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/liguilla_torneo.dart';

// ═══════════════════════════════════════════════════════════
// BRACKET WIDGET (REFACTORIZADO)
// Depende exclusivamente de los modelos de Liguilla (no de liga)
// ═══════════════════════════════════════════════════════════

class LiguillaBracketWidget extends StatelessWidget {
  /// Todos los partidos de la liguilla, agendados y por jugar
  final List<LiguillaPartido> partidos;
  final LiguillaTorneo torneo;

  const LiguillaBracketWidget({
    super.key,
    required this.partidos,
    required this.torneo,
  });

  @override
  Widget build(BuildContext context) {
    if (partidos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.sportscourt,
                  color: AppColors.textTertiary, size: 48),
              const SizedBox(height: 16),
              Text(
                'El torneo ${torneo.nombre} aún no tiene\npartidos generados en el bracket.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Clasificar partidos por ronda
    final List<List<LiguillaPartido>> rounds = [];
    final rondasNombres = ['OCTAVOS', 'CUARTOS', 'SEMIFINALES', 'FINAL'];
    
    for (final r in rondasNombres) {
      final partidosRonda = partidos.where((p) => p.ronda == r).toList();
      if (partidosRonda.isNotEmpty) {
        partidosRonda.sort((a, b) => a.numeroPartido.compareTo(b.numeroPartido));
        rounds.add(partidosRonda);
      }
    }

    // Si por alguna razón la BD regresó desordenado o algo faltó
    if (rounds.isEmpty) return const SizedBox();

    // Determinar el campeón
    final finalMatch = rounds.last.first;
    String? campeon;
    if (finalMatch.jugado) {
      if ((finalMatch.golesLocal ?? 0) > (finalMatch.golesVisitante ?? 0)) {
        campeon = finalMatch.equipoLocalNombre;
      } else if ((finalMatch.golesVisitante ?? 0) > (finalMatch.golesLocal ?? 0)) {
        campeon = finalMatch.equipoVisitanteNombre;
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 700;

      if (isWide) {
        return _buildHorizontalBracket(rounds, campeon);
      } else {
        return _buildVerticalBracket(rounds, campeon);
      }
    });
  }

  // ─────────────── HORIZONTAL (Desktop/Tablet) ───────────────
  Widget _buildHorizontalBracket(
      List<List<LiguillaPartido>> rounds, String? campeon) {
    final totalRounds = rounds.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (int r = 0; r < totalRounds; r++) ...[
            _buildRoundColumn(rounds[r], rounds[r].first.ronda, r, totalRounds),
            if (r < totalRounds - 1) _buildConnectors(rounds[r].length),
          ],
          if (campeon != null) ...[
            _buildConnectors(1),
            _buildTrophyCard(campeon),
          ],
        ],
      ),
    );
  }

  Widget _buildRoundColumn(
      List<LiguillaPartido> matches, String title, int roundIndex, int totalRounds) {
    // Incremento de espacio vertical entre nodos según se avanza en rondas
    final spacing = 16.0 + (roundIndex * 80.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Round title badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppColors.maroonGradient,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.5),
          ),
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.gold,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...matches
            .map((m) => Padding(
                  padding: EdgeInsets.symmetric(vertical: spacing / 2),
                  child: _MatchCard(match: m),
                )),
      ],
    );
  }

  Widget _buildConnectors(int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          count,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: 40,
              height: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.6),
                      AppColors.gold.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────── VERTICAL (Mobile) ───────────────
  Widget _buildVerticalBracket(
      List<List<LiguillaPartido>> rounds, String? campeon) {
    final totalRounds = rounds.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Banner de campeón si existe
          if (campeon != null) ...[
            _buildTrophyCard(campeon),
            const SizedBox(height: 8),
            _buildVerticalLine(),
            const SizedBox(height: 8),
          ],
          // Dibujar rondas de la Final hacia atrás para jerarquía visual (como árbol)
          for (int r = totalRounds - 1; r >= 0; r--) ...[
            _buildRoundHeader(rounds[r].first.ronda),
            const SizedBox(height: 10),
            ...rounds[r].map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MatchCard(match: m),
                )),
            if (r > 0) ...[
              _buildVerticalLine(),
              const SizedBox(height: 8),
            ],
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildRoundHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppColors.maroonGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.maroon.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.flag_fill, color: AppColors.gold, size: 14),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.gold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalLine() {
    return Container(
      width: 3,
      height: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.5),
            AppColors.gold.withValues(alpha: 0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTrophyCard(String campeon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D2A06), Color(0xFF1C1C1E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 1.5),
        boxShadow: AppColors.goldGlow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.goldGradient.createShader(bounds),
            child: Text(
              'CAMPEÓN',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            campeon,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MATCH CARD — Slot del bracket
// ═══════════════════════════════════════════════════════════

class _MatchCard extends StatelessWidget {
  final LiguillaPartido match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final isDecided = match.jugado;
    
    // Determinar ganador para los estilos visuales
    String? ganadorId;
    if (isDecided) {
      if ((match.golesLocal ?? 0) > (match.golesVisitante ?? 0)) {
        ganadorId = match.equipoLocalId;
      } else if ((match.golesVisitante ?? 0) > (match.golesLocal ?? 0)) {
        ganadorId = match.equipoVisitanteId;
      }
    }

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDecided
              ? AppColors.gold.withValues(alpha: 0.4)
              : AppColors.divider,
          width: isDecided ? 1 : 0.5,
        ),
        boxShadow: isDecided ? AppColors.goldGlowSubtle : AppColors.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isDecided
                  ? AppColors.gold.withValues(alpha: 0.12)
                  : AppColors.bgCardLight.withValues(alpha: 0.5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Text(
              isDecided
                  ? 'FINALIZADO'
                  : (match.equipoLocalId != null && match.equipoVisitanteId != null)
                      ? 'POR JUGAR'
                      : 'POR DEFINIR',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: isDecided ? AppColors.gold : AppColors.textTertiary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          // Team A
          _buildTeamRow(
            nombre: match.equipoLocalNombre,
            goles: match.golesLocal,
            isGanador: ganadorId != null && ganadorId == match.equipoLocalId,
            isPerdedor: ganadorId != null && ganadorId != match.equipoLocalId,
          ),
          // Divider
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: AppColors.divider.withValues(alpha: 0.5),
          ),
          // Team B
          _buildTeamRow(
            nombre: match.equipoVisitanteNombre,
            goles: match.golesVisitante,
            isGanador: ganadorId != null && ganadorId == match.equipoVisitanteId,
            isPerdedor: ganadorId != null && ganadorId != match.equipoVisitanteId,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow({
    String? nombre,
    int? goles,
    required bool isGanador,
    required bool isPerdedor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        gradient: isGanador
            ? const LinearGradient(
                colors: [Color(0xFF2D1A08), Colors.transparent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
      ),
      child: Row(
        children: [
          // Team avatar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: isGanador ? AppColors.maroonGradient : null,
              color: isGanador ? null : AppColors.bgCardLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isGanador
                    ? AppColors.gold.withValues(alpha: 0.4)
                    : AppColors.divider,
                width: 0.5,
              ),
            ),
            child: Center(
              child: Text(
                nombre != null && nombre.isNotEmpty
                    ? nombre[0].toUpperCase()
                    : '?',
                style: GoogleFonts.inter(
                  color: isGanador ? AppColors.gold : AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Team name
          Expanded(
            child: Text(
              nombre ?? 'Por definir',
              style: GoogleFonts.inter(
                color: nombre == null
                    ? AppColors.textTertiary
                    : isPerdedor
                        ? AppColors.textTertiary
                        : isGanador
                            ? AppColors.gold
                            : AppColors.textPrimary,
                fontSize: 12,
                fontWeight:
                    isGanador ? FontWeight.w800 : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Score
          if (goles != null)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isGanador
                    ? AppColors.gold.withValues(alpha: 0.15)
                    : AppColors.bgCardLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isGanador
                      ? AppColors.gold.withValues(alpha: 0.5)
                      : AppColors.divider,
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  '$goles',
                  style: GoogleFonts.inter(
                    color: isGanador ? AppColors.gold : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
          else if (nombre != null)
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.bgCardLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '-',
                  style: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
