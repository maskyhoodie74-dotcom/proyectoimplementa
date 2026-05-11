import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
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
    Future.microtask(
        () => context.read<PartidosProvider>().fetchPartidos());
  }

  @override
  Widget build(BuildContext context) {
    final partidos = context.watch<PartidosProvider>();
    final resultados = partidos.resultados;

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
                  child: const Icon(CupertinoIcons.checkmark_seal_fill,
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
                        'RESULTADOS',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Text(
                      '${resultados.length} partidos jugados',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: partidos.loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold))
                : resultados.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppColors.gold,
                        backgroundColor: AppColors.bgCard,
                        onRefresh: () => partidos.fetchPartidos(),
                        child: LayoutBuilder(builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth > 800;
                          return Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth: isDesktop ? 1100.0 : double.infinity),
                              child: isDesktop
                                  ? _buildGridView(resultados, constraints)
                                  : _buildListView(resultados),
                            ),
                          );
                        }),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List resultados) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      itemCount: resultados.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => MatchCard(
        partido: resultados[i],
        showScore: true,
      ),
    );
  }

  Widget _buildGridView(List resultados, BoxConstraints constraints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: resultados.map((p) {
          return SizedBox(
            width: (constraints.maxWidth - 64) / 2,
            child: MatchCard(partido: p, showScore: true),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sin resultados todavía',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los resultados aparecerán\ncuando se jueguen los partidos.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
