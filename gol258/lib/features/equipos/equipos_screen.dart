import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../equipos/equipos_provider.dart';
import '../../core/theme.dart';
import '../../models/equipo.dart';
import '../auth/auth_provider.dart';
import 'equipo_detalle_screen.dart';

class EquiposScreen extends StatefulWidget {
  const EquiposScreen({super.key});
  @override
  State<EquiposScreen> createState() => _EquiposScreenState();
}

class _EquiposScreenState extends State<EquiposScreen> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<EquiposProvider>().fetchEquipos());

    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim().toLowerCase();
      setState(() {
        _query = q;
        _showSuggestions = q.isNotEmpty;
      });
    });

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      } else if (_query.isNotEmpty) {
        setState(() => _showSuggestions = true);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showForm({Equipo? equipo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EquipoFormSheet(equipo: equipo),
    );
  }

  void _selectEquipo(Equipo eq) {
    // Cerrar teclado y sugerencias
    _focusNode.unfocus();
    setState(() => _showSuggestions = false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _DetalleWrapper(equipo: eq),
      ),
    );
  }

  void _onSubmit() {
    // Al presionar Enter: seleccionar la primera sugerencia si existe
    final equipos = context.read<EquiposProvider>().equipos;
    final matches = _query.isEmpty
        ? <Equipo>[]
        : equipos
            .where((e) => e.nombre.toLowerCase().contains(_query))
            .toList();
    if (matches.isNotEmpty) _selectEquipo(matches.first);
  }

  @override
  Widget build(BuildContext context) {
    final equipos = context.watch<EquiposProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    final suggestions = _query.isEmpty
        ? <Equipo>[]
        : equipos.equipos
            .where((e) => e.nombre.toLowerCase().contains(_query))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.bgDark,
              tooltip: 'Agregar Equipo',
              onPressed: () => _showForm(),
              child: const Icon(Icons.add),
            )
          : null,
      body: GestureDetector(
        // Cerrar sugerencias al tocar fuera
        onTap: () {
          _focusNode.unfocus();
          setState(() => _showSuggestions = false);
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            // ─── Barra de búsqueda ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BUSCAR EQUIPO',
                    style: GoogleFonts.inter(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchCtrl,
                    focusNode: _focusNode,
                    onSubmitted: (_) => _onSubmit(),
                    style: GoogleFonts.inter(
                        color: AppColors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Escribe el nombre del equipo…',
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textSecondary, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: AppColors.textSecondary,
                                  size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _focusNode.requestFocus();
                              },
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Contenido Principal con Sugerencias Flotantes ──────────
            Expanded(
              child: Stack(
                children: [
                  // Estado vacío / instrucción
                  Positioned.fill(
                    child: _buildEmptyPrompt(equipos.loading),
                  ),

                  // Dropdown de sugerencias (Flotante)
                  if (_showSuggestions)
                    Positioned(
                      top: 0,
                      left: 16,
                      right: 16,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 350),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard.withOpacity(0.98),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.gold.withOpacity(0.4), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: equipos.loading
                                ? const Padding(
                                    padding: EdgeInsets.all(40),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          color: AppColors.gold),
                                    ),
                                  )
                                : suggestions.isEmpty
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 30),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text('🔍',
                                                style: TextStyle(fontSize: 18)),
                                            const SizedBox(width: 10),
                                            Text(
                                              'No encontramos "$_query"',
                                              style: GoogleFonts.inter(
                                                color: AppColors.textSecondary,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        itemCount: suggestions.length,
                                        separatorBuilder: (_, __) => const Divider(
                                            height: 1,
                                            color: AppColors.divider,
                                            indent: 60),
                                        itemBuilder: (_, i) {
                                          final eq = suggestions[i];
                                          return _suggestionTile(eq);
                                        },
                                      ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionTile(Equipo eq) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectEquipo(eq),
        splashColor: AppColors.gold.withOpacity(0.08),
        highlightColor: AppColors.gold.withOpacity(0.04),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppColors.maroonGradient,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.gold.withOpacity(0.35), width: 1),
                ),
                child: eq.escudoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(eq.escudoUrl!,
                            fit: BoxFit.cover))
                    : Center(
                        child: Text(
                          eq.nombre.isNotEmpty
                              ? eq.nombre[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.inter(
                            color: AppColors.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Nombre y categoría
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eq.nombre,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${eq.categoria ?? "Sin categoría"} · ${eq.entrenador != null ? "DT: ${eq.entrenador}" : "Sin entrenador"}',
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Flecha
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.textTertiary, size: 13),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPrompt(bool loading) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.gold));
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.gold.withOpacity(0.2), width: 1.5),
            ),
            child: const Center(
              child: Text('🔍', style: TextStyle(fontSize: 38)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Busca un equipo',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escribe el nombre del equipo en el\nbuscador para ver su información.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          // Indicador de tip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: AppColors.gold, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Presiona Enter o selecciona para ver la ficha',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wrapper ─────────────────────────────────────────────────────────────────

class _DetalleWrapper extends StatelessWidget {
  final Equipo equipo;
  const _DetalleWrapper({required this.equipo});

  @override
  Widget build(BuildContext context) {
    return EquipoDetalleScreen(equipo: equipo);
  }
}

// ─── Form Sheet ───────────────────────────────────────────────────────────────

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
  final _categorias = [
    'Varonil',
    'Femenil',
    'Mixto',
    'Juvenil',
    'División I'
  ];

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
      'entrenador': _entrenadorCtrl.text.trim().isEmpty
          ? null
          : _entrenadorCtrl.text.trim(),
    };

    if (widget.equipo != null) {
      final ok = await context
          .read<EquiposProvider>()
          .editarEquipo(widget.equipo!.id, data);
      if (ok && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Equipo actualizado correctamente')),
        );
      }
    } else {
      final creds =
          await context.read<EquiposProvider>().crearEquipo(data);
      if (creds != null && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ ¡Equipo creado exitosamente!')),
        );
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.bgCard,
            title: Text('CUENTA DE EQUIPO CREADA',
                style: GoogleFonts.inter(color: AppColors.gold)),
            content: Text(
                'Comparte estos accesos con el representante:\n\nUsuario: ${creds['correo']}\nClave: ${creds['contrasena']}',
                style:
                    GoogleFonts.inter(color: AppColors.textPrimary)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ENTENDIDO',
                      style: TextStyle(color: AppColors.gold))),
            ],
          ),
        );
      } else if (mounted) {
        final errorMsg = context.read<EquiposProvider>().error ?? 'Error al crear equipo';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $errorMsg'), backgroundColor: Colors.red),
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
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                  width: 3,
                  height: 36,
                  color: AppColors.gold,
                  margin: const EdgeInsets.only(right: 12)),
              Text(
                  widget.equipo != null
                      ? 'EDITAR EQUIPO'
                      : 'REGISTRO DE EQUIPO',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
            Text('Completa los datos técnicos de la escuadra',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            Text('NOMBRE DEL EQUIPO',
                style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
                controller: _nombreCtrl,
                style:
                    GoogleFonts.inter(color: AppColors.textPrimary),
                decoration:
                    const InputDecoration(hintText: 'Ej. Cobras FC')),
            const SizedBox(height: 16),
            Text('CATEGORÍA',
                style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider)),
              child: DropdownButton<String>(
                value: _categoria,
                isExpanded: true,
                dropdownColor: AppColors.bgCard,
                underline: const SizedBox(),
                items: _categorias
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c,
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 14))))
                    .toList(),
                onChanged: (v) => setState(() => _categoria = v!),
              ),
            ),
            const SizedBox(height: 16),
            Text('NOMBRE DEL ENTRENADOR',
                style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
                controller: _entrenadorCtrl,
                style:
                    GoogleFonts.inter(color: AppColors.textPrimary),
                decoration:
                    const InputDecoration(hintText: 'Nombre completo')),
            const SizedBox(height: 24),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: AppColors.bgDark, strokeWidth: 2))
                      : Text(widget.equipo != null
                          ? 'ACTUALIZAR EQUIPO'
                          : 'REGISTRAR EQUIPO'),
                )),
            const SizedBox(height: 12),
            SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.maroon),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text('CANCELAR',
                      style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          letterSpacing: 1.5)),
                )),
          ],
        ),
      ),
    );
  }
}
