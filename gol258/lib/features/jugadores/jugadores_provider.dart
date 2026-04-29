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

  Future<bool> crearJugador(Map<String, dynamic> data) async {
    try {
      await supabase.from('jugadores').insert(data);
      await fetchJugadores();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
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
}
