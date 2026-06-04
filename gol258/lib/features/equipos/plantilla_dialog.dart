import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/equipo.dart';
import '../../models/jugador.dart';
import '../jugadores/jugadores_provider.dart';

/// Muestra un BottomSheet premium con la plantilla del equipo.
/// Permite reordenar jugadores y moverlos entre Titulares y Banca.
Future<void> showPlantillaDialog(BuildContext context, Equipo equipo) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PlantillaSheet(equipo: equipo),
  );
}

class _PlantillaSheet extends StatefulWidget {
  final Equipo equipo;
  const _PlantillaSheet({required this.equipo});

  @override
  State<_PlantillaSheet> createState() => _PlantillaSheetState();
}

class _PlantillaSheetState extends State<_PlantillaSheet>
    with SingleTickerProviderStateMixin {
  List<Jugador> _titulares = [];
  List<Jugador> _banca = [];
  bool _loading = true;
  bool _saving = false;
  bool _hasChanges = false;
  late AnimationController _entryController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _loadJugadores();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _loadJugadores() async {
    final provider = context.read<JugadoresProvider>();
    final jugadores = await provider.fetchJugadoresPorEquipo(widget.equipo.id);
    if (!mounted) return;
    setState(() {
      _titulares = jugadores.where((j) => j.esTitular).toList();
      _banca = jugadores.where((j) => !j.esTitular).toList();
      // Sort by their saved order
      _titulares.sort((a, b) => a.ordenPlantilla.compareTo(b.ordenPlantilla));
      _banca.sort((a, b) => a.ordenPlantilla.compareTo(b.ordenPlantilla));
      _loading = false;
    });
    _entryController.forward();
  }

  void _moveToTitulares(Jugador j) {
    setState(() {
      _banca.remove(j);
      _titulares.add(j.copyWith(esTitular: true));
      _hasChanges = true;
    });
  }

  void _moveToBanca(Jugador j) {
    setState(() {
      _titulares.remove(j);
      _banca.add(j.copyWith(esTitular: false));
      _hasChanges = true;
    });
  }

  Future<void> _guardar() async {
    setState(() => _saving = true);
    final provider = context.read<JugadoresProvider>();
    // Combine lists: titulares first, then banca, with correct esTitular flag
    final allJugadores = <Jugador>[
      ..._titulares.map((j) => j.copyWith(esTitular: true)),
      ..._banca.map((j) => j.copyWith(esTitular: false)),
    ];
    final ok = await provider.guardarPlantilla(widget.equipo.id, allJugadores);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _hasChanges = false;
    });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(CupertinoIcons.checkmark_circle_fill,
                  color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Text('Plantilla guardada exitosamente',
                  style: GoogleFonts.inter(color: AppColors.textPrimary)),
            ],
          ),
          backgroundColor: AppColors.bgCardLight,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
          left: BorderSide(color: AppColors.divider, width: 0.5),
          right: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.gold))
                : FadeTransition(
                    opacity: _fadeIn,
                    child: _buildContent(),
                  ),
          ),
          if (!_loading) _buildSaveBar(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final color = _parseHex(widget.equipo.colorHex);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(color, AppColors.bgDark, 0.7) ?? AppColors.bgDark,
            AppColors.bgDark,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          // Team badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.gold.withOpacity(0.4), width: 1),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: -2),
              ],
            ),
            child: widget.equipo.escudoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.network(widget.equipo.escudoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildInitial()),
                  )
                : _buildInitial(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.equipo.nombre.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'PLANTILLA · ${_titulares.length + _banca.length} jugadores',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Close button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.bgCardLight,
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: const Icon(CupertinoIcons.xmark,
                  color: AppColors.textSecondary, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        widget.equipo.nombre.isNotEmpty
            ? widget.equipo.nombre[0].toUpperCase()
            : '?',
        style: GoogleFonts.inter(
          color: AppColors.gold,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_titulares.isEmpty && _banca.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.person_3,
                color: AppColors.textTertiary, size: 48),
            const SizedBox(height: 16),
            Text(
              'No hay jugadores registrados\nen este equipo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // ── TITULARES ──
          _buildSectionLabel(
            icon: CupertinoIcons.star_fill,
            label: 'TITULARES',
            count: _titulares.length,
            color: AppColors.gold,
          ),
          const SizedBox(height: 8),
          _buildReorderableList(
            list: _titulares,
            isTitulares: true,
            onReorder: (oldIdx, newIdx) {
              setState(() {
                if (newIdx > oldIdx) newIdx--;
                final item = _titulares.removeAt(oldIdx);
                _titulares.insert(newIdx, item);
                _hasChanges = true;
              });
            },
          ),

          const SizedBox(height: 20),

          // ── BANCA ──
          _buildSectionLabel(
            icon: CupertinoIcons.rectangle_on_rectangle,
            label: 'BANCA',
            count: _banca.length,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          _buildReorderableList(
            list: _banca,
            isTitulares: false,
            onReorder: (oldIdx, newIdx) {
              setState(() {
                if (newIdx > oldIdx) newIdx--;
                final item = _banca.removeAt(oldIdx);
                _banca.insert(newIdx, item);
                _hasChanges = true;
              });
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSectionLabel({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReorderableList({
    required List<Jugador> list,
    required bool isTitulares,
    required void Function(int, int) onReorder,
  }) {
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.divider.withOpacity(0.5), width: 0.5),
        ),
        child: Center(
          child: Text(
            isTitulares
                ? 'Arrastra jugadores aquí para hacerlos titulares'
                : 'Sin jugadores en banca',
            style: GoogleFonts.inter(
                color: AppColors.textTertiary, fontSize: 12),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.divider.withOpacity(0.5), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: list.length,
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final elevation = Tween<double>(begin: 0, end: 12)
                    .animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOut))
                    .value;
                return Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgCardLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.gold.withOpacity(0.5), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.2),
                          blurRadius: elevation,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          onReorder: onReorder,
          itemBuilder: (context, index) {
            final jugador = list[index];
            return _buildJugadorTile(
              key: ValueKey(jugador.id),
              jugador: jugador,
              index: index,
              isTitular: isTitulares,
            );
          },
        ),
      ),
    );
  }

  Widget _buildJugadorTile({
    required Key key,
    required Jugador jugador,
    required int index,
    required bool isTitular,
  }) {
    final posColor = _positionColor(jugador.posicion);

    return Container(
      key: key,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(CupertinoIcons.line_horizontal_3,
                    color: AppColors.textTertiary, size: 16),
              ),
            ),
            const SizedBox(width: 8),
            // Player number badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: isTitular
                    ? const LinearGradient(
                        colors: [Color(0xFF2D1A08), Color(0xFF1C1C1E)],
                      )
                    : null,
                color: isTitular ? null : AppColors.bgCardLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isTitular
                      ? AppColors.gold.withOpacity(0.4)
                      : AppColors.divider,
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  '#${jugador.numero}',
                  style: GoogleFonts.inter(
                    color:
                        isTitular ? AppColors.gold : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jugador.nombre,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: posColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        jugador.posicion ?? 'Sin posición',
                        style: GoogleFonts.inter(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (jugador.goles > 0) ...[
                        Icon(CupertinoIcons.sportscourt,
                            color: AppColors.gold.withOpacity(0.6), size: 10),
                        const SizedBox(width: 2),
                        Text(
                          '${jugador.goles}',
                          style: GoogleFonts.inter(
                            color: AppColors.gold.withOpacity(0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Action: move to other list
            GestureDetector(
              onTap: () {
                if (isTitular) {
                  _moveToBanca(jugador);
                } else {
                  _moveToTitulares(jugador);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isTitular
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF2D1A08), Color(0xFF1C1C1E)],
                        ),
                  color: isTitular ? AppColors.bgCardLight : null,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isTitular
                        ? AppColors.divider
                        : AppColors.gold.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTitular
                          ? CupertinoIcons.arrow_down
                          : CupertinoIcons.arrow_up,
                      color: isTitular
                          ? AppColors.textTertiary
                          : AppColors.gold,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isTitular ? 'Banca' : 'Titular',
                      style: GoogleFonts.inter(
                        color: isTitular
                            ? AppColors.textTertiary
                            : AppColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border:
            const Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Info chip
          Expanded(
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.star_fill,
                          color: AppColors.gold, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        '${_titulares.length}',
                        style: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.rectangle_on_rectangle,
                          color: AppColors.textTertiary, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        '${_banca.length}',
                        style: GoogleFonts.inter(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Save button
          GestureDetector(
            onTap: _hasChanges && !_saving ? _guardar : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient:
                    _hasChanges ? AppColors.goldGradient : null,
                color: _hasChanges ? null : AppColors.bgCardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasChanges
                      ? Colors.transparent
                      : AppColors.divider,
                  width: 0.5,
                ),
                boxShadow: _hasChanges ? AppColors.goldGlowSubtle : null,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.bgDark,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_alt,
                          color: _hasChanges
                              ? AppColors.bgDark
                              : AppColors.textTertiary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'GUARDAR',
                          style: GoogleFonts.inter(
                            color: _hasChanges
                                ? AppColors.bgDark
                                : AppColors.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color _positionColor(String? pos) {
    if (pos == null) return AppColors.textTertiary;
    final p = pos.toLowerCase();
    if (p.contains('portero') || p.contains('gk') || p.contains('arquero')) {
      return const Color(0xFFFF9F0A); // orange
    }
    if (p.contains('defensa') || p.contains('def') || p.contains('cb')) {
      return const Color(0xFF0A84FF); // blue
    }
    if (p.contains('medio') ||
        p.contains('mid') ||
        p.contains('volante') ||
        p.contains('mc')) {
      return const Color(0xFF32D74B); // green
    }
    if (p.contains('delantero') ||
        p.contains('fw') ||
        p.contains('atacante') ||
        p.contains('st')) {
      return const Color(0xFFFF453A); // red
    }
    return AppColors.textTertiary;
  }

  Color _parseHex(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.maroon;
    }
  }
}
