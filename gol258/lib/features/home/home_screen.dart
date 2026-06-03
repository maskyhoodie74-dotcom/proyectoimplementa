import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../partidos/partidos_provider.dart';
import '../../core/theme.dart';
import '../../models/partido.dart';
import '../../widgets/match_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  int _selectedFilterIndex = 0;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    Future.microtask(() =>
        context.read<PartidosProvider>().fetchPartidos());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final partidos = context.watch<PartidosProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.bgCard,
        onRefresh: () => partidos.fetchPartidos(),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Hero Header
              SliverToBoxAdapter(child: _buildHeroHeader(auth, partidos)),
              // Search + Filters
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 12),
                      _buildFilterChips(),
                    ],
                  ),
                ),
              ),
              // My team matches
              if (auth.equipoId != null && _searchQuery.isEmpty) ...[
                _buildSectionSliver(
                  title: 'TUS PRÓXIMOS PARTIDOS',
                  icon: CupertinoIcons.star_fill,
                  onSeeAll: () => context.go('/calendario'),
                ),
                _buildMatchesSliver(
                  partidos.loading,
                  _filterPartidos(partidos.proximosPartidosDeEquipo(auth.equipoId!), auth),
                  emptyMsg: 'Tu equipo no tiene partidos programados',
                  showScore: false,
                ),
              ],
              // Upcoming matches
              _buildSectionSliver(
                title: 'PRÓXIMOS PARTIDOS',
                icon: CupertinoIcons.calendar,
                onSeeAll: () => context.go('/calendario'),
              ),
              _buildMatchesSliver(
                partidos.loading,
                _filterPartidos(partidos.proximosPartidos, auth),
                emptyMsg: 'No hay partidos programados',
                showScore: false,
              ),
              // Results
              _buildSectionSliver(
                title: 'ÚLTIMOS RESULTADOS',
                icon: CupertinoIcons.chart_bar_fill,
                onSeeAll: () => context.go('/resultados'),
              ),
              _buildMatchesSliver(
                false,
                _filterPartidos(partidos.resultados, auth),
                emptyMsg: 'Sin resultados todavía',
                showScore: true,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(AuthProvider auth, PartidosProvider partidos) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      decoration: const BoxDecoration(
        gradient: AppColors.heroBg,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 480;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.userName.isNotEmpty
                      ? 'Hola, ${auth.userName.split(' ').first} 👋'
                      : 'Liga GOL 258 👋',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.goldGradient.createShader(bounds),
                  child: Text(
                    'Torneos CBTis 258',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStatCard(
                        '${partidos.proximosPartidos.length}',
                        'Próximos',
                        CupertinoIcons.calendar,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMiniStatCard(
                        '${partidos.resultados.length}',
                        'Jugados',
                        CupertinoIcons.checkmark_seal_fill,
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.userName.isNotEmpty
                            ? 'Hola, ${auth.userName.split(' ').first} 👋'
                            : 'Liga GOL 258 👋',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.goldGradient.createShader(bounds),
                        child: Text(
                          'Torneos CBTis 258',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildMiniStatCard(
                  '${partidos.proximosPartidos.length}',
                  'Próximos',
                  CupertinoIcons.calendar,
                ),
                const SizedBox(width: 8),
                _buildMiniStatCard(
                  '${partidos.resultados.length}',
                  'Jugados',
                  CupertinoIcons.checkmark_seal_fill,
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildMiniStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppColors.glassGradient,
        color: AppColors.bgCardLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 14),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.glassGradient,
            color: AppColors.bgCard.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Buscar equipos, canchas...',
              hintStyle: GoogleFonts.inter(
                  color: AppColors.textTertiary, fontSize: 15),
              prefixIcon: const Icon(CupertinoIcons.search,
                  color: AppColors.textSecondary, size: 20),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      (label: 'Todos', icon: CupertinoIcons.square_grid_2x2),
      (label: 'Locales', icon: CupertinoIcons.location_solid),
      (label: 'División I', icon: CupertinoIcons.star_fill),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.asMap().entries.map((entry) {
          final isSelected = entry.key == _selectedFilterIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.goldGradient : AppColors.glassGradient,
                  color: isSelected ? null : AppColors.bgCardLight.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.gold
                        : AppColors.divider,
                    width: isSelected ? 1 : 0.5,
                  ),
                  boxShadow: isSelected ? AppColors.goldGlowSubtle : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      entry.value.icon,
                      size: 13,
                      color: isSelected ? AppColors.bgDark : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.value.label,
                      style: GoogleFonts.inter(
                        color: isSelected ? AppColors.bgDark : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.maroonGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.gold, size: 14),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                children: [
                  Text(
                    'Ver todos',
                    style: GoogleFonts.inter(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(CupertinoIcons.chevron_right,
                      color: AppColors.gold, size: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildSectionSliver({
    required String title,
    required IconData icon,
    VoidCallback? onSeeAll,
  }) {
    return SliverToBoxAdapter(
      child: _buildSectionHeader(title: title, icon: icon, onSeeAll: onSeeAll),
    );
  }

  SliverToBoxAdapter _buildMatchesSliver(
    bool loading,
    List<Partido> matches, {
    required String emptyMsg,
    required bool showScore,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              )
            : matches.isEmpty
                ? _buildEmptyState(emptyMsg)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      if (isWide) {
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: matches.take(6).map((p) => SizedBox(
                            width: (constraints.maxWidth - 12) / 2,
                            child: MatchCard(partido: p, showScore: showScore, showDetails: !showScore),
                          )).toList(),
                        );
                      }
                      return Column(
                        children: matches.take(3).map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: MatchCard(partido: p, showScore: showScore, showDetails: !showScore),
                        )).toList(),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.sportscourt,
              color: AppColors.textTertiary, size: 36),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  List<Partido> _filterPartidos(List<Partido> source, AuthProvider auth) {
    List<Partido> filtered = source;
    if (_selectedFilterIndex == 1 && auth.equipoId != null) {
      filtered = filtered
          .where((p) =>
              p.equipoLocalId == auth.equipoId ||
              p.equipoVisitanteId == auth.equipoId)
          .toList();
    } else if (_selectedFilterIndex == 2) {
      filtered = filtered
          .where((p) => p.categoria == 'División I')
          .toList();
      if (filtered.isEmpty) filtered = source;
    }
    if (_searchQuery.isEmpty) return filtered;
    return filtered.where((p) {
      final loc = p.equipoLocalNombre?.toLowerCase() ?? '';
      final vis = p.equipoVisitanteNombre?.toLowerCase() ?? '';
      final lug = p.lugar?.toLowerCase() ?? '';
      final q = _searchQuery.toLowerCase();
      return loc.contains(q) || vis.contains(q) || lug.contains(q);
    }).toList();
  }
}
