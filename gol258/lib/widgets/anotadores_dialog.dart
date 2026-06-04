import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../features/jugadores/jugadores_provider.dart';
import '../models/jugador.dart';

class AnotadoresDialog extends StatefulWidget {
  final String equipoLocalId;
  final String equipoVisitanteId;
  final String equipoLocalNombre;
  final String equipoVisitanteNombre;
  final int golesLocal;
  final int golesVisitante;
  final Function(Map<String, int> golesAnotadores, List<Jugador> jugadoresLocal, List<Jugador> jugadoresVisitante) onSaved;

  const AnotadoresDialog({
    super.key,
    required this.equipoLocalId,
    required this.equipoVisitanteId,
    required this.equipoLocalNombre,
    required this.equipoVisitanteNombre,
    required this.golesLocal,
    required this.golesVisitante,
    required this.onSaved,
  });

  @override
  State<AnotadoresDialog> createState() => _AnotadoresDialogState();
}

class _AnotadoresDialogState extends State<AnotadoresDialog> {
  bool _loading = true;
  List<Jugador> _jugadoresLocal = [];
  List<Jugador> _jugadoresVisitante = [];
  final Map<String, int> _golesAnotadores = {};

  @override
  void initState() {
    super.initState();
    _cargarJugadores();
  }

  Future<void> _cargarJugadores() async {
    final jugProv = context.read<JugadoresProvider>();
    final local = await jugProv.fetchJugadoresPorEquipo(widget.equipoLocalId);
    final vis = await jugProv.fetchJugadoresPorEquipo(widget.equipoVisitanteId);

    if (mounted) {
      setState(() {
        _jugadoresLocal = local;
        _jugadoresVisitante = vis;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AlertDialog(
        backgroundColor: AppColors.bgCard,
        content: const SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
        ),
      );
    }

    final totalAsigLocal = _jugadoresLocal.fold<int>(0, (s, j) => s + (_golesAnotadores[j.id] ?? 0));
    final totalAsigVis = _jugadoresVisitante.fold<int>(0, (s, j) => s + (_golesAnotadores[j.id] ?? 0));
    final valido = totalAsigLocal == widget.golesLocal && totalAsigVis == widget.golesVisitante;

    return AlertDialog(
      backgroundColor: AppColors.bgCard,
      title: Text(
        'Asignar Anotadores',
        style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Marcador: ${widget.equipoLocalNombre} ${widget.golesLocal} - ${widget.golesVisitante} ${widget.equipoVisitanteNombre}',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Local: $totalAsigLocal/${widget.golesLocal} · Visitante: $totalAsigVis/${widget.golesVisitante}',
                style: GoogleFonts.inter(
                  color: valido ? AppColors.success : AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // LOCAL
              if (widget.golesLocal > 0) ...[
                Text(
                  widget.equipoLocalNombre,
                  style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                if (_jugadoresLocal.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Sin jugadores registrados en este equipo.', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12)),
                  )
                else
                  ..._jugadoresLocal.map((j) => _anotadorRow(j, widget.golesLocal - (totalAsigLocal - (_golesAnotadores[j.id] ?? 0)))),
                const SizedBox(height: 16),
              ],

              // VISITANTE
              if (widget.golesVisitante > 0) ...[
                Text(
                  widget.equipoVisitanteNombre,
                  style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                if (_jugadoresVisitante.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Sin jugadores registrados en este equipo.', style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 12)),
                  )
                else
                  ..._jugadoresVisitante.map((j) => _anotadorRow(j, widget.golesVisitante - (totalAsigVis - (_golesAnotadores[j.id] ?? 0)))),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: !valido
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onSaved(_golesAnotadores, _jugadoresLocal, _jugadoresVisitante);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: AppColors.bgDark,
          ),
          child: Text('Guardar', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  Widget _anotadorRow(Jugador j, int maxDisponible) {
    final asignados = _golesAnotadores[j.id] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '#${j.numero} ${j.nombre}',
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary, size: 20),
            onPressed: asignados <= 0 ? null : () => setState(() => _golesAnotadores[j.id] = asignados - 1),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: AppColors.bgCardLight, borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text(
                '$asignados',
                style: GoogleFonts.inter(
                  color: asignados > 0 ? AppColors.gold : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.gold, size: 20),
            onPressed: asignados >= maxDisponible + asignados || maxDisponible <= 0
                ? null
                : () => setState(() => _golesAnotadores[j.id] = asignados + 1),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
