import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../partidos/partidos_provider.dart';
import '../auth/auth_provider.dart';
import '../equipos/equipos_provider.dart';
import '../../core/theme.dart';
import '../../models/partido.dart';
import '../../widgets/match_card.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});
  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    Future.microtask(() {
      context.read<PartidosProvider>().fetchPartidos();
      context.read<EquiposProvider>().fetchEquipos();
    });
  }

  void _showPartidoForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PartidoFormSheet(),
    );
  }

  List<Partido> _getEventsForDay(DateTime day, List<Partido> todos) {
    return todos.where((p) => isSameDay(p.fecha, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final partidos = context.watch<PartidosProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final todos = [...partidos.proximosPartidos, ...partidos.resultados];
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!, todos) : <Partido>[];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        title: Text('CALENDARIO',
            style: GoogleFonts.inter(color: AppColors.gold, fontSize: 20, letterSpacing: 2)),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.gold),
              onPressed: _showPartidoForm,
            ),
        ],
      ),
      body: partidos.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : RefreshIndicator(
              color: AppColors.gold,
              backgroundColor: AppColors.bgCard,
              onRefresh: () => partidos.fetchPartidos(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: TableCalendar<Partido>(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          eventLoader: (day) => _getEventsForDay(day, todos),
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            if (!isSameDay(_selectedDay, selectedDay)) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            }
                          },
                          onFormatChanged: (format) {
                            if (_calendarFormat != format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            }
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                          },
                          calendarStyle: CalendarStyle(
                            defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
                            weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
                            outsideTextStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                            selectedDecoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                            selectedTextStyle: const TextStyle(color: AppColors.bgDark, fontWeight: FontWeight.bold),
                            todayDecoration: BoxDecoration(
                              color: AppColors.maroonDark.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: const BoxDecoration(
                              color: AppColors.maroon,
                              shape: BoxShape.circle,
                            ),
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: GoogleFonts.inter(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.bold),
                            leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.gold),
                            rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.gold),
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle: TextStyle(color: AppColors.textSecondary),
                            weekendStyle: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _selectedDay != null
                                ? DateFormat('EEEE, d MMM yyyy', 'es_MX').format(_selectedDay!).toUpperCase()
                                : 'SELECCIONA UNA FECHA',
                            style: GoogleFonts.inter(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: selectedEvents.isEmpty
                            ? Center(child: Text('No hay partidos este día.', style: GoogleFonts.inter(color: AppColors.textSecondary)))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                physics: const BouncingScrollPhysics(),
                                itemCount: selectedEvents.length,
                                itemBuilder: (context, index) {
                                  final p = selectedEvents[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: MatchCard(partido: p, showScore: p.jugado, showDetails: !p.jugado),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _PartidoFormSheet extends StatefulWidget {
  const _PartidoFormSheet();
  @override
  State<_PartidoFormSheet> createState() => _PartidoFormSheetState();
}

class _PartidoFormSheetState extends State<_PartidoFormSheet> {
  String? _localId;
  String? _visitanteId;
  DateTime _fecha = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _hora = const TimeOfDay(hour: 16, minute: 0);
  final _lugarCtrl = TextEditingController();
  String _categoria = 'Varonil';
  bool _saving = false;
  final _categorias = ['Varonil', 'Femenil', 'Mixto', 'Juvenil', 'División I'];

  @override
  void dispose() {
    _lugarCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_localId == null || _visitanteId == null) return;
    if (_localId == _visitanteId) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El equipo local y visitante deben ser diferentes')));
      return;
    }
    setState(() => _saving = true);
    final data = {
      'equipo_local_id': _localId,
      'equipo_visitante_id': _visitanteId,
      'fecha': DateFormat('yyyy-MM-dd').format(_fecha),
      'hora': '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}',
      'lugar': _lugarCtrl.text.trim().isEmpty ? null : _lugarCtrl.text.trim(),
      'categoria': _categoria,
      'jugado': false,
      'estado': 'programado',
    };
    final ok = await context.read<PartidosProvider>().crearPartido(data);
    if (ok && mounted) Navigator.pop(context);
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
            Text('PROGRAMAR PARTIDO',
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            _dropLabel('EQUIPO LOCAL'),
            const SizedBox(height: 8),
            _equipoDropdown(_localId, equipos, (v) => setState(() => _localId = v)),
            const SizedBox(height: 16),
            _dropLabel('EQUIPO VISITANTE'),
            const SizedBox(height: 8),
            _equipoDropdown(_visitanteId, equipos, (v) => setState(() => _visitanteId = v)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _dropLabel('FECHA'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _fecha,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(primary: AppColors.gold),
                        ),
                        child: child!,
                      ),
                    );
                    if (d != null) setState(() => _fecha = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                        color: AppColors.bgCardLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider)),
                    child: Text(DateFormat('dd/MM/yyyy').format(_fecha),
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14)),
                  ),
                ),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _dropLabel('HORA'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context, initialTime: _hora,
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.gold)),
                        child: child!,
                      ),
                    );
                    if (t != null) setState(() => _hora = t);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                        color: AppColors.bgCardLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider)),
                    child: Text(_hora.format(context),
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14)),
                  ),
                ),
              ])),
            ]),
            const SizedBox(height: 16),
            _dropLabel('LUGAR'),
            const SizedBox(height: 8),
            TextField(controller: _lugarCtrl,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'Cancha principal')),
            const SizedBox(height: 16),
            _dropLabel('CATEGORÍA'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.bgCardLight, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider)),
              child: DropdownButton<String>(
                value: _categoria, isExpanded: true, dropdownColor: AppColors.bgCard, underline: const SizedBox(),
                items: _categorias.map((c) => DropdownMenuItem(value: c,
                    child: Text(c, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _categoria = v!),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.bgDark, strokeWidth: 2))
                      : const Text('PROGRAMAR PARTIDO'),
                )),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.maroon), padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('CANCELAR', style: GoogleFonts.inter(color: AppColors.textPrimary, letterSpacing: 1.5)),
                )),
          ],
        ),
      ),
    );
  }

  Widget _dropLabel(String label) => Text(label,
      style: GoogleFonts.inter(color: AppColors.gold, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600));

  Widget _equipoDropdown(String? value, List equipos, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.bgCardLight, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider)),
      child: DropdownButton<String>(
        value: value, isExpanded: true, dropdownColor: AppColors.bgCard, underline: const SizedBox(),
        hint: Text('Seleccionar equipo', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14)),
        items: equipos.map<DropdownMenuItem<String>>((e) =>
            DropdownMenuItem(value: e.id, child: Text(e.nombre,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
