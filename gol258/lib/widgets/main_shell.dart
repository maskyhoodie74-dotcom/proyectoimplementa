import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../features/auth/auth_provider.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/calendario')) return 1;
    if (location.startsWith('/posiciones')) return 2;
    if (location.startsWith('/admin')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    final tabs = [
      const _NavTab(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Inicio', route: '/home'),
      const _NavTab(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Calendario', route: '/calendario'),
      const _NavTab(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Tabla', route: '/posiciones'),
    ];

    if (auth.isAdmin) {
      tabs.add(const _NavTab(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
          label: 'Admin',
          route: '/admin'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        if (isDesktop) {
          // Navigation Rail para escritorio
          return Scaffold(
            backgroundColor: AppColors.bgDark,
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: AppColors.bgCard,
                  selectedIndex: currentIndex,
                  onDestinationSelected: (idx) => context.go(tabs[idx].route),
                  labelType: NavigationRailLabelType.all,
                  selectedIconTheme: const IconThemeData(color: AppColors.gold, size: 28),
                  unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),
                  selectedLabelTextStyle: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 11),
                  unselectedLabelTextStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                  indicatorColor: AppColors.maroonDark.withOpacity(0.5),
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, top: 16),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.maroonDark,
                        border: Border.all(color: AppColors.gold, width: 2),
                      ),
                      child: const Center(child: Text('⚽', style: TextStyle(fontSize: 24))),
                    ),
                  ),
                  destinations: tabs.map((t) {
                    return NavigationRailDestination(
                      icon: Icon(t.icon),
                      selectedIcon: Icon(t.activeIcon),
                      label: Text(t.label.toUpperCase()),
                    );
                  }).toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1, color: AppColors.divider),
                Expanded(child: child),
              ],
            ),
          );
        }

        // Scaffold con Drawer desplegable para móviles
        return Scaffold(
          drawer: _buildDrawer(context, tabs, currentIndex, auth),
          body: child,
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, List<_NavTab> tabs, int currentIndex, AuthProvider auth) {
    return Drawer(
      backgroundColor: AppColors.bgCard,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.divider)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.maroonDark,
                      border: Border.all(color: AppColors.gold, width: 2),
                      boxShadow: AppColors.goldGlow,
                    ),
                    child: const Center(child: Text('⚽', style: TextStyle(fontSize: 32))),
                  ),
                  const SizedBox(height: 16),
                  Text('COBRAS CBTIS 258',
                      style: GoogleFonts.inter(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  if (auth.userName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(auth.userName, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                  ]
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                itemCount: tabs.length,
                itemBuilder: (context, i) {
                  final tab = tabs[i];
                  final isSelected = currentIndex == i;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.maroonDark.withOpacity(0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: AppColors.gold.withOpacity(0.5)) : Border.all(color: Colors.transparent),
                    ),
                    child: ListTile(
                      leading: Icon(isSelected ? tab.activeIcon : tab.icon,
                          color: isSelected ? AppColors.gold : AppColors.textSecondary),
                      title: Text(tab.label.toUpperCase(),
                          style: GoogleFonts.inter(
                              color: isSelected ? AppColors.gold : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              letterSpacing: 1)),
                      onTap: () {
                        Navigator.pop(context); // Cierra el drawer
                        context.go(tab.route);
                      },
                    ),
                  );
                },
              ),
            ),
            if (auth.isLoggedIn)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error.withOpacity(0.1),
                    foregroundColor: AppColors.error,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar Sesión'),
                  onPressed: () {
                    auth.logout();
                    context.go('/');
                  },
                ),
              ),
          ],
        ),
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
