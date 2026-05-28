import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import 'liguilla_provider.dart';
import '../equipos/equipos_provider.dart';
import '../../models/liguilla_torneo.dart';

class AdminLiguillaScreen extends StatefulWidget {
  const AdminLiguillaScreen({super.key});

  @override
  State<AdminLiguillaScreen> createState() => _AdminLiguillaScreenState();
}

class _AdminLiguillaScreenState extends State<AdminLiguillaScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<LiguillaProvider>().fetchTorneoActivo();
      context.read<EquiposProvider>().fetchEquipos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final liguillaP = context.watch<LiguillaProvider>();
    final torneo = liguillaP.torneoActivo;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.maroonDark,
        title: Text('Gestión de Liguilla',
            style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
      ),
      body: liguillaP.loading && torneo == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTorneoSection(liguillaP, torneo),
                  const SizedBox(height: 24),
                  if (torneo != null) ...[
                    _buildEquiposSection(liguillaP, torneo),
                    const SizedBox(height: 24),
                    _buildPartidosSection(liguillaP, torneo),
                  ],
                ],
              ),
            ),
    );
  }

  // ─────────────── SECCIÓN 1: TORNEO ───────────────
  Widget _buildTorneoSection(LiguillaProvider p, LiguillaTorneo? torneo) {
    if (torneo == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            const Icon(CupertinoIcons.calendar_badge_plus, size: 48, color: AppColors.gold),
            const SizedBox(height: 16),
            Text('No hay torneo activo', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _mostrarCrearTorneoDialog(context, p),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.maroon,
                foregroundColor: Colors.white,
              ),
              child: const Text('Crear Nuevo Torneo'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        boxShadow: AppColors.goldGlowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TORNEO ACTIVO', style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text('EN CURSO', style: GoogleFonts.inter(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700)),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(torneo.nombre, style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          Text('Formato: ${torneo.numEquipos} equipos', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.bgCard,
                        title: const Text('¿Cerrar Torneo?', style: TextStyle(color: Colors.white)),
                        content: const Text('El torneo quedará guardado pero ya no será el activo.', style: TextStyle(color: AppColors.textSecondary)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cerrar Torneo', style: TextStyle(color: AppColors.error))),
                        ],
                      ),
                    );
                    if (confirm == true) await p.cerrarTorneo();
                  },
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                  child: const Text('Cerrar Torneo', style: TextStyle(color: AppColors.error)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _mostrarCrearTorneoDialog(BuildContext context, LiguillaProvider p) {
    final ctrl = TextEditingController(text: 'Liguilla ${DateTime.now().year}');
    int numEquipos = 4;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('Nuevo Torneo', style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nombre del Torneo',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Formato', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: numEquipos,
                dropdownColor: AppColors.bgDark,
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
                ),
                items: const [
                  DropdownMenuItem(value: 2, child: Text('🥊 2 Equipos (Final Directa)', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 4, child: Text('🏆 4 Equipos (Semifinales)', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 8, child: Text('🏟️ 8 Equipos (Cuartos)', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 16, child: Text('🌎 16 Equipos (Octavos)', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (v) => setS(() => numEquipos = v!),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await p.crearTorneo(ctrl.text.trim(), numEquipos);
                if (mounted) {
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Torneo creado'), backgroundColor: AppColors.success));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(p.error ?? 'Error desconocido al crear torneo'), backgroundColor: AppColors.error));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
              child: const Text('Crear', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── SECCIÓN 2: EQUIPOS ───────────────
  Widget _buildEquiposSection(LiguillaProvider p, LiguillaTorneo torneo) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('EQUIPOS CLASIFICADOS', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.5)),
                Text('${p.equipos.length} / ${torneo.numEquipos}', style: GoogleFonts.inter(color: p.equipos.length == torneo.numEquipos ? AppColors.success : AppColors.gold, fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          if (p.equipos.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('Ningún equipo registrado', style: GoogleFonts.inter(color: AppColors.textTertiary))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: p.equipos.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (ctx, i) {
                final eq = p.equipos[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                    child: Text('${eq.seed}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(eq.nombreEquipo ?? 'Desconocido', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  trailing: IconButton(
                    icon: const Icon(CupertinoIcons.trash, color: AppColors.error, size: 20),
                    onPressed: () => p.quitarEquipo(eq.id),
                  ),
                );
              },
            ),
          if (p.equipos.length < torneo.numEquipos)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _mostrarAgregarEquipoDialog(context, p, p.equipos.length + 1),
                  icon: const Icon(CupertinoIcons.add),
                  label: const Text('Agregar Equipo'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.gold, side: const BorderSide(color: AppColors.gold)),
                ),
              ),
            ),
          if (p.equipos.length == torneo.numEquipos && p.partidos.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await p.generarBracket();
                    if (ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bracket generado. ¡Todo listo!'), backgroundColor: AppColors.success));
                  },
                  icon: const Icon(CupertinoIcons.arrow_merge),
                  label: const Text('Generar Bracket de Partidos'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _mostrarAgregarEquipoDialog(BuildContext context, LiguillaProvider p, int recommendedSeed) {
    final eqProv = context.read<EquiposProvider>();
    String? equipoSelId;
    int seed = recommendedSeed;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('Agregar a Liguilla', style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seleccionar Equipo', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: equipoSelId,
                dropdownColor: AppColors.bgDark,
                isExpanded: true,
                hint: const Text('Elige un equipo', style: TextStyle(color: AppColors.textTertiary)),
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
                ),
                items: eqProv.equipos.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nombre, style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => setS(() => equipoSelId = v),
              ),
              const SizedBox(height: 16),
              Text('Seed (Posición en tabla)', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: seed,
                dropdownColor: AppColors.bgDark,
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
                ),
                items: List.generate(p.torneoActivo!.numEquipos, (i) => i + 1).map((e) => DropdownMenuItem(value: e, child: Text('$e° Lugar', style: const TextStyle(color: Colors.white)))).toList(),
                onChanged: (v) => setS(() => seed = v!),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
            ElevatedButton(
              onPressed: equipoSelId == null ? null : () async {
                Navigator.pop(ctx);
                final ok = await p.agregarEquipo(equipoSelId!, seed);
                if (ok && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Equipo añadido'), backgroundColor: AppColors.success));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
              child: const Text('Añadir', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── SECCIÓN 3: PARTIDOS ───────────────
  Widget _buildPartidosSection(LiguillaProvider p, LiguillaTorneo torneo) {
    if (p.partidos.isEmpty) return const SizedBox();

    // Agrupar por ronda
    final rondasNombres = ['OCTAVOS', 'CUARTOS', 'SEMIFINALES', 'FINAL'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GESTIÓN DE PARTIDOS', style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        ...rondasNombres.map((r) {
          final parts = p.getPartidosPorRonda(r);
          if (parts.isEmpty) return const SizedBox();
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.maroonDark, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                  child: Text(r, style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w800)),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: parts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (ctx, i) {
                    final pt = parts[i];
                    return ListTile(
                      title: Text('${pt.equipoLocalNombre ?? "Por definir"} vs ${pt.equipoVisitanteNombre ?? "Por definir"}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text(pt.jugado ? 'Finalizado: ${pt.golesLocal} - ${pt.golesVisitante}' : 'Fecha: ${pt.fecha?.toIso8601String().split('T')[0] ?? "Pendiente"} | ${pt.hora}', style: TextStyle(color: pt.jugado ? AppColors.gold : AppColors.textTertiary)),
                      trailing: pt.jugado ? const Icon(CupertinoIcons.checkmark_seal_fill, color: AppColors.success) : IconButton(
                        icon: const Icon(CupertinoIcons.pencil_ellipsis_rectangle, color: AppColors.gold),
                        onPressed: () => _mostrarEditarPartidoDialog(context, p, pt),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _mostrarEditarPartidoDialog(BuildContext context, LiguillaProvider p, LiguillaPartido pt) {
    if (pt.equipoLocalId == null || pt.equipoVisitanteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aún faltan equipos por definir en esta llave')));
      return;
    }

    final fechaCtrl = TextEditingController(text: pt.fecha?.toIso8601String().split('T')[0] ?? '');
    final horaCtrl = TextEditingController(text: pt.hora);
    final lugarCtrl = TextEditingController(text: pt.lugar ?? '');
    
    int gl = pt.golesLocal ?? 0;
    int gv = pt.golesVisitante ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text('Editar Partido', style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${pt.equipoLocalNombre} vs ${pt.equipoVisitanteNombre}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextField(controller: fechaCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Fecha (YYYY-MM-DD)', labelStyle: TextStyle(color: AppColors.textSecondary))),
                TextField(controller: horaCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Hora', labelStyle: TextStyle(color: AppColors.textSecondary))),
                TextField(controller: lugarCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Lugar', labelStyle: TextStyle(color: AppColors.textSecondary))),
                const SizedBox(height: 24),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 16),
                Text('Resultado (si ya se jugó)', style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _editScoreBox('${pt.equipoLocalNombre?.substring(0,3)}', gl, () => setS(() => gl++), () { if(gl>0) setS(()=>gl--); }),
                    const Text(':', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    _editScoreBox('${pt.equipoVisitanteNombre?.substring(0,3)}', gv, () => setS(() => gv++), () { if(gv>0) setS(()=>gv--); }),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary))),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await p.editarPartido(pt.id, {
                  'fecha': fechaCtrl.text.isEmpty ? null : fechaCtrl.text,
                  'hora': horaCtrl.text,
                  'lugar': lugarCtrl.text,
                });
                if (gl > 0 || gv > 0) {
                  // Registrar resultado avanza el bracket
                  await p.registrarResultado(pt.id, gl, gv);
                }
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partido actualizado'), backgroundColor: AppColors.success));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editScoreBox(String lbl, int v, VoidCallback add, VoidCallback rem) {
    return Column(children: [
      Text(lbl.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      const SizedBox(height: 8),
      GestureDetector(onTap: add, child: const Icon(Icons.add, color: AppColors.gold)),
      Container(
        width: 48, height: 48, margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: AppColors.bgCardLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
        child: Center(child: Text('$v', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700))),
      ),
      GestureDetector(onTap: rem, child: const Icon(Icons.remove, color: AppColors.textSecondary)),
    ]);
  }
}
