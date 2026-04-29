import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../partidos/partidos_provider.dart';
import '../../core/theme.dart';
import '../../widgets/match_card.dart';
import '../../widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<PartidosProvider>().fetchPartidos());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final partidos = context.watch<PartidosProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.maroonDark,
                border: Border.all(color: AppColors.gold, width: 1.5),
              ),
              child: const Center(
                  child: Text('⚽', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 10),
            Text('COBRAS',
                style: GoogleFonts.oswald(
                    color: AppColors.gold,
                    fontSize: 20,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.gold),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.bgCard,
        onRefresh: () => partidos.fetchPartidos(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Search bar
              _buildSearchBar(),
              const SizedBox(height: 20),
              // Filter chips
              _buildFilterChips(),
              const SizedBox(height: 24),
              // Próximos partidos
              SectionHeader(
                title: 'PRÓXIMOS PARTIDOS',
                onSeeAll: () => context.go('/calendario'),
              ),
              const SizedBox(height: 12),
              if (partidos.loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                )
              else if (partidos.proximosPartidos.isEmpty)
                _buildEmptyState('No hay partidos programados')
              else
                ...partidos.proximosPartidos.take(3).map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MatchCard(partido: p, showDetails: true),
                      ),
                    ),
              const SizedBox(height: 24),
              // Últimos resultados
              SectionHeader(
                title: 'ÚLTIMOS RESULTADOS',
                onSeeAll: () => context.go('/resultados'),
              ),
              const SizedBox(height: 12),
              if (partidos.resultados.isEmpty)
                _buildEmptyState('Sin resultados todavía')
              else
                ...partidos.resultados.take(3).map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MatchCard(partido: p, showScore: true),
                      ),
                    ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar equipos o campos...',
          hintStyle:
              GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: const Icon(Icons.search,
              color: AppColors.textSecondary, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['TODOS LOS PARTIDOS', 'LOCALES', 'TOP'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final isSelected = entry.key == 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.gold : AppColors.divider,
                ),
              ),
              child: Text(
                entry.value,
                style: GoogleFonts.oswald(
                  color:
                      isSelected ? AppColors.bgDark : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Text(message,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 14)),
      ),
    );
  }
}
