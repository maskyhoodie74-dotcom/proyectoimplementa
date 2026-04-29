import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../partidos/partidos_provider.dart';
import '../../core/theme.dart';
import '../../widgets/match_card.dart';

class ResultadosScreen extends StatefulWidget {
  const ResultadosScreen({super.key});
  @override
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PartidosProvider>().fetchPartidos());
  }

  @override
  Widget build(BuildContext context) {
    final partidos = context.watch<PartidosProvider>();
    final resultados = partidos.resultados;

    return Scaffold(
      appBar: AppBar(
        title: Text('RESULTADOS',
            style: GoogleFonts.oswald(color: AppColors.gold, fontSize: 20, letterSpacing: 2)),
      ),
      body: partidos.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : resultados.isEmpty
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text('Sin resultados todavía', style: GoogleFonts.oswald(color: AppColors.textSecondary, fontSize: 18)),
                  ],
                ))
              : RefreshIndicator(
                  color: AppColors.gold,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: () => partidos.fetchPartidos(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: resultados.length,
                    itemBuilder: (_, i) {
                      final p = resultados[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MatchCard(partido: p, showScore: true),
                      );
                    },
                  ),
                ),
    );
  }
}
