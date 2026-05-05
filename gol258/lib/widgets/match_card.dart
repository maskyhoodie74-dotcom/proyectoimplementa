import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/partido.dart';

class MatchCard extends StatelessWidget {
  final Partido partido;
  final bool showScore;
  final bool showDetails;

  const MatchCard({
    super.key,
    required this.partido,
    this.showScore = false,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCardLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          splashColor: AppColors.maroon.withOpacity(0.3),
          highlightColor: AppColors.gold.withOpacity(0.1),
          onTap: () {
            // Future feature: navigate to match details
          },
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider.withOpacity(0.5), width: 0.5)),
                ),
                child: Row(
                  children: [
                    if (partido.categoria != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: AppColors.maroonGradient,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                        ),
                        child: Text(partido.categoria!.toUpperCase(),
                            style: GoogleFonts.inter(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '${partido.hora}',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const Spacer(),
                    Icon(
                      showScore ? Icons.check_circle_outline : Icons.calendar_today_outlined,
                      color: showScore ? AppColors.success : AppColors.textSecondary,
                      size: 14,
                    ),
                  ],
                ),
              ),
              // Teams
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: _teamSide(
                      partido.equipoLocalNombre ?? 'Local',
                      partido.equipoLocalEscudo,
                      isWinner: showScore && (partido.golesLocal ?? 0) > (partido.golesVisitante ?? 0),
                    )),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: showScore
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgDark.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                                    boxShadow: AppColors.goldGlow,
                                  ),
                                  child: Text(partido.marcador,
                                      style: GoogleFonts.inter(
                                          color: AppColors.gold,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 2)),
                                ),
                                const SizedBox(height: 4),
                                Text('FINALIZADO',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                              ],
                            )
                          : Text('VS',
                              style: GoogleFonts.inter(
                                  color: AppColors.gold.withOpacity(0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                    ),
                    Expanded(child: _teamSide(
                      partido.equipoVisitanteNombre ?? 'Visitante',
                      partido.equipoVisitanteEscudo,
                      isRight: true,
                      isWinner: showScore && (partido.golesVisitante ?? 0) > (partido.golesLocal ?? 0),
                    )),
                  ],
                ),
              ),
              // Location
              if (partido.lugar != null)
                Padding(
                  padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.textSecondary, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(partido.lugar!,
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 11)),
                      ),
                      if (showDetails)
                        Text('VER DETALLES',
                            style: GoogleFonts.inter(
                                color: AppColors.gold,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamSide(String nombre, String? escudo,
      {bool isRight = false, bool isWinner = false}) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AppColors.bgDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isWinner ? AppColors.gold : AppColors.divider.withOpacity(0.5),
              width: isWinner ? 1.5 : 0.5,
            ),
            boxShadow: isWinner ? AppColors.goldGlow : null,
          ),
          child: Center(
            child: escudo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.network(escudo, width: 44, height: 44, fit: BoxFit.cover))
                : Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                        color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 6),
        Text(nombre,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
                color: isWinner ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isWinner ? FontWeight.w700 : FontWeight.w400)),
      ],
    );
    return content;
  }
}
