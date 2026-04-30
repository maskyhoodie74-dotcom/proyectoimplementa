import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.gold, size: 20),
          onPressed: () => context.go('/home'),
        ),
        title: Text('RESULTADOS',
            style: GoogleFonts.inter(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
      body: partidos.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : resultados.isEmpty
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text('Sin resultados todavía', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 18)),
                  ],
                ))
              : RefreshIndicator(
                  color: AppColors.gold,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: () => partidos.fetchPartidos(),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 800;
                      final contentWidth = isDesktop ? 1200.0 : double.infinity;
                      final cardWidth = isDesktop ? 380.0 : double.infinity;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentWidth),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: resultados.map((p) {
                                return SizedBox(
                                  width: cardWidth,
                                  child: MatchCard(partido: p, showScore: true),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
