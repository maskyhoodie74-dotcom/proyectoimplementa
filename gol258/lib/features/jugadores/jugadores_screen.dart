import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              ? Center(
                  child: Text(
                    'Sin jugadores registrados',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 18),
                  ),
                )
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
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.maroonDark,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                                ),
                                child: Center(
                                  child: Text(
                                    '#${j.numero}',
                                    style: GoogleFonts.inter(
                                        color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              title: Text(
                                j.nombre,
                                style: GoogleFonts.inter(
                                    color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${j.equipoNombre ?? "Sin equipo"} • ${j.posicion ?? "Jugador"}\n⚽ ${j.goles} goles  🎯 ${j.asistencias} asist.',
                                style: GoogleFonts.inter(
                                    color: AppColors.textSecondary, fontSize: 11, height: 1.5),
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

// ─────────────────────────────────────────────
// FORM SHEET
// ─────────────────────────────────────────────

class _JugadorFormSheet extends StatefulWidget {
  final Jugador? jugador;
  const _JugadorFormSheet({this.jugador});
  @override
  State<_JugadorFormSheet> createState() => _JugadorFormSheetState();
}

class _JugadorFormSheetState extends State<_JugadorFormSheet> {
  final _nombreCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String? _equipoId;
  String _posicion = 'Delantero';
  bool _saving = false;
  String? _errorMsg;

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
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // Dominios de correo permitidos
  static const _dominiosPermitidos = [
    '@gmail.com',
    '@hotmail.com',
    '@yahoo.com',
    '@cbtis258.edu.mx',
  ];

  String? _validarCorreo(String correo) {
    if (correo.isEmpty) return null; // vacío = autogenerar
    if (correo.length > 254) {
      return 'El correo no puede superar los 254 caracteres.';
    }
    if (!correo.contains('@')) {
      return 'El correo debe contener @.';
    }
    final partes = correo.split('@');
    if (partes.length != 2 || partes[0].isEmpty || partes[1].isEmpty) {
      return 'Formato de correo inválido.';
    }
    final dominioAceptado = _dominiosPermitidos.any(
      (d) => correo.toLowerCase().endsWith(d),
    );
    if (!dominioAceptado) {
      return 'Solo se permiten correos:\n@gmail.com  @hotmail.com\n@yahoo.com  @cbtis258.edu.mx';
    }
    // Validar que el usuario antes del @ no esté vacío
    final usuario = partes[0];
    if (usuario.length < 2) {
      return 'El nombre de usuario del correo es demasiado corto.';
    }
    return null; // válido
  }

  String? _validarContrasena(String pass) {
    if (pass.isEmpty) return null; // vacío = autogenerar
    if (pass.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (pass.length > 30) {
      return 'La contraseña no puede superar los 30 caracteres.';
    }
    return null;
  }

  Future<void> _save() async {
    setState(() => _errorMsg = null);

    // Validar nombre
    if (_nombreCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'El nombre del jugador es obligatorio.');
      return;
    }
    if (_nombreCtrl.text.trim().length > 60) {
      setState(() => _errorMsg = 'El nombre no puede superar los 60 caracteres.');
      return;
    }

    // Validar equipo
    if (_equipoId == null) {
      setState(() => _errorMsg = 'Debes seleccionar un equipo.');
      return;
    }

    // Validar credenciales solo al crear
    if (widget.jugador == null) {
      final emailError = _validarCorreo(_emailCtrl.text.trim());
      if (emailError != null) {
        setState(() => _errorMsg = emailError);
        return;
      }
      final passError = _validarContrasena(_passCtrl.text.trim());
      if (passError != null) {
        setState(() => _errorMsg = passError);
        return;
      }
    }

    setState(() => _saving = true);

    final data = {
      'nombre_jugador': _nombreCtrl.text.trim(),
      'numero': int.tryParse(_numeroCtrl.text) ?? 0,
      'equipo_id': _equipoId,
      'posicion': _posicion,
    };

    try {
      if (widget.jugador != null) {
        // Editar jugador existente
        final ok = await context.read<JugadoresProvider>().editarJugador(widget.jugador!.id, data);
        if (mounted) {
          if (ok) {
            Navigator.pop(context);
          } else {
            setState(() {
              _errorMsg = context.read<JugadoresProvider>().error ?? 'Error al actualizar el jugador.';
            });
          }
        }
      } else {
        // Crear nuevo jugador con credenciales opcionales
        final creds = await context.read<JugadoresProvider>().crearJugador(
          data,
          correoPersonalizado: _emailCtrl.text.trim(),
          contrasenaPersonalizada: _passCtrl.text.trim(),
        );
        if (mounted) {
          if (creds != null) {
            Navigator.pop(context);
            _mostrarDialogoCredenciales(creds['correo']!, creds['contrasena']!);
          } else {
            setState(() {
              _errorMsg = context.read<JugadoresProvider>().error ?? 'Error al crear el jugador.';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _mostrarDialogoCredenciales(String correo, String contrasena) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Text('✅ ', style: TextStyle(fontSize: 20)),
          Text('JUGADOR REGISTRADO',
              style: GoogleFonts.inter(
                  color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w800)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparte estas credenciales con el jugador.\nDebe usar la pestaña "JUGADOR" para iniciar sesión.',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 16),
            _credRow(ctx, 'CORREO', correo),
            const SizedBox(height: 10),
            _credRow(ctx, 'CONTRASEÑA', contrasena),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: 'Correo: $correo\nContraseña: $contrasena'));
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text('¡Credenciales copiadas!',
                      style: GoogleFonts.inter(color: AppColors.textPrimary)),
                  backgroundColor: AppColors.maroonDark,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text('COPIAR TODO',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ENTENDIDO',
                style: GoogleFonts.inter(
                    color: AppColors.gold, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _credRow(BuildContext ctx, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            SelectableText(value,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.copy_outlined, color: AppColors.textSecondary, size: 18),
          tooltip: 'Copiar',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text('$label copiado',
                    style: GoogleFonts.inter(color: AppColors.textPrimary)),
                backgroundColor: AppColors.maroonDark,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final equipos = context.watch<EquiposProvider>().equipos;
    final isEditing = widget.jugador != null;

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
            // Handle bar
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),

            // Título
            Text(
              isEditing ? 'EDITAR JUGADOR' : 'REGISTRAR JUGADOR',
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // Error message
            if (_errorMsg != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withOpacity(0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMsg!,
                        style: GoogleFonts.inter(color: AppColors.error, fontSize: 12)),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // NOMBRE
            Text('NOMBRE *',
                style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nombreCtrl,
              maxLength: 60,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                  hintText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                  counterText: ''),
            ),
            const SizedBox(height: 16),

            // NÚMERO Y POSICIÓN
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('# NÚMERO',
                      style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _numeroCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                    decoration: const InputDecoration(hintText: '10'),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('POSICIÓN',
                      style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.bgCardLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider)),
                    child: DropdownButton<String>(
                      value: _posicion,
                      isExpanded: true,
                      dropdownColor: AppColors.bgCard,
                      underline: const SizedBox(),
                      items: _posiciones
                          .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p,
                                  style: GoogleFonts.inter(
                                      color: AppColors.textPrimary, fontSize: 12))))
                          .toList(),
                      onChanged: (v) => setState(() => _posicion = v!),
                    ),
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 16),

            // EQUIPO
            Text('EQUIPO *',
                style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.bgCardLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _equipoId == null && _errorMsg != null
                          ? AppColors.error
                          : AppColors.divider)),
              child: DropdownButton<String>(
                value: _equipoId,
                isExpanded: true,
                dropdownColor: AppColors.bgCard,
                underline: const SizedBox(),
                hint: Text('Seleccionar equipo',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
                items: equipos
                    .map((e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.nombre,
                            style:
                                GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14))))
                    .toList(),
                onChanged: (v) => setState(() => _equipoId = v),
              ),
            ),

            // CREDENCIALES OPCIONALES (solo al crear)
            if (!isEditing) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.maroonDark.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withOpacity(0.2)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.key_outlined, color: AppColors.gold, size: 15),
                    const SizedBox(width: 6),
                    Text('CREDENCIALES DE ACCESO',
                        style: GoogleFonts.inter(
                            color: AppColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                  ]),
                  const SizedBox(height: 4),
                  Text('Opcional — si los dejas vacíos se generan automáticamente.',
                      style:
                          GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 12),
                  Text('CORREO',
                      style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 254,
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'usuario@gmail.com / @hotmail.com / @yahoo.com / @cbtis258.edu.mx',
                      prefixIcon: Icon(Icons.email_outlined, size: 16),
                      isDense: true,
                      counterText: '',
                      helperText: 'Solo: @gmail.com · @hotmail.com · @yahoo.com · @cbtis258.edu.mx',
                      helperStyle: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('CONTRASEÑA',
                      style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passCtrl,
                    maxLength: 30,
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Entre 6 y 30 caracteres',
                      prefixIcon: Icon(Icons.lock_outline, size: 16),
                      isDense: true,
                      counterText: '',
                      helperText: 'Mínimo 6 · Máximo 30 caracteres',
                      helperStyle: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 24),

            // Botón guardar
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
                    : Text(isEditing ? 'ACTUALIZAR' : 'REGISTRAR JUGADOR'),
              ),
            ),
            const SizedBox(height: 12),

            // Botón cancelar
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
                    style:
                        GoogleFonts.inter(color: AppColors.textPrimary, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
