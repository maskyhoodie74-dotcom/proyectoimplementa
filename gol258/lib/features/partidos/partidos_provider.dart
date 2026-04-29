import 'package:flutter/material.dart';
import '../../core/supabase_config.dart';
import '../../models/partido.dart';

class PartidosProvider extends ChangeNotifier {
  List<Partido> _partidos = [];
  bool _loading = false;
  String? _error;

  List<Partido> get partidos => _partidos;
  bool get loading => _loading;
  String? get error => _error;

  List<Partido> get proximosPartidos => _partidos
      .where((p) => !p.jugado && p.fecha.isAfter(DateTime.now().subtract(const Duration(hours: 2))))
      .toList()
    ..sort((a, b) => a.fecha.compareTo(b.fecha));

  List<Partido> get resultados => _partidos
      .where((p) => p.jugado)
      .toList()
    ..sort((a, b) => b.fecha.compareTo(a.fecha));

  Future<void> fetchPartidos() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await supabase
          .from('calendario')
          .select('*, equipo_local:equipos!equipo_local_id(nombre_equipo, escudo_url, color_hex), equipo_visitante:equipos!equipo_visitante_id(nombre_equipo, escudo_url, color_hex)')
          .order('fecha', ascending: false);
      _partidos = (data as List).map((e) => Partido.fromMap(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> crearPartido(Map<String, dynamic> data) async {
    try {
      await supabase.from('calendario').insert(data);
      await fetchPartidos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrarResultado(
      String id, int golesLocal, int golesVisitante) async {
    try {
      await supabase.from('calendario').update({
        'goles_local': golesLocal,
        'goles_visitante': golesVisitante,
        'jugado': true,
        'estado': 'finalizado',
      }).eq('id', id);
      await fetchPartidos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarPartido(String id) async {
    try {
      await supabase.from('calendario').delete().eq('id', id);
      await fetchPartidos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Calcula la tabla de posiciones
  Map<String, Map<String, int>> calcularPosiciones() {
    final tabla = <String, Map<String, int>>{};

    for (final p in _partidos.where((p) => p.jugado)) {
      final local = p.equipoLocalNombre ?? p.equipoLocalId;
      final visitante = p.equipoVisitanteNombre ?? p.equipoVisitanteId;
      final gl = p.golesLocal ?? 0;
      final gv = p.golesVisitante ?? 0;

      tabla.putIfAbsent(local, () => {'PJ': 0, 'PG': 0, 'PE': 0, 'PP': 0, 'GF': 0, 'GC': 0, 'Pts': 0});
      tabla.putIfAbsent(visitante, () => {'PJ': 0, 'PG': 0, 'PE': 0, 'PP': 0, 'GF': 0, 'GC': 0, 'Pts': 0});

      tabla[local]!['PJ'] = tabla[local]!['PJ']! + 1;
      tabla[local]!['GF'] = tabla[local]!['GF']! + gl;
      tabla[local]!['GC'] = tabla[local]!['GC']! + gv;

      tabla[visitante]!['PJ'] = tabla[visitante]!['PJ']! + 1;
      tabla[visitante]!['GF'] = tabla[visitante]!['GF']! + gv;
      tabla[visitante]!['GC'] = tabla[visitante]!['GC']! + gl;

      if (gl > gv) {
        tabla[local]!['PG'] = tabla[local]!['PG']! + 1;
        tabla[local]!['Pts'] = tabla[local]!['Pts']! + 3;
        tabla[visitante]!['PP'] = tabla[visitante]!['PP']! + 1;
      } else if (gl < gv) {
        tabla[visitante]!['PG'] = tabla[visitante]!['PG']! + 1;
        tabla[visitante]!['Pts'] = tabla[visitante]!['Pts']! + 3;
        tabla[local]!['PP'] = tabla[local]!['PP']! + 1;
      } else {
        tabla[local]!['PE'] = tabla[local]!['PE']! + 1;
        tabla[local]!['Pts'] = tabla[local]!['Pts']! + 1;
        tabla[visitante]!['PE'] = tabla[visitante]!['PE']! + 1;
        tabla[visitante]!['Pts'] = tabla[visitante]!['Pts']! + 1;
      }
    }
    return tabla;
  }
}
