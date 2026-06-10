import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/partido.dart';
import '../features/highlights/highlights_screen.dart';
import '../features/partidos/partido_detalle_screen.dart';


class MatchCard extends StatefulWidget {
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
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = widget.showScore;
    final localWins = isFinished &&
        (widget.partido.golesLocal ?? 0) > (widget.partido.golesVisitante ?? 0);
    final visWins = isFinished &&
        (widget.partido.golesVisitante ?? 0) > (widget.partido.golesLocal ?? 0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) => _pressCtrl.reverse(),
        onTapCancel: () => _pressCtrl.reverse(),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PartidoDetalleScreen(partido: widget.partido),
          ));
        },
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isHovered 
                      ? AppColors.gold.withOpacity(0.4) 
                      : (isFinished ? AppColors.gold.withOpacity(0.25) : AppColors.divider),
                  width: _isHovered ? 1.0 : 0.5,
                ),
                boxShadow: _isHovered ? AppColors.glassShadow : AppColors.cardShadow,
              ),
          child: Column(
            children: [
              // Top status bar
              _buildStatusBar(isFinished),
              // Teams + Score
              _buildMatchBody(localWins, visWins),
              // Bottom detail
              _buildBottomRow(),
            ],
          ),
        ),
      ),
    )));
  }

  Widget _buildStatusBar(bool isFinished) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withOpacity(0.4), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (widget.partido.categoria != null) ...[
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: AppColors.maroonGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.partido.categoria!.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.partido.hora ?? '',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isFinished
                  ? AppColors.success.withOpacity(0.12)
                  : AppColors.info.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFinished
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.clock,
                  size: 10,
                  color: isFinished ? AppColors.success : AppColors.info,
                ),
                const SizedBox(width: 4),
                Text(
                  isFinished ? 'FINALIZADO' : 'PROGRAMADO',
                  style: GoogleFonts.inter(
                    color: isFinished ? AppColors.success : AppColors.info,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchBody(bool localWins, bool visWins) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildTeamSide(
              widget.partido.equipoLocalNombre ?? 'Local',
              widget.partido.equipoLocalEscudo,
              isWinner: localWins,
              alignment: CrossAxisAlignment.start,
            ),
          ),
          _buildCenterSection(),
          Expanded(
            child: _buildTeamSide(
              widget.partido.equipoVisitanteNombre ?? 'Visitante',
              widget.partido.equipoVisitanteEscudo,
              isWinner: visWins,
              alignment: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSide(
    String nombre,
    String? escudo, {
    bool isWinner = false,
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: isWinner ? AppColors.maroonGradient : null,
            color: isWinner ? null : AppColors.bgCardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isWinner
                  ? AppColors.gold
                  : AppColors.divider,
              width: isWinner ? 1.5 : 0.5,
            ),
            boxShadow: isWinner ? AppColors.goldGlowSubtle : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: escudo != null
                ? Image.network(
                    escudo,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _teamInitial(nombre, isWinner),
                  )
                : _teamInitial(nombre, isWinner),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: Text(
            nombre,
            textAlign: alignment == CrossAxisAlignment.start
                ? TextAlign.left
                : TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: isWinner ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _teamInitial(String nombre, bool isWinner) {
    return Center(
      child: Text(
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
        style: GoogleFonts.inter(
          color: isWinner ? AppColors.gold : AppColors.textSecondary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildCenterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: widget.showScore
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.gold.withOpacity(0.6), width: 1.5),
                    boxShadow: AppColors.goldGlowSubtle,
                  ),
                  child: Text(
                    widget.partido.marcador,
                    style: GoogleFonts.inter(
                      color: AppColors.gold,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgDark.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Text(
                    'VS',
                    style: GoogleFonts.inter(
                      color: AppColors.gold.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBottomRow() {
    final hasLugar = widget.partido.lugar != null;
    final hasDetails = widget.showDetails;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Row(
        children: [
          if (hasLugar) ...[
            const Icon(CupertinoIcons.location_solid,
                color: AppColors.textSecondary, size: 11),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.partido.lugar!,
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            const Spacer(),
          if (hasDetails) ...[
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PartidoDetalleScreen(partido: widget.partido),
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.sportscourt_fill,
                        color: AppColors.gold, size: 10),
                    const SizedBox(width: 4),
                    Text('Detalles',
                        style: GoogleFonts.inter(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          GestureDetector(
            onTap: () {
              final pId = int.tryParse(widget.partido.id.toString());
              if (pId != null) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => HighlightsScreen(partidoId: pId),
                ));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.maroonDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📸', style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 4),
                  Text('Galería',
                      style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
