import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../equipos/equipos_provider.dart';
import '../jugadores/jugadores_provider.dart';
import '../partidos/partidos_provider.dart';
import '../../core/theme.dart';
import '../../models/jugador.dart';
import '../../models/partido.dart';
import '../../widgets/anotadores_dialog.dart';

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
  // Paso 2 - anotadores
  bool _mostrarAnotadores = false;
  List<Jugador> _jugadoresLocal = [];
  List<Jugador> _jugadoresVisitante = [];
  Map<String, int> _golesAnotadores = {}; // jugadorId -> goles asignados

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
            Image.asset(
              'assets/images/logo_no_bg.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
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
                        _actionCard(
                          icon: Icons.emoji_events_outlined,
                          label: 'Liguilla',
                          onTap: () => context.go('/admin-liguilla'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Resultados en vivo
                    _buildResultadosEnVivo(partidos),
                    const SizedBox(height: 24),
                    // Últimos resultados con edición
                    if (partidos.resultados.isNotEmpty) _buildUltimosResultados(partidos),
                    if (partidos.resultados.isNotEmpty) const SizedBox(height: 24),
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
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: isHovered ? AppColors.cardGradient : null,
                color: isHovered ? null : AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isHovered ? AppColors.gold.withOpacity(0.5) : AppColors.divider,
                  width: isHovered ? 1.0 : 0.5,
                ),
                boxShadow: isHovered ? AppColors.goldGlowSubtle : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: isHovered ? AppColors.maroonGradient : null,
                      color: isHovered ? null : AppColors.maroonDark,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isHovered ? [
                        BoxShadow(
                          color: AppColors.maroon.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: Icon(icon, color: AppColors.gold, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(label,
                      style: GoogleFonts.inter(
                          color: isHovered ? AppColors.gold : AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: isHovered ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        );
      },
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
          if (_mostrarAnotadores) _buildAnotadoresPanel()
          else SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedPartidoId == null
                  ? null
                  : () async {
                      // Cargar jugadores de ambos equipos
                      final p = partidos.partidos.firstWhere((x) => x.id == _selectedPartidoId);
                      final jugProv = context.read<JugadoresProvider>();
                      final local = await jugProv.fetchJugadoresPorEquipo(p.equipoLocalId);
                      final vis = await jugProv.fetchJugadoresPorEquipo(p.equipoVisitanteId);
                      setState(() {
                        _jugadoresLocal = local;
                        _jugadoresVisitante = vis;
                        _golesAnotadores = {};
                        _mostrarAnotadores = true;
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.maroon,
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text('SIGUIENTE → ANOTADORES'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnotadoresPanel() {
    final p = context.read<PartidosProvider>().partidos.firstWhere((x) => x.id == _selectedPartidoId);
    final totalAsigLocal = _jugadoresLocal.fold<int>(0, (s, j) => s + (_golesAnotadores[j.id] ?? 0));
    final totalAsigVis = _jugadoresVisitante.fold<int>(0, (s, j) => s + (_golesAnotadores[j.id] ?? 0));
    final valido = totalAsigLocal == _golesLocal && totalAsigVis == _golesVisitante;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ANOTADORES', style: GoogleFonts.inter(color: AppColors.gold, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Asigna los goles a cada jugador. Local: $totalAsigLocal/${_golesLocal} · Visitante: $totalAsigVis/${_golesVisitante}',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 12),
        // LOCAL
        Text(p.equipoLocalNombre ?? 'Local', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        ..._jugadoresLocal.map((j) => _anotadorRow(j, _golesLocal - (totalAsigLocal - (_golesAnotadores[j.id] ?? 0)))),
        const SizedBox(height: 12),
        // VISITANTE
        Text(p.equipoVisitanteNombre ?? 'Visitante', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        ..._jugadoresVisitante.map((j) => _anotadorRow(j, _golesVisitante - (totalAsigVis - (_golesAnotadores[j.id] ?? 0)))),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _mostrarAnotadores = false),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.divider)),
              child: Text('ATRÁS', style: GoogleFonts.inter(color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: !valido ? null : () async {
                final prov = context.read<PartidosProvider>();
                final jugProv = context.read<JugadoresProvider>();
                final ok = await prov.registrarResultado(_selectedPartidoId!, _golesLocal, _golesVisitante);
                if (ok) {
                  for (final entry in _golesAnotadores.entries) {
                    if (entry.value > 0) await jugProv.sumarGoles(entry.key, entry.value);
                  }
                  // Sumar partidos a todos los jugadores participantes
                  for (final j in [..._jugadoresLocal, ..._jugadoresVisitante]) {
                    await jugProv.sumarPartidos(j.id, 1);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resultado y anotadores guardados ✅'), backgroundColor: AppColors.success));
                    setState(() { _selectedPartidoId = null; _golesLocal = 0; _golesVisitante = 0; _mostrarAnotadores = false; _golesAnotadores = {}; });
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: AppColors.bgDark),
              child: Text('GUARDAR', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _anotadorRow(Jugador j, int maxDisponible) {
    final asignados = _golesAnotadores[j.id] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text('#${j.numero} ${j.nombre}', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13), overflow: TextOverflow.ellipsis)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary, size: 20),
            onPressed: asignados <= 0 ? null : () => setState(() => _golesAnotadores[j.id] = asignados - 1),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: AppColors.bgCardLight, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text('$asignados', style: GoogleFonts.inter(color: asignados > 0 ? AppColors.gold : AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 14))),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.gold, size: 20),
            onPressed: asignados >= maxDisponible + asignados || maxDisponible <= 0 ? null : () => setState(() => _golesAnotadores[j.id] = asignados + 1),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _showEditarPartido(BuildContext context, Partido p) {
    int gl = p.golesLocal ?? 0;
    int gv = p.golesVisitante ?? 0;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('Editar Resultado', style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${p.equipoLocalNombre ?? "Local"} vs ${p.equipoVisitanteNombre ?? "Visitante"}',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _editScoreBox(gl, () => setS(() => gl++), () { if (gl > 0) setS(() => gl--); }),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(':', style: GoogleFonts.inter(color: AppColors.gold, fontSize: 28, fontWeight: FontWeight.w700))),
                  _editScoreBox(gv, () => setS(() => gv++), () { if (gv > 0) setS(() => gv--); }),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (gl > 0 || gv > 0) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogCtx) => AnotadoresDialog(
                      equipoLocalId: p.equipoLocalId,
                      equipoVisitanteId: p.equipoVisitanteId,
                      equipoLocalNombre: p.equipoLocalNombre ?? 'Local',
                      equipoVisitanteNombre: p.equipoVisitanteNombre ?? 'Visitante',
                      golesLocal: gl,
                      golesVisitante: gv,
                      onSaved: (golesAnotadores, jugadoresLocal, jugadoresVisitante) async {
                        final prov = context.read<PartidosProvider>();
                        final jugProv = context.read<JugadoresProvider>();
                        final ok = await prov.editarPartido(p.id, {
                          'goles_local': gl,
                          'goles_visitante': gv,
                          'jugado': true,
                          'estado': 'finalizado',
                        });
                        if (ok) {
                          for (final entry in golesAnotadores.entries) {
                            if (entry.value > 0) {
                              await jugProv.sumarGoles(entry.key, entry.value);
                            }
                          }
                          if (!p.jugado) {
                            for (final j in [...jugadoresLocal, ...jugadoresVisitante]) {
                              await jugProv.sumarPartidos(j.id, 1);
                            }
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partido y anotadores actualizados ✅'), backgroundColor: AppColors.success));
                          }
                        }
                      },
                    ),
                  );
                } else {
                  final ok = await context.read<PartidosProvider>().editarPartido(p.id, {'goles_local': gl, 'goles_visitante': gv, 'jugado': true, 'estado': 'finalizado'});
                  if (ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partido actualizado ✅'), backgroundColor: AppColors.success));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.maroon),
              child: const Text('ACTUALIZAR'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editScoreBox(int v, VoidCallback add, VoidCallback rem) {
    return Column(children: [
      GestureDetector(onTap: add, child: const Icon(Icons.add, color: AppColors.gold)),
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: AppColors.bgCardLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
        child: Center(child: Text('$v', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.w700))),
      ),
      GestureDetector(onTap: rem, child: const Icon(Icons.remove, color: AppColors.textSecondary)),
    ]);
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

  Widget _buildUltimosResultados(PartidosProvider partidos) {
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
          Row(children: [
            const Icon(Icons.history, color: AppColors.gold, size: 16),
            const SizedBox(width: 8),
            Text('ÚLTIMOS RESULTADOS', style: GoogleFonts.inter(color: AppColors.gold, fontSize: 13, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 12),
          ...partidos.resultados.take(3).map((p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: AppColors.bgCardLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
            child: Row(
              children: [
                Expanded(child: Text('${p.equipoLocalNombre ?? "L"} ${p.marcador} ${p.equipoVisitanteNombre ?? "V"}',
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.gold, size: 18),
                  tooltip: 'Editar resultado',
                  onPressed: () => _showEditarPartido(context, p),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          )),
        ],
      ),
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
