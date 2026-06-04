import 'package:flutter/material.dart';
import '../../core/supabase_config.dart';
import '../../models/jugador.dart';

class JugadoresProvider extends ChangeNotifier {
  List<Jugador> _jugadores = [];
  bool _loading = false;
  String? _error;

  List<Jugador> get jugadores => _jugadores;
  bool get loading => _loading;
  String? get error => _error;

  List<Jugador> get topGoleadores {
    final sorted = [..._jugadores]..sort((a, b) => b.goles.compareTo(a.goles));
    return sorted.take(10).toList();
  }

  Future<void> fetchJugadores({String? equipoId}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      var query = supabase
          .from('jugadores')
          .select('*, equipos(nombre_equipo, color_hex)');
      if (equipoId != null) {
        query = query.eq('equipo_id', equipoId) as dynamic;
      }
      final data = await (query as dynamic).order('nombre_jugador');
      _jugadores = (data as List).map((e) => Jugador.fromMap(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<Map<String, String>?> crearJugador(
    Map<String, dynamic> data, {
    String? correoPersonalizado,
    String? contrasenaPersonalizada,
  }) async {
    _error = null;
    notifyListeners();
    try {
      final nombre = data['nombre_jugador'] as String;
      final slug = nombre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final ts = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      final correo = correoPersonalizado?.trim().isNotEmpty == true
          ? correoPersonalizado!.trim().toLowerCase()
          : 'jugador_${slug}_$ts@gol258.com';
      final contrasena = contrasenaPersonalizada?.trim().isNotEmpty == true
          ? contrasenaPersonalizada!.trim()
          : 'gol258${ts.substring(ts.length - 4)}';

      // Verificar si el correo ya existe
      final existing = await supabase
          .from('usuario')
          .select('id')
          .eq('correo', correo)
          .maybeSingle();
      if (existing != null) {
        _error = 'El correo "$correo" ya está registrado.';
        notifyListeners();
        return null;
      }

      final usuarioResponse = await supabase.from('usuario').insert({
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena,
      }).select().single();
      final usuarioId = usuarioResponse['id'];

      final jugadorResponse = await supabase.from('jugadores').insert(data).select().single();
      final jugadorId = jugadorResponse['id'];

      await supabase.from('usuario_jugadores').insert({
        'usuario_id': usuarioId,
        'jugador_id': jugadorId,
      });

      await fetchJugadores();
      return {'correo': correo, 'contrasena': contrasena};
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> editarJugador(String id, Map<String, dynamic> data) async {
    try {
      await supabase.from('jugadores').update(data).eq('id', id);
      await fetchJugadores();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarJugador(String id) async {
    try {
      await supabase.from('jugadores').delete().eq('id', id);
      await fetchJugadores();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Suma [cantidad] goles al jugador indicado en la DB y en memoria.
  Future<bool> sumarGoles(String jugadorId, int cantidad) async {
    try {
      // Leer valor actual
      final row = await supabase
          .from('jugadores')
          .select('goles')
          .eq('id', jugadorId)
          .single();
      final actual = (row['goles'] as int?) ?? 0;
      await supabase
          .from('jugadores')
          .update({'goles': actual + cantidad})
          .eq('id', jugadorId);
      // Actualizar en memoria
      final idx = _jugadores.indexWhere((j) => j.id == jugadorId);
      if (idx != -1) {
        final j = _jugadores[idx];
        _jugadores[idx] = Jugador(
          id: j.id,
          nombre: j.nombre,
          equipoId: j.equipoId,
          equipoNombre: j.equipoNombre,
          numero: j.numero,
          posicion: j.posicion,
          goles: actual + cantidad,
          asistencias: j.asistencias,
          partidos: j.partidos,
          fotoUrl: j.fotoUrl,
          createdAt: j.createdAt,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Suma [cantidad] partidos al jugador indicado en la DB y en memoria.
  Future<bool> sumarPartidos(String jugadorId, int cantidad) async {
    try {
      final row = await supabase
          .from('jugadores')
          .select('partidos')
          .eq('id', jugadorId)
          .single();
      final actual = (row['partidos'] as int?) ?? 0;
      await supabase
          .from('jugadores')
          .update({'partidos': actual + cantidad})
          .eq('id', jugadorId);
      final idx = _jugadores.indexWhere((j) => j.id == jugadorId);
      if (idx != -1) {
        final j = _jugadores[idx];
        _jugadores[idx] = Jugador(
          id: j.id,
          nombre: j.nombre,
          equipoId: j.equipoId,
          equipoNombre: j.equipoNombre,
          numero: j.numero,
          posicion: j.posicion,
          goles: j.goles,
          asistencias: j.asistencias,
          partidos: actual + cantidad,
          fotoUrl: j.fotoUrl,
          createdAt: j.createdAt,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Retorna los jugadores del equipo dado (filtrando en memoria).
  List<Jugador> jugadoresPorEquipo(String equipoId) =>
      _jugadores.where((j) => j.equipoId == equipoId).toList();

  /// Carga desde DB solo los jugadores de un equipo específico.
  Future<List<Jugador>> fetchJugadoresPorEquipo(String equipoId) async {
    try {
      final data = await supabase
          .from('jugadores')
          .select('*, equipos(nombre_equipo, color_hex)')
          .eq('equipo_id', equipoId)
          .order('orden_plantilla')
          .order('nombre_jugador');
      return (data as List).map((e) => Jugador.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Guarda el orden de la plantilla (titulares y banca) para un equipo.
  /// Recibe la lista completa de jugadores ya reordenada con esTitular asignado.
  Future<bool> guardarPlantilla(String equipoId, List<Jugador> jugadores) async {
    try {
      for (int i = 0; i < jugadores.length; i++) {
        final j = jugadores[i];
        await supabase.from('jugadores').update({
          'es_titular': j.esTitular,
          'orden_plantilla': i,
        }).eq('id', j.id);
      }
      // Actualizar en memoria
      for (int i = 0; i < jugadores.length; i++) {
        final updated = jugadores[i].copyWith(ordenPlantilla: i);
        final idx = _jugadores.indexWhere((j) => j.id == updated.id);
        if (idx != -1) {
          _jugadores[idx] = updated;
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
