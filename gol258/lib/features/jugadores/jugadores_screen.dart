import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../jugadores/jugadores_provider.dart';
import '../equipos/equipos_provider.dart';
import '../auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../models/jugador.dart';

class JugadoresScreen extends StatefulWidget {
  const JugadoresScreen({super.key});
  @override
  State<JugadoresScreen> createState() => _JugadoresScreenState();
}

class _JugadoresScreenState extends State<JugadoresScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<JugadoresProvider>().fetchJugadores();
      context.read<EquiposProvider>().fetchEquipos();
    });
  }

  void _showForm({Jugador? jugador}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JugadorFormSheet(jugador: jugador),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jugadores = context.watch<JugadoresProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.bgDark,
              tooltip: 'Agregar Jugador',
              onPressed: () => _showForm(),
              child: const Icon(Icons.person_add),
            )
          : null,
      body: jugadores.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : jugadores.jugadores.isEmpty
              ? Center(child: Text('Sin jugadores registrados',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 18)))
              : RefreshIndicator(
                  color: AppColors.gold,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: () => jugadores.fetchJugadores(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: jugadores.jugadores.length,
                        itemBuilder: (_, i) {
                          final j = jugadores.jugadores[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.maroonDark,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                                ),
                                child: Center(
                                  child: Text('#${j.numero}',
                                      style: GoogleFonts.inter(
                                          color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w700)),
                                ),
                              ),
                              title: Text(j.nombre,
                                  style: GoogleFonts.inter(
                                      color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text(
                                '${j.equipoNombre ?? "Sin equipo"} • ${j.posicion ?? "Jugador"}\n⚽ ${j.goles} goles  🎯 ${j.asistencias} asist.',
                                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, height: 1.5),
                              ),
                              isThreeLine: true,
                              trailing: isAdmin
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              color: AppColors.textSecondary, size: 18),
                                          onPressed: () => _showForm(jugador: j),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: AppColors.error, size: 18),
                                          onPressed: () async {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                backgroundColor: AppColors.bgCard,
                                                title: Text('Eliminar jugador',
                                                    style: GoogleFonts.inter(color: AppColors.textPrimary)),
                                                content: Text('¿Eliminar "${j.nombre}"?',
                                                    style: GoogleFonts.inter(color: AppColors.textSecondary)),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx, false),
                                                      child: const Text('Cancelar')),
                                                  TextButton(onPressed: () => Navigator.pop(ctx, true),
                                                      child: const Text('Eliminar',
                                                          style: TextStyle(color: AppColors.error))),
                                                ],
                                              ),
                                            );
                                            if (ok == true && mounted) {
                                              await context.read<JugadoresProvider>().eliminarJugador(j.id);
                                            }
                                          },
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
    );
  }
}

class _JugadorFormSheet extends StatefulWidget {
  final Jugador? jugador;
  const _JugadorFormSheet({this.jugador});
  @override
  State<_JugadorFormSheet> createState() => _JugadorFormSheetState();
}

class _JugadorFormSheetState extends State<_JugadorFormSheet> {
  final _nombreCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  String? _equipoId;
  String _posicion = 'Delantero';
  bool _saving = false;
  final _posiciones = ['Portero', 'Defensa', 'Mediocampista', 'Delantero'];

  @override
  void initState() {
    super.initState();
    if (widget.jugador != null) {
      _nombreCtrl.text = widget.jugador!.nombre;
      _numeroCtrl.text = widget.jugador!.numero.toString();
      _equipoId = widget.jugador!.equipoId;
      _posicion = widget.jugador!.posicion ?? 'Delantero';
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _numeroCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nombreCtrl.text.trim().isEmpty || _equipoId == null) return;
    setState(() => _saving = true);
    final data = {
      'nombre_jugador': _nombreCtrl.text.trim(),
      'numero': int.tryParse(_numeroCtrl.text) ?? 0,
      'equipo_id': _equipoId,
      'posicion': _posicion,
    };
    
    if (widget.jugador != null) {
      final ok = await context.read<JugadoresProvider>().editarJugador(widget.jugador!.id, data);
      if (ok && mounted) Navigator.pop(context);
    } else {
      final creds = await context.read<JugadoresProvider>().crearJugador(data);
      if (creds != null && mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.bgCard,
            title: Text('CUENTA DE JUGADOR CREADA', style: GoogleFonts.inter(color: AppColors.gold)),
            content: Text('Por favor, comparte estos accesos con el jugador:\n\nUsuario: ${creds['correo']}\nClave: ${creds['contrasena']}', style: GoogleFonts.inter(color: AppColors.textPrimary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ENTENDIDO', style: TextStyle(color: AppColors.gold))),
            ],
          ),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final equipos = context.watch<EquiposProvider>().equipos;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(widget.jugador != null ? 'EDITAR JUGADOR' : 'REGISTRAR JUGADOR',
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Text('NOMBRE', style: GoogleFonts.inter(color: AppColors.gold, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: _nombreCtrl,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Nombre completo')),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('# NÚMERO', style: GoogleFonts.inter(color: AppColors.gold, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(controller: _numeroCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                    decoration: const InputDecoration(hintText: '10')),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('POSICIÓN', style: GoogleFonts.inter(color: AppColors.gold, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.bgCardLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider)),
                  child: DropdownButton<String>(
                    value: _posicion, isExpanded: true, dropdownColor: AppColors.bgCard, underline: const SizedBox(),
                    items: _posiciones.map((p) => DropdownMenuItem(value: p,
                        child: Text(p, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12)))).toList(),
                    onChanged: (v) => setState(() => _posicion = v!),
                  ),
                ),
              ])),
            ]),
            const SizedBox(height: 16),
            Text('EQUIPO', style: GoogleFonts.inter(color: AppColors.gold, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider)),
              child: DropdownButton<String>(
                value: _equipoId, isExpanded: true, dropdownColor: AppColors.bgCard, underline: const SizedBox(),
                hint: Text('Seleccionar equipo', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
                items: equipos.map((e) => DropdownMenuItem(value: e.id,
                    child: Text(e.nombre, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _equipoId = v),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.bgDark, strokeWidth: 2))
                      : Text(widget.jugador != null ? 'ACTUALIZAR' : 'REGISTRAR JUGADOR'),
                )),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.maroon),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('CANCELAR', style: GoogleFonts.inter(color: AppColors.textPrimary, letterSpacing: 1.5)),
                )),
          ],
        ),
      ),
    );
  }
}
