import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../equipos/equipos_provider.dart';
import '../partidos/partidos_provider.dart';
import '../../core/theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _localCtrl = TextEditingController();
  final _visitanteCtrl = TextEditingController();
  String? _selectedPartidoId;
  int _golesLocal = 0;
  int _golesVisitante = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<EquiposProvider>().fetchEquipos();
      context.read<PartidosProvider>().fetchPartidos();
    });
  }

  @override
  void dispose() {
    _localCtrl.dispose();
    _visitanteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('Acceso restringido',
              style: TextStyle(color: AppColors.error)),
        ),
      );
    }

    final equipos = context.watch<EquiposProvider>();
    final partidos = context.watch<PartidosProvider>();

    return Scaffold(
      backgroundColor: AppColors.maroonDark,
      appBar: AppBar(
        backgroundColor: AppColors.maroonDark,
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
                    color: AppColors.gold, fontSize: 20, letterSpacing: 2)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.gold),
            onPressed: () => _showNotifications(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: AppColors.error),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go('/');
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          final contentWidth = isDesktop ? 1000.0 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.all(isDesktop ? 32 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PORTAL DEL COORDINADOR',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text('Gestión Deportiva',
                        style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    // Action grid
                    GridView.count(
                      crossAxisCount: isDesktop ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: isDesktop ? 1.8 : 1.4,
                      children: [
                        _actionCard(
                          icon: Icons.group_add_outlined,
                          label: '+ Equipo',
                          onTap: () => context.go('/equipos'),
                        ),
                        _actionCard(
                          icon: Icons.person_add_outlined,
                          label: '+ Jugador',
                          onTap: () => context.go('/jugadores'),
                        ),
                        _actionCard(
                          icon: Icons.calendar_month_outlined,
                          label: 'Jornada',
                          onTap: () => context.go('/calendario'),
                        ),
                        _actionCard(
                          icon: Icons.bar_chart_outlined,
                          label: 'Reportes',
                          onTap: () => context.go('/estadisticas'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Resultados en vivo
                    _buildResultadosEnVivo(partidos),
                    const SizedBox(height: 24),
                // Equipos activos
                _buildEquiposActivos(equipos),
                const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: AppColors.gold),
            const SizedBox(width: 8),
            Text('Notificaciones Admin', style: GoogleFonts.inter(color: AppColors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline, color: AppColors.gold),
              title: Text('Bienvenido al panel', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14)),
              subtitle: Text('Aquí puedes gestionar toda la liga.', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
            ),
            const Divider(color: AppColors.divider),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.warning_amber_rounded, color: AppColors.maroon),
              title: Text('Equipos sin entrenador', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14)),
              subtitle: Text('Revisa los equipos registrados.', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.maroonDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.gold, size: 24),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadosEnVivo(PartidosProvider partidos) {
    final proximosPartidos = partidos.proximosPartidos;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text('RESULTADOS EN VIVO',
                  style: GoogleFonts.inter(
                      color: AppColors.gold,
                      fontSize: 14,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          // Selector partido
          Text('PARTIDO',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: DropdownButton<String>(
              value: _selectedPartidoId,
              isExpanded: true,
              dropdownColor: AppColors.bgCard,
              underline: const SizedBox(),
              hint: Text('Seleccionar partido',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 13)),
              items: proximosPartidos.map((p) {
                return DropdownMenuItem<String>(
                  value: p.id,
                  child: Text(
                    '${p.equipoLocalNombre ?? "Local"} vs ${p.equipoVisitanteNombre ?? "Visitante"}',
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary, fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedPartidoId = val),
            ),
          ),
          const SizedBox(height: 16),
          // Marcador
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text('L',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    _scoreBox(_golesLocal, () {
                      setState(() => _golesLocal++);
                    }, () {
                      if (_golesLocal > 0) setState(() => _golesLocal--);
                    }),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(':',
                    style: GoogleFonts.inter(
                        color: AppColors.gold,
                        fontSize: 32,
                        fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('V',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    _scoreBox(_golesVisitante, () {
                      setState(() => _golesVisitante++);
                    }, () {
                      if (_golesVisitante > 0) {
                        setState(() => _golesVisitante--);
                      }
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedPartidoId == null
                  ? null
                  : () async {
                      final ok = await partidos.registrarResultado(
                          _selectedPartidoId!, _golesLocal, _golesVisitante);
                      if (ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Resultado guardado'),
                              backgroundColor: AppColors.success),
                        );
                        setState(() {
                          _selectedPartidoId = null;
                          _golesLocal = 0;
                          _golesVisitante = 0;
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.maroon,
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text('GUARDAR RESULTADO'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBox(int value, VoidCallback onAdd, VoidCallback onRemove) {
    return Column(
      children: [
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.all(4),
            child: const Icon(Icons.add, color: AppColors.gold, size: 18),
          ),
        ),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.bgCardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            padding: const EdgeInsets.all(4),
            child: const Icon(Icons.remove, color: AppColors.textSecondary, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildEquiposActivos(EquiposProvider equipos) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('EQUIPOS ACTIVOS',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    letterSpacing: 1.5)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text('${equipos.equipos.length} TOTAL',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (equipos.loading)
          const CircularProgressIndicator(color: AppColors.gold)
        else
          ...equipos.equipos.take(3).map((eq) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.maroonDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                        child: Text('🛡️', style: TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(eq.nombre,
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        Text(
                            '${eq.categoria ?? "Sin categoría"}',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: AppColors.textSecondary, size: 18),
                    onPressed: () => context.go('/equipos'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error, size: 18),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.bgCard,
                          title: Text('Eliminar equipo',
                              style: GoogleFonts.inter(
                                  color: AppColors.textPrimary)),
                          content: Text('¿Estás seguro?',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary)),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancelar')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Eliminar',
                                    style: TextStyle(color: AppColors.error))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await context
                            .read<EquiposProvider>()
                            .eliminarEquipo(eq.id);
                      }
                    },
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/equipos'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.divider),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('VER TODOS LOS EQUIPOS',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    letterSpacing: 1.5)),
          ),
        ),
      ],
    );
  }
}
