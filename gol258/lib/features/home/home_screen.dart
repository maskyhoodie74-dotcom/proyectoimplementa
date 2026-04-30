import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../partidos/partidos_provider.dart';
import '../../core/theme.dart';
import '../../models/partido.dart';
import '../../widgets/match_card.dart';
import '../../widgets/section_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  int _selectedFilterIndex = 0;

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
        backgroundColor: AppColors.bgDark,
        elevation: 0,
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
                style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontSize: 20,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.gold),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('No hay notificaciones nuevas'),
                    backgroundColor: AppColors.maroon),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.bgCard,
        onRefresh: () => partidos.fetchPartidos(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              final contentWidth = isDesktop ? 1200.0 : double.infinity;
              final cardWidth = isDesktop ? 380.0 : double.infinity;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
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
                  // Tus próximos partidos (solo si tiene equipo)
                  if (auth.equipoId != null && _searchQuery.isEmpty) ...[
                    SectionHeader(
                      title: 'TUS PRÓXIMOS PARTIDOS',
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
                    else if (partidos.proximosPartidosDeEquipo(auth.equipoId!).isEmpty)
                      _buildEmptyState('Tu equipo no tiene partidos programados')
                    else
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: partidos.proximosPartidosDeEquipo(auth.equipoId!).take(3).map(
                              (p) => SizedBox(
                                width: cardWidth,
                                child: MatchCard(partido: p, showDetails: true),
                              ),
                            ).toList(),
                      ),
                    const SizedBox(height: 24),
                  ],
                  // Próximos partidos generales
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
                  else if (_filterPartidos(partidos.proximosPartidos).isEmpty)
                    _buildEmptyState('No hay partidos programados')
                  else
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _filterPartidos(partidos.proximosPartidos).take(isDesktop ? 6 : 3).map(
                            (p) => SizedBox(
                              width: cardWidth,
                              child: MatchCard(partido: p, showDetails: true),
                            ),
                          ).toList(),
                    ),
                  const SizedBox(height: 24),
                  // Últimos resultados
                  SectionHeader(
                    title: 'ÚLTIMOS RESULTADOS',
                    onSeeAll: () => context.go('/resultados'),
                  ),
                  const SizedBox(height: 12),
                  if (_filterPartidos(partidos.resultados).isEmpty)
                    _buildEmptyState('Sin resultados todavía')
                  else
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: _filterPartidos(partidos.resultados).take(isDesktop ? 6 : 3).map(
                            (p) => SizedBox(
                              width: cardWidth,
                              child: MatchCard(partido: p, showScore: true),
                            ),
                          ).toList(),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
        ),
      ),
    );
  }

  List<Partido> _filterPartidos(List<Partido> source) {
    if (_searchQuery.isEmpty) return source;
    return source.where((p) {
      final loc = p.equipoLocalNombre?.toLowerCase() ?? '';
      final vis = p.equipoVisitanteNombre?.toLowerCase() ?? '';
      final lug = p.lugar?.toLowerCase() ?? '';
      final q = _searchQuery.toLowerCase();
      return loc.contains(q) || vis.contains(q) || lug.contains(q);
    }).toList();
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCardLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar equipos, canchas o categorías...',
          hintStyle:
              GoogleFonts.inter(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 14),
          prefixIcon: const Icon(Icons.search,
              color: AppColors.gold, size: 22),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
          final isSelected = entry.key == _selectedFilterIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilterIndex = entry.key);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Filtro aplicado: ${entry.value}'),
                    backgroundColor: AppColors.maroon,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.goldGradient : null,
                  color: isSelected ? null : AppColors.bgCardLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? AppColors.gold : AppColors.gold.withOpacity(0.1),
                  ),
                  boxShadow: isSelected ? AppColors.goldGlow : null,
                ),
                child: Text(
                  entry.value,
                  style: GoogleFonts.inter(
                    color:
                        isSelected ? AppColors.bgDark : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
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
