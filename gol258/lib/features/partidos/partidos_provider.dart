import 'package:flutter/material.dart';
import '../../core/supabase_config.dart';
import '../../models/partido.dart';
import '../../models/equipo.dart';

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

  List<Partido> proximosPartidosDeEquipo(String equipoId) {
    return proximosPartidos
        .where((p) => p.equipoLocalId == equipoId || p.equipoVisitanteId == equipoId)
        .toList();
  }

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

  /// Edita cualquier campo de un partido (marcador, fecha, hora, lugar, etc.)
  Future<bool> editarPartido(String id, Map<String, dynamic> data) async {
    try {
      await supabase.from('calendario').update(data).eq('id', id);
      await fetchPartidos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Registra el resultado y devuelve true. La lógica de actualizar
  /// los goles de cada jugador se maneja desde el UI (Admin Dashboard)
  /// usando JugadoresProvider.sumarGoles para mayor claridad.
  Future<bool> registrarResultadoConAnotadores(
      String id, int golesLocal, int golesVisitante) async {
    return registrarResultado(id, golesLocal, golesVisitante);
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

  // Calcula la tabla de posiciones con métricas detalladas
  Map<String, Map<String, dynamic>> _calcularTabla(List<Partido> listaPartidos) {
    final tabla = <String, Map<String, dynamic>>{
      // Inicializar con 0 para todos los equipos conocidos si se pasan aquí,
      // pero esta función es genérica para cualquier lista de partidos.
    };

    for (final p in listaPartidos.where((p) => p.jugado)) {
      final local = p.equipoLocalNombre ?? p.equipoLocalId;
      final visitante = p.equipoVisitanteNombre ?? p.equipoVisitanteId;
      final gl = p.golesLocal ?? 0;
      final gv = p.golesVisitante ?? 0;

      tabla.putIfAbsent(local, () => {'PJ': 0, 'PG': 0, 'PE': 0, 'PP': 0, 'GF': 0, 'GC': 0, 'Pts': 0});
      tabla.putIfAbsent(visitante, () => {'PJ': 0, 'PG': 0, 'PE': 0, 'PP': 0, 'GF': 0, 'GC': 0, 'Pts': 0});

      tabla[local]!['PJ'] += 1;
      tabla[local]!['GF'] += gl;
      tabla[local]!['GC'] += gv;

      tabla[visitante]!['PJ'] += 1;
      tabla[visitante]!['GF'] += gv;
      tabla[visitante]!['GC'] += gl;

      if (gl > gv) {
        tabla[local]!['PG'] += 1;
        tabla[local]!['Pts'] += 3;
        tabla[visitante]!['PP'] += 1;
      } else if (gl < gv) {
        tabla[visitante]!['PG'] += 1;
        tabla[visitante]!['Pts'] += 3;
        tabla[local]!['PP'] += 1;
      } else {
        tabla[local]!['PE'] += 1;
        tabla[local]!['Pts'] += 1;
        tabla[visitante]!['PE'] += 1;
        tabla[visitante]!['Pts'] += 1;
      }
    }
    return tabla;
  }

  /// Ordena los equipos por Puntos (desc), Diferencia de Goles (desc) y Nombre (asc)
  List<MapEntry<String, Map<String, dynamic>>> _ordenarTabla(
      Map<String, Map<String, dynamic>> tabla, List<Equipo> todosLosEquipos) {
    
    // Asegurar que todos los equipos estén en la tabla
    for (final eq in todosLosEquipos) {
      tabla.putIfAbsent(eq.nombre, () => {'PJ': 0, 'PG': 0, 'PE': 0, 'PP': 0, 'GF': 0, 'GC': 0, 'Pts': 0});
    }

    final entries = tabla.entries.toList();
    entries.sort((a, b) {
      // 1. Puntos
      final ptsA = a.value['Pts'] as int;
      final ptsB = b.value['Pts'] as int;
      if (ptsA != ptsB) return ptsB.compareTo(ptsA);

      // 2. Diferencia de Goles
      final gdA = (a.value['GF'] as int) - (a.value['GC'] as int);
      final gdB = (b.value['GF'] as int) - (b.value['GC'] as int);
      if (gdA != gdB) return gdB.compareTo(gdA);

      // 3. Orden Alfabético (A-Z)
      return a.key.toLowerCase().compareTo(b.key.toLowerCase());
    });

    return entries;
  }

  /// Calcula la tabla actual y la tendencia comparada con la "jornada" anterior
  List<Map<String, dynamic>> obtenerTablaConTendencia(List<Equipo> equipos) {
    if (equipos.isEmpty) return [];

    final partidosJugados = _partidos.where((p) => p.jugado).toList();
    // Ordenar por fecha para identificar la "última jornada"
    partidosJugados.sort((a, b) => a.fecha.compareTo(b.fecha));

    // 1. Tabla Actual
    final tablaActualRaw = _calcularTabla(partidosJugados);
    final tablaActualOrdenada = _ordenarTabla(tablaActualRaw, equipos);

    // 2. Tabla Anterior (sin los partidos del último día de juego)
    if (partidosJugados.isEmpty) {
      return tablaActualOrdenada.map((e) => {
        'nombre': e.key,
        'stats': e.value,
        'tendencia': 0,
      }).toList();
    }

    final ultimaFecha = partidosJugados.last.fecha;
    final partidosAnteriores = partidosJugados.where((p) => 
      p.fecha.year != ultimaFecha.year || 
      p.fecha.month != ultimaFecha.month || 
      p.fecha.day != ultimaFecha.day
    ).toList();

    final tablaAnteriorRaw = _calcularTabla(partidosAnteriores);
    final tablaAnteriorOrdenada = _ordenarTabla(tablaAnteriorRaw, equipos);

    // Mapear posiciones anteriores para comparar
    final posicionesAnteriores = <String, int>{};
    for (int i = 0; i < tablaAnteriorOrdenada.length; i++) {
      posicionesAnteriores[tablaAnteriorOrdenada[i].key] = i + 1;
    }

    // 3. Construir resultado final con tendencia
    return tablaActualOrdenada.asMap().entries.map((entry) {
      final posActual = entry.key + 1;
      final nombre = entry.value.key;
      final stats = entry.value.value;
      
      final posAnterior = posicionesAnteriores[nombre] ?? posActual;
      final tendencia = posAnterior - posActual; // Positivo si subió (ej: 5 - 3 = +2)

      return {
        'nombre': nombre,
        'stats': stats,
        'tendencia': tendencia,
      };
    }).toList();
  }
}


