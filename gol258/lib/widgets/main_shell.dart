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

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: tabs.asMap().entries.map((entry) {
                final i = entry.key;
                final tab = entry.value;
                final isSelected = currentIndex == i;
                final isAdminTab = tab.route == '/admin';
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(tab.route),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      decoration: isAdminTab && isSelected
                          ? BoxDecoration(
                              color: AppColors.maroon,
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      margin: isAdminTab ? const EdgeInsets.all(8) : EdgeInsets.zero,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? tab.activeIcon : tab.icon,
                            color: isAdminTab
                                ? (isSelected ? AppColors.gold : AppColors.textSecondary)
                                : (isSelected ? AppColors.gold : AppColors.textSecondary),
                            size: 22,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tab.label.toUpperCase(),
                            style: GoogleFonts.inter(
                              color: isSelected ? AppColors.gold : AppColors.textSecondary,
                              fontSize: 9,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
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
