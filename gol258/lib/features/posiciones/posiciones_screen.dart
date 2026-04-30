import 'dart:ui';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../partidos/partidos_provider.dart';
import '../../core/theme.dart';

class PosicionesScreen extends StatefulWidget {
  const PosicionesScreen({super.key});
  @override
  State<PosicionesScreen> createState() => _PosicionesScreenState();
}

class _PosicionesScreenState extends State<PosicionesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PartidosProvider>().fetchPartidos());
  }

  @override
  Widget build(BuildContext context) {
    final partidos = context.watch<PartidosProvider>();
    final tabla = partidos.calcularPosiciones();
    final entries = tabla.entries.toList()
      ..sort((a, b) {
        final ptsB = b.value['Pts'] ?? 0;
        final ptsA = a.value['Pts'] ?? 0;
        if (ptsA != ptsB) return ptsB.compareTo(ptsA);
        final gdA = (a.value['GF'] ?? 0) - (a.value['GC'] ?? 0);
        final gdB = (b.value['GF'] ?? 0) - (b.value['GC'] ?? 0);
        return gdB.compareTo(gdA);
      });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: Text('POSICIONES',
            style: GoogleFonts.inter(color: AppColors.gold, fontSize: 20, letterSpacing: 2)),
      ),
      body: partidos.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
              : RefreshIndicator(
                  color: AppColors.gold,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: () => partidos.fetchPartidos(),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 800;
                      final contentWidth = isDesktop ? 1000.0 : double.infinity;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentWidth),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            padding: EdgeInsets.all(isDesktop ? 32 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                _buildHeader(),
                                const SizedBox(height: 8),
                                if (entries.isEmpty)
                                  _buildEmptyRow()
                                else
                                  ...entries.asMap().entries.map((e) {
                                    final pos = e.key + 1;
                                    final nombre = e.value.key;
                                    final stats = e.value.value;
                                    return _buildRow(pos, nombre, stats);
                                  }),
                                const SizedBox(height: 24),
                                _buildLegend(),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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

  Widget _buildEmptyRow() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Text(
          'AÚN NO HAY DATOS REGISTRADOS',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildRow(int pos, String nombre, Map<String, int> stats) {
    final gd = (stats['GF'] ?? 0) - (stats['GC'] ?? 0);
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
            width: 28,
            child: pos == 1
                ? const Text('🥇', style: TextStyle(fontSize: 16))
                : pos == 2
                    ? const Text('🥈', style: TextStyle(fontSize: 16))
                    : pos == 3
                        ? const Text('🥉', style: TextStyle(fontSize: 16))
                        : Text('$pos', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(nombre,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
                overflow: TextOverflow.ellipsis),
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
                color: gd > 0 ? AppColors.success : gd < 0 ? AppColors.error : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text('${stats['Pts'] ?? 0}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
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
          Text('LEYENDA', style: GoogleFonts.inter(color: AppColors.gold, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
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
          SizedBox(width: 36, child: Text(abbr,
              style: GoogleFonts.inter(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600))),
          Text(full, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => GoogleFonts.inter(
      color: AppColors.bgDark, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w700);

  TextStyle _cellStyle() =>
      GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13);
}
