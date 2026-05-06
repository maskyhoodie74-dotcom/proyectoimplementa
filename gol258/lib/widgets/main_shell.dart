import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../features/auth/auth_provider.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location, bool isAdmin) {
    if (location.startsWith('/calendario')) return 1;
    if (location.startsWith('/posiciones')) return 2;
    if (location.startsWith('/admin')) return isAdmin ? 3 : 0;
    if (location.startsWith('/equipos')) return isAdmin ? 3 : 0;
    if (location.startsWith('/jugadores')) return isAdmin ? 3 : 0;
    if (location.startsWith('/estadisticas')) return isAdmin ? 3 : 0;
    if (location.startsWith('/resultados')) return 0;
    return 0;
  }

  List<_NavTab> _buildTabs(AuthProvider auth) {
    final tabs = [
      const _NavTab(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Inicio', route: '/home'),
      const _NavTab(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Calendario', route: '/calendario'),
      const _NavTab(icon: Icons.leaderboard_outlined, activeIcon: Icons.leaderboard, label: 'Tabla', route: '/posiciones'),
    ];
    if (auth.isAdmin) {
      tabs.add(const _NavTab(
          icon: Icons.manage_accounts_outlined,
          activeIcon: Icons.manage_accounts,
          label: 'Admin',
          route: '/admin'));
    } else if (auth.jugadorId != null) {
      tabs.add(const _NavTab(
          icon: Icons.sports_soccer_outlined,
          activeIcon: Icons.sports_soccer,
          label: 'Mi Perfil',
          route: '/jugador-dashboard'));
    }
    return tabs;
  }

  void _doLogout(BuildContext context) {
    context.read<AuthProvider>().logout();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final location = GoRouterState.of(context).matchedLocation;
    final tabs = _buildTabs(auth);
    final currentIndex = _locationToIndex(location, auth.isAdmin)
        .clamp(0, tabs.length - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        final isTablet = constraints.maxWidth > 500 && !isDesktop;

        if (isDesktop) {
          return _buildDesktopLayout(context, auth, tabs, currentIndex);
        } else if (isTablet) {
          return _buildTabletLayout(context, auth, tabs, currentIndex);
        } else {
          return _buildMobileLayout(context, auth, tabs, currentIndex);
        }
      },
    );
  }

  // ─────────────────────── DESKTOP (NavigationRail) ───────────────────────
  Widget _buildDesktopLayout(BuildContext context, AuthProvider auth,
      List<_NavTab> tabs, int currentIndex) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Row(
        children: [
          Container(
            width: 200,
            color: AppColors.bgCard,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.divider)),
                  ),
                  child: Column(children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.maroonDark,
                        border: Border.all(color: AppColors.gold, width: 2),
                        boxShadow: AppColors.goldGlow,
                      ),
                      child: const Center(child: Text('⚽', style: TextStyle(fontSize: 28))),
                    ),
                    const SizedBox(height: 12),
                    Text('GOL 258',
                        style: GoogleFonts.inter(
                            color: AppColors.gold,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2)),
                    if (auth.userName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        auth.userName,
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ]),
                ),
                // Nav items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    children: tabs.asMap().entries.map((entry) {
                      final i = entry.key;
                      final tab = entry.value;
                      final isSelected = currentIndex == i;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppColors.maroonGradient : null,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: AppColors.gold.withValues(alpha: 0.3))
                              : null,
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            isSelected ? tab.activeIcon : tab.icon,
                            color: isSelected ? AppColors.gold : AppColors.textSecondary,
                            size: 22,
                          ),
                          title: Text(
                            tab.label,
                            style: GoogleFonts.inter(
                              color: isSelected ? AppColors.gold : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          onTap: () => context.go(tab.route),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Logout
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.logout_rounded,
                          color: AppColors.error, size: 20),
                      title: Text('Cerrar Sesión',
                          style: GoogleFonts.inter(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onTap: () => _doLogout(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1, color: AppColors.divider),
          Expanded(child: child),
        ],
      ),
    );
  }

  // ─────────────────────── TABLET (NavigationRail compacto) ───────────────
  Widget _buildTabletLayout(BuildContext context, AuthProvider auth,
      List<_NavTab> tabs, int currentIndex) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: AppColors.bgCard,
            selectedIndex: currentIndex.clamp(0, tabs.length - 1),
            onDestinationSelected: (idx) => context.go(tabs[idx].route),
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: AppColors.gold, size: 26),
            unselectedIconTheme:
                const IconThemeData(color: AppColors.textSecondary, size: 22),
            selectedLabelTextStyle: GoogleFonts.inter(
                color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 10),
            unselectedLabelTextStyle:
                GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
            indicatorColor: AppColors.maroonDark.withValues(alpha: 0.6),
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 12),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.maroonDark,
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: const Center(child: Text('⚽', style: TextStyle(fontSize: 22))),
              ),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: IconButton(
                icon: const Icon(Icons.logout_rounded,
                    color: AppColors.error, size: 22),
                tooltip: 'Cerrar Sesión',
                onPressed: () => _doLogout(context),
              ),
            ),
            destinations: tabs.map((t) => NavigationRailDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.activeIcon),
              label: Text(t.label.toUpperCase()),
            )).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1, color: AppColors.divider),
          Expanded(child: child),
        ],
      ),
    );
  }

  // ─────────────────────── MOBILE (BottomNavigationBar + AppBar global) ───
  Widget _buildMobileLayout(BuildContext context, AuthProvider auth,
      List<_NavTab> tabs, int currentIndex) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.maroonDark,
              border: Border.all(color: AppColors.gold, width: 1.5),
            ),
            child: const Center(child: Text('⚽', style: TextStyle(fontSize: 15))),
          ),
          const SizedBox(width: 8),
          Text('GOL 258',
              style: GoogleFonts.inter(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5)),
        ]),
        actions: [
          // User name
          if (auth.userName.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  auth.userName,
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
            ),
          // Logout button always visible
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: _buildBottomNav(context, tabs, currentIndex),
    );
  }

  Widget _buildBottomNav(
      BuildContext context, List<_NavTab> tabs, int currentIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: tabs.asMap().entries.map((entry) {
              final i = entry.key;
              final tab = entry.value;
              final isSelected = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => context.go(tab.route),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: isSelected
                            ? BoxDecoration(
                                color: AppColors.maroonDark,
                                borderRadius: BorderRadius.circular(10),
                              )
                            : null,
                        child: Icon(
                          isSelected ? tab.activeIcon : tab.icon,
                          color: isSelected
                              ? AppColors.gold
                              : AppColors.textSecondary,
                          size: isSelected ? 22 : 20,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.label,
                        style: GoogleFonts.inter(
                          color: isSelected
                              ? AppColors.gold
                              : AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Row(children: [
          const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 8),
          Text('Cerrar Sesión',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        ]),
        content: Text('¿Estás seguro que deseas cerrar sesión?',
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCELAR',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
              context.go('/');
            },
            child: Text('SALIR',
                style: GoogleFonts.inter(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
