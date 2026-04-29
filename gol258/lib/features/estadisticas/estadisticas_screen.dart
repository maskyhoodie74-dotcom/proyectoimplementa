import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../jugadores/jugadores_provider.dart';
import '../../core/theme.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});
  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<JugadoresProvider>().fetchJugadores());
  }

  @override
  Widget build(BuildContext context) {
    final jugadores = context.watch<JugadoresProvider>();
    final top = jugadores.topGoleadores;

    return Scaffold(
      appBar: AppBar(
        title: Text('ESTADÍSTICAS',
            style: GoogleFonts.oswald(color: AppColors.gold, fontSize: 20, letterSpacing: 2)),
      ),
      body: jugadores.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : top.isEmpty
              ? Center(child: Text('Sin estadísticas',
                  style: GoogleFonts.oswald(color: AppColors.textSecondary, fontSize: 18)))
              : RefreshIndicator(
                  color: AppColors.gold,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: () => jugadores.fetchJugadores(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionTitle('🏆 TOP GOLEADORES'),
                      const SizedBox(height: 12),
                      ...top.asMap().entries.map((e) {
                        final j = e.value;
                        final pos = e.key + 1;
                        final maxGoles = top.first.goles > 0 ? top.first.goles : 1;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: pos == 1 ? AppColors.gold.withOpacity(0.4) : AppColors.divider,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: pos <= 3 ? AppColors.maroonDark : AppColors.bgCardLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    pos == 1 ? '🥇' : pos == 2 ? '🥈' : pos == 3 ? '🥉' : '$pos',
                                    style: TextStyle(
                                      fontSize: pos <= 3 ? 16 : 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(j.nombre,
                                        style: GoogleFonts.inter(
                                            color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(j.equipoNombre ?? 'Sin equipo',
                                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: j.goles / maxGoles,
                                        backgroundColor: AppColors.divider,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          pos == 1 ? AppColors.gold : AppColors.maroon,
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                children: [
                                  Text('${j.goles}',
                                      style: GoogleFonts.oswald(
                                          color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.w700)),
                                  Text('goles',
                                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      _buildSectionTitle('🎯 TOP ASISTIDORES'),
                      const SizedBox(height: 12),
                      ...([...jugadores.jugadores]
                          ..sort((a, b) => b.asistencias.compareTo(a.asistencias)))
                          .take(5)
                          .map((j) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Text('🎯', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(j.nombre,
                                        style: GoogleFonts.inter(
                                            color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                                    Text(j.equipoNombre ?? 'Sin equipo',
                                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Text('${j.asistencias}',
                                  style: GoogleFonts.oswald(
                                      color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 4),
                              Text('asist.', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10)),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.oswald(
            color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1));
  }
}
