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
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                if (partido.categoria != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.maroonDark,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(partido.categoria!,
                        style: GoogleFonts.inter(color: AppColors.gold, fontSize: 10)),
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
                            Text(partido.marcador,
                                style: GoogleFonts.oswald(
                                    color: AppColors.gold,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700)),
                            Text('FINAL',
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary, fontSize: 9, letterSpacing: 1.5)),
                          ],
                        )
                      : Text('VS',
                          style: GoogleFonts.oswald(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
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
                    Text('DETALLES DEL PARTIDO',
                        style: GoogleFonts.inter(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _teamSide(String nombre, String? escudo,
      {bool isRight = false, bool isWinner = false}) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppColors.maroonDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isWinner ? AppColors.gold : AppColors.divider,
              width: isWinner ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: escudo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(escudo, width: 40, height: 40, fit: BoxFit.cover))
                : Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                    style: GoogleFonts.oswald(
                        color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 6),
        Text(nombre,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.oswald(
                color: isWinner ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isWinner ? FontWeight.w700 : FontWeight.w400)),
      ],
    );
    return content;
  }
}
