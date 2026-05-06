import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../equipos/equipos_provider.dart';
import '../../core/theme.dart';
import '../../models/equipo.dart';
import '../auth/auth_provider.dart';

class EquiposScreen extends StatefulWidget {
  const EquiposScreen({super.key});
  @override
  State<EquiposScreen> createState() => _EquiposScreenState();
}

class _EquiposScreenState extends State<EquiposScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<EquiposProvider>().fetchEquipos());
  }

  void _showForm({Equipo? equipo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EquipoFormSheet(equipo: equipo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final equipos = context.watch<EquiposProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.bgDark,
              tooltip: 'Agregar Equipo',
              onPressed: () => _showForm(),
              child: const Icon(Icons.add),
            )
          : null,
      body: equipos.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : equipos.equipos.isEmpty
              ? Center(
                  child: Text('Sin equipos registrados',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 18)))
              : RefreshIndicator(
                  color: AppColors.gold,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: () => equipos.fetchEquipos(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: equipos.equipos.length,
                        itemBuilder: (_, i) {
                          final eq = equipos.equipos[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.maroonDark,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                                ),
                                child: Center(
                                  child: Text(
                                    eq.nombre.isNotEmpty ? eq.nombre[0].toUpperCase() : '?',
                                    style: GoogleFonts.inter(
                                        color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              title: Text(eq.nombre,
                                  style: GoogleFonts.inter(
                                      color: AppColors.textPrimary, fontSize: 16)),
                              subtitle: Text('${eq.categoria ?? "Sin categoría"} • DT: ${eq.entrenador ?? "N/A"}',
                                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                              trailing: isAdmin
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              color: AppColors.textSecondary, size: 18),
                                          onPressed: () => _showForm(equipo: eq),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: AppColors.error, size: 18),
                                          onPressed: () async {
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                backgroundColor: AppColors.bgCard,
                                                title: Text('Eliminar equipo',
                                                    style: GoogleFonts.inter(color: AppColors.textPrimary)),
                                                content: Text('¿Eliminar "${eq.nombre}"?',
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
                                              await context.read<EquiposProvider>().eliminarEquipo(eq.id);
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

class _EquipoFormSheet extends StatefulWidget {
  final Equipo? equipo;
  const _EquipoFormSheet({this.equipo});
  @override
  State<_EquipoFormSheet> createState() => _EquipoFormSheetState();
}

class _EquipoFormSheetState extends State<_EquipoFormSheet> {
  final _nombreCtrl = TextEditingController();
  final _entrenadorCtrl = TextEditingController();
  String _categoria = 'Varonil';
  bool _saving = false;
  final _categorias = ['Varonil', 'Femenil', 'Mixto', 'Juvenil', 'División I'];

  @override
  void initState() {
    super.initState();
    if (widget.equipo != null) {
      _nombreCtrl.text = widget.equipo!.nombre;
      _entrenadorCtrl.text = widget.equipo!.entrenador ?? '';
      _categoria = widget.equipo!.categoria ?? 'Varonil';
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _entrenadorCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final data = {
      'nombre_equipo': _nombreCtrl.text.trim(),
      'categoria': _categoria,
      'entrenador': _entrenadorCtrl.text.trim().isEmpty ? null : _entrenadorCtrl.text.trim(),
    };
    
    if (widget.equipo != null) {
      final ok = await context.read<EquiposProvider>().editarEquipo(widget.equipo!.id, data);
      if (ok && mounted) Navigator.pop(context);
    } else {
      final creds = await context.read<EquiposProvider>().crearEquipo(data);
      if (creds != null && mounted) {
        Navigator.pop(context); // close sheet
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.bgCard,
            title: Text('CUENTA DE EQUIPO CREADA', style: GoogleFonts.inter(color: AppColors.gold)),
            content: Text('Por favor, comparte estos accesos con el representante del equipo:\n\nUsuario: ${creds['correo']}\nClave: ${creds['contrasena']}', style: GoogleFonts.inter(color: AppColors.textPrimary)),
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
            Row(children: [
              Container(width: 3, height: 36, color: AppColors.gold, margin: const EdgeInsets.only(right: 12)),
              Text(widget.equipo != null ? 'EDITAR EQUIPO' : 'REGISTRO DE EQUIPO',
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
            Text('Completa los datos técnicos de la escuadra',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            Text('NOMBRE DEL EQUIPO',
                style: GoogleFonts.inter(color: AppColors.gold, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: _nombreCtrl,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Ej. Cobras FC')),
            const SizedBox(height: 16),
            Text('CATEGORÍA',
                style: GoogleFonts.inter(color: AppColors.gold, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider)),
              child: DropdownButton<String>(
                value: _categoria, isExpanded: true, dropdownColor: AppColors.bgCard, underline: const SizedBox(),
                items: _categorias.map((c) => DropdownMenuItem(value: c,
                    child: Text(c, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _categoria = v!),
              ),
            ),
            const SizedBox(height: 16),
            Text('NOMBRE DEL ENTRENADOR',
                style: GoogleFonts.inter(color: AppColors.gold, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: _entrenadorCtrl,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Nombre completo')),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.bgDark, strokeWidth: 2))
                      : Text(widget.equipo != null ? 'ACTUALIZAR EQUIPO' : 'REGISTRAR EQUIPO'),
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
