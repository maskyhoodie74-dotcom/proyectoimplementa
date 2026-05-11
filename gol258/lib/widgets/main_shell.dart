import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
    if (location.startsWith('/jugador-dashboard')) return 3;
    return 0;
  }

  List<_NavTab> _buildTabs(AuthProvider auth) {
    final tabs = [
      const _NavTab(
        icon: CupertinoIcons.house,
        activeIcon: CupertinoIcons.house_fill,
        label: 'Inicio',
        route: '/home',
      ),
      const _NavTab(
        icon: CupertinoIcons.calendar,
        activeIcon: CupertinoIcons.calendar_today,
        label: 'Calendario',
        route: '/calendario',
      ),
      const _NavTab(
        icon: CupertinoIcons.chart_bar,
        activeIcon: CupertinoIcons.chart_bar_fill,
        label: 'Tabla',
        route: '/posiciones',
      ),
    ];
    if (auth.isAdmin) {
      tabs.add(const _NavTab(
        icon: CupertinoIcons.settings,
        activeIcon: CupertinoIcons.settings_solid,
        label: 'Admin',
        route: '/admin',
      ));
    } else if (auth.jugadorId != null) {
      tabs.add(const _NavTab(
        icon: CupertinoIcons.person_circle,
        activeIcon: CupertinoIcons.person_circle_fill,
        label: 'Mi Perfil',
        route: '/jugador-dashboard',
      ));
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
    final currentIndex = _locationToIndex(location, auth.isAdmin).clamp(0, tabs.length - 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        final isTablet = constraints.maxWidth > 600 && !isDesktop;

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

  // ═══════════════════════════════════════════════════════
  // DESKTOP — Sidebar navigation (premium style)
  // ═══════════════════════════════════════════════════════
  Widget _buildDesktopLayout(BuildContext context, AuthProvider auth,
      List<_NavTab> tabs, int currentIndex) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Row(
        children: [
          _DesktopSidebar(
            auth: auth,
            tabs: tabs,
            currentIndex: currentIndex,
            onTabTap: (route) => context.go(route),
            onLogout: () => _showLogoutDialog(context),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.bgDark,
                border: Border(
                  left: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TABLET — Rail navigation
  // ═══════════════════════════════════════════════════════
  Widget _buildTabletLayout(BuildContext context, AuthProvider auth,
      List<_NavTab> tabs, int currentIndex) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Row(
        children: [
          _TabletRail(
            auth: auth,
            tabs: tabs,
            currentIndex: currentIndex,
            onTabTap: (route) => context.go(route),
            onLogout: () => _showLogoutDialog(context),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // MOBILE — iOS-style bottom bar
  // ═══════════════════════════════════════════════════════
  Widget _buildMobileLayout(BuildContext context, AuthProvider auth,
      List<_NavTab> tabs, int currentIndex) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      extendBody: true,
      appBar: _IosStyleAppBar(auth: auth, onLogout: () => _showLogoutDialog(context)),
      body: child,
      bottomNavigationBar: _IosBottomBar(
        tabs: tabs,
        currentIndex: currentIndex,
        onTap: (route) => context.go(route),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas salir?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
              context.go('/');
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DESKTOP SIDEBAR
// ═══════════════════════════════════════════════════════════
class _DesktopSidebar extends StatelessWidget {
  final AuthProvider auth;
  final List<_NavTab> tabs;
  final int currentIndex;
  final void Function(String) onTabTap;
  final VoidCallback onLogout;

  const _DesktopSidebar({
    required this.auth,
    required this.tabs,
    required this.currentIndex,
    required this.onTabTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A0A0A), Color(0xFF0D0D0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Brand header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider.withOpacity(0.5), width: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogoCircle(size: 52),
                const SizedBox(height: 16),
                Text(
                  'GOL 258',
                  style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'LIGA CBTIS 258',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                if (auth.userName.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            auth.userName,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              children: [
                Text(
                  'NAVEGACIÓN',
                  style: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                ...tabs.asMap().entries.map((entry) {
                  final i = entry.key;
                  final tab = entry.value;
                  final isSelected = currentIndex == i;
                  return _SidebarItem(
                    tab: tab,
                    isSelected: isSelected,
                    onTap: () => onTabTap(tab.route),
                  );
                }),
              ],
            ),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.all(12),
            child: _SidebarLogout(onLogout: onLogout),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final _NavTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: widget.isSelected ? AppColors.maroonGradient : null,
            color: _hovered && !widget.isSelected
                ? AppColors.bgCard
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: widget.isSelected
                ? Border.all(
                    color: AppColors.gold.withOpacity(0.3),
                    width: 0.5,
                  )
                : null,
            boxShadow: widget.isSelected ? AppColors.cardShadow : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.isSelected ? widget.tab.activeIcon : widget.tab.icon,
                color: widget.isSelected ? AppColors.gold : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                widget.tab.label,
                style: GoogleFonts.inter(
                  color: widget.isSelected ? AppColors.gold : AppColors.textPrimary,
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (widget.isSelected) ...[
                const Spacer(),
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarLogout extends StatefulWidget {
  final VoidCallback onLogout;
  const _SidebarLogout({required this.onLogout});

  @override
  State<_SidebarLogout> createState() => _SidebarLogoutState();
}

class _SidebarLogoutState extends State<_SidebarLogout> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onLogout,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.error.withOpacity(0.12)
                : AppColors.error.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.error.withOpacity(_hovered ? 0.4 : 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.arrow_right_square,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 12),
              Text(
                'Cerrar Sesión',
                style: GoogleFonts.inter(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TABLET RAIL
// ═══════════════════════════════════════════════════════════
class _TabletRail extends StatelessWidget {
  final AuthProvider auth;
  final List<_NavTab> tabs;
  final int currentIndex;
  final void Function(String) onTabTap;
  final VoidCallback onLogout;

  const _TabletRail({
    required this.auth,
    required this.tabs,
    required this.currentIndex,
    required this.onTabTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      decoration: const BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(
          right: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildLogoCircle(size: 40),
          const SizedBox(height: 24),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              children: tabs.asMap().entries.map((entry) {
                final i = entry.key;
                final tab = entry.value;
                final isSelected = currentIndex == i;
                return Tooltip(
                  message: tab.label,
                  preferBelow: false,
                  child: GestureDetector(
                    onTap: () => onTabTap(tab.route),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.maroonDark
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: AppColors.gold.withOpacity(0.3))
                            : null,
                      ),
                      child: Icon(
                        isSelected ? tab.activeIcon : tab.icon,
                        color: isSelected ? AppColors.gold : AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Tooltip(
            message: 'Cerrar Sesión',
            child: GestureDetector(
              onTap: onLogout,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Icon(
                  CupertinoIcons.arrow_right_square,
                  color: AppColors.error,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MOBILE — iOS-style AppBar
// ═══════════════════════════════════════════════════════════
class _IosStyleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AuthProvider auth;
  final VoidCallback onLogout;

  const _IosStyleAppBar({required this.auth, required this.onLogout});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: preferredSize.height + MediaQuery.of(context).padding.top,
          decoration: BoxDecoration(
            color: AppColors.bgDark.withOpacity(0.85),
            border: const Border(
              bottom: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          alignment: Alignment.bottomCenter,
          padding: EdgeInsets.only(
            left: 16,
            right: 8,
            bottom: 8,
            top: MediaQuery.of(context).padding.top,
          ),
          child: Row(
            children: [
              // Logo
              _buildLogoCircle(size: 32),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GOL 258',
                    style: GoogleFonts.inter(
                      color: AppColors.gold,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'CBTis 258',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (auth.userName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5, height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        auth.userName.split(' ').first,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onLogout,
                child: const Icon(
                  CupertinoIcons.arrow_right_square,
                  color: AppColors.error,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MOBILE — iOS-style bottom navigation
// ═══════════════════════════════════════════════════════════
class _IosBottomBar extends StatelessWidget {
  final List<_NavTab> tabs;
  final int currentIndex;
  final void Function(String) onTap;

  const _IosBottomBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard.withOpacity(0.85),
            border: const Border(
              top: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: tabs.asMap().entries.map((entry) {
                  final i = entry.key;
                  final tab = entry.value;
                  final isSelected = currentIndex == i;

                  return Expanded(
                    child: _BottomBarItem(
                      tab: tab,
                      isSelected: isSelected,
                      onTap: () => onTap(tab.route),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatefulWidget {
  final _NavTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomBarItem({
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_BottomBarItem> createState() => _BottomBarItemState();
}

class _BottomBarItemState extends State<_BottomBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(7),
              decoration: widget.isSelected
                  ? BoxDecoration(
                      gradient: AppColors.maroonGradient,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.maroon.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    )
                  : null,
              child: Icon(
                widget.isSelected ? widget.tab.activeIcon : widget.tab.icon,
                color: widget.isSelected ? AppColors.gold : AppColors.textSecondary,
                size: widget.isSelected ? 22 : 20,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.inter(
                color: widget.isSelected ? AppColors.gold : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: widget.isSelected ? 0.2 : 0,
              ),
              child: Text(widget.tab.label),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SHARED: Logo circle
// ═══════════════════════════════════════════════════════════
Widget _buildLogoCircle({required double size}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: AppColors.maroonGradient,
      border: Border.all(color: AppColors.gold, width: size > 40 ? 2 : 1.5),
      boxShadow: AppColors.goldGlowSubtle,
    ),
    child: Center(
      child: Text(
        '⚽',
        style: TextStyle(fontSize: size * 0.45),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════
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
