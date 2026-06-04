import 'package:flutter/material.dart';
import '../../core/supabase_config.dart';
import '../../models/liguilla_torneo.dart';

class LiguillaProvider extends ChangeNotifier {
  LiguillaTorneo? _torneoActivo;
  List<LiguillaEquipoInfo> _equipos = [];
  List<LiguillaPartido> _partidos = [];
  bool _loading = false;
  String? _error;

  LiguillaTorneo? get torneoActivo => _torneoActivo;
  List<LiguillaEquipoInfo> get equipos => _equipos;
  List<LiguillaPartido> get partidos => _partidos;
  bool get loading => _loading;
  String? get error => _error;

  // Ordenamos los partidos por número para que el bracket los dibuje en orden
  List<LiguillaPartido> getPartidosPorRonda(String ronda) {
    return _partidos.where((p) => p.ronda == ronda).toList()
      ..sort((a, b) => a.numeroPartido.compareTo(b.numeroPartido));
  }

  /// Carga el torneo activo actual o el último finalizado
  Future<void> fetchTorneoActivo() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Obtener el torneo más reciente
      final res = await supabase
          .from('liguilla_torneos')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res == null) {
        _torneoActivo = null;
        _equipos = [];
        _partidos = [];
      } else {
        _torneoActivo = LiguillaTorneo.fromMap(res);

        // 2. Cargar equipos con JOIN
        final eqsRes = await supabase
            .from('liguilla_equipos')
            .select('*, equipos:equipo_id(nombre_equipo, escudo_url, color_hex)')
            .eq('torneo_id', _torneoActivo!.id)
            .order('seed', ascending: true);
        _equipos = (eqsRes as List).map((e) => LiguillaEquipoInfo.fromMap(e)).toList();

        // 3. Cargar partidos con JOIN
        final partsRes = await supabase
            .from('liguilla_partidos')
            .select('*, equipo_local:equipo_local_id(nombre_equipo, escudo_url), equipo_visitante:equipo_visitante_id(nombre_equipo, escudo_url)')
            .eq('torneo_id', _torneoActivo!.id)
            .order('ronda', ascending: false) // No importa mucho aquí, ordenamos en getPartidosPorRonda
            .order('numero_partido', ascending: true);
        _partidos = (partsRes as List).map((p) => LiguillaPartido.fromMap(p)).toList();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetchTorneoActivo: $e');
    }

    _loading = false;
    notifyListeners();
  }

  /// Crea un nuevo torneo y cierra los anteriores
  Future<bool> crearTorneo(String nombre, int numEquipos) async {
    try {
      // Cerrar activos
      await supabase
          .from('liguilla_torneos')
          .update({'estado': 'finalizado'})
          .eq('estado', 'activo');

      // Crear nuevo
      await supabase.from('liguilla_torneos').insert({
        'nombre': nombre,
        'estado': 'activo',
        'num_equipos': numEquipos,
      });

      await fetchTorneoActivo();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Agrega un equipo al torneo en una posición (seed) específica
  Future<bool> agregarEquipo(String equipoId, int seed) async {
    if (_torneoActivo == null) return false;
    try {
      await supabase.from('liguilla_equipos').insert({
        'torneo_id': int.parse(_torneoActivo!.id),
        'equipo_id': int.parse(equipoId),
        'seed': seed,
      });
      await fetchTorneoActivo();
      return true;
    } catch (e) {
      _error = 'Error agregando equipo: $e';
      notifyListeners();
      return false;
    }
  }

  /// Elimina un equipo del torneo
  Future<bool> quitarEquipo(String id) async {
    try {
      await supabase.from('liguilla_equipos').delete().eq('id', id);
      await fetchTorneoActivo();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Genera el bracket vacío en base a los equipos actuales (se usa cuando ya están completos)
  Future<bool> generarBracket() async {
    if (_torneoActivo == null || _equipos.isEmpty) return false;
    
    try {
      // 1. Limpiar partidos existentes del torneo actual
      await supabase.from('liguilla_partidos').delete().eq('torneo_id', _torneoActivo!.id);

      // 2. Generar árbol dependiendo del número de equipos configurado en el torneo
      final n = _torneoActivo!.numEquipos;
      final tId = int.parse(_torneoActivo!.id);

      List<Map<String, dynamic>> partidosParaInsertar = [];

      // Función auxiliar para saber el equipo por seed. Retorna null si no está registrado aún.
      int? getEquipoIdBySeed(int seed) {
        try {
          final eq = _equipos.firstWhere((e) => e.seed == seed);
          return int.parse(eq.equipoId);
        } catch (_) {
          return null; // Aún no asignado
        }
      }

      if (n == 2) {
        // Duelo directo (Solo FINAL)
        partidosParaInsertar.add({
          'torneo_id': tId, 'ronda': 'FINAL', 'numero_partido': 1,
          'equipo_local_id': getEquipoIdBySeed(1), 'equipo_visitante_id': getEquipoIdBySeed(2),
        });
      } else if (n == 4) {
        // Semifinales (1vs4, 2vs3)
        partidosParaInsertar.addAll([
          { 'torneo_id': tId, 'ronda': 'SEMIFINALES', 'numero_partido': 1, 'equipo_local_id': getEquipoIdBySeed(1), 'equipo_visitante_id': getEquipoIdBySeed(4) },
          { 'torneo_id': tId, 'ronda': 'SEMIFINALES', 'numero_partido': 2, 'equipo_local_id': getEquipoIdBySeed(2), 'equipo_visitante_id': getEquipoIdBySeed(3) },
          // Final vacía
          { 'torneo_id': tId, 'ronda': 'FINAL', 'numero_partido': 1, 'equipo_local_id': null, 'equipo_visitante_id': null },
        ]);
      } else if (n == 8) {
        // Cuartos (1vs8, 2vs7, 3vs6, 4vs5)
        partidosParaInsertar.addAll([
          { 'torneo_id': tId, 'ronda': 'CUARTOS', 'numero_partido': 1, 'equipo_local_id': getEquipoIdBySeed(1), 'equipo_visitante_id': getEquipoIdBySeed(8) },
          { 'torneo_id': tId, 'ronda': 'CUARTOS', 'numero_partido': 2, 'equipo_local_id': getEquipoIdBySeed(4), 'equipo_visitante_id': getEquipoIdBySeed(5) },
          { 'torneo_id': tId, 'ronda': 'CUARTOS', 'numero_partido': 3, 'equipo_local_id': getEquipoIdBySeed(3), 'equipo_visitante_id': getEquipoIdBySeed(6) },
          { 'torneo_id': tId, 'ronda': 'CUARTOS', 'numero_partido': 4, 'equipo_local_id': getEquipoIdBySeed(2), 'equipo_visitante_id': getEquipoIdBySeed(7) },
          // Semis vacías
          { 'torneo_id': tId, 'ronda': 'SEMIFINALES', 'numero_partido': 1, 'equipo_local_id': null, 'equipo_visitante_id': null },
          { 'torneo_id': tId, 'ronda': 'SEMIFINALES', 'numero_partido': 2, 'equipo_local_id': null, 'equipo_visitante_id': null },
          // Final vacía
          { 'torneo_id': tId, 'ronda': 'FINAL', 'numero_partido': 1, 'equipo_local_id': null, 'equipo_visitante_id': null },
        ]);
      } else if (n == 16) {
        // Octavos
        partidosParaInsertar.addAll([
          { 'torneo_id': tId, 'ronda': 'OCTAVOS', 'numero_partido': 1, 'equipo_local_id': getEquipoIdBySeed(1), 'equipo_visitante_id': getEquipoIdBySeed(16) },
          { 'torneo_id': tId, 'ronda': 'OCTAVOS', 'numero_partido': 2, 'equipo_local_id': getEquipoIdBySeed(8), 'equipo_visitante_id': getEquipoIdBySeed(9) },
          { 'torneo_id': tId, 'ronda': 'OCTAVOS', 'numero_partido': 3, 'equipo_local_id': getEquipoIdBySeed(5), 'equipo_visitante_id': getEquipoIdBySeed(12) },
          { 'torneo_id': tId, 'ronda': 'OCTAVOS', 'numero_partido': 4, 'equipo_local_id': getEquipoIdBySeed(4), 'equipo_visitante_id': getEquipoIdBySeed(13) },
          { 'torneo_id': tId, 'ronda': 'OCTAVOS', 'numero_partido': 5, 'equipo_local_id': getEquipoIdBySeed(3), 'equipo_visitante_id': getEquipoIdBySeed(14) },
          { 'torneo_id': tId, 'ronda': 'OCTAVOS', 'numero_partido': 6, 'equipo_local_id': getEquipoIdBySeed(6), 'equipo_visitante_id': getEquipoIdBySeed(11) },
          { 'torneo_id': tId, 'ronda': 'OCTAVOS', 'numero_partido': 7, 'equipo_local_id': getEquipoIdBySeed(7), 'equipo_visitante_id': getEquipoIdBySeed(10) },
          { 'torneo_id': tId, 'ronda': 'OCTAVOS', 'numero_partido': 8, 'equipo_local_id': getEquipoIdBySeed(2), 'equipo_visitante_id': getEquipoIdBySeed(15) },
          // Cuartos vacíos
          { 'torneo_id': tId, 'ronda': 'CUARTOS', 'numero_partido': 1, 'equipo_local_id': null, 'equipo_visitante_id': null },
          { 'torneo_id': tId, 'ronda': 'CUARTOS', 'numero_partido': 2, 'equipo_local_id': null, 'equipo_visitante_id': null },
          { 'torneo_id': tId, 'ronda': 'CUARTOS', 'numero_partido': 3, 'equipo_local_id': null, 'equipo_visitante_id': null },
          { 'torneo_id': tId, 'ronda': 'CUARTOS', 'numero_partido': 4, 'equipo_local_id': null, 'equipo_visitante_id': null },
          // Semis vacías
          { 'torneo_id': tId, 'ronda': 'SEMIFINALES', 'numero_partido': 1, 'equipo_local_id': null, 'equipo_visitante_id': null },
          { 'torneo_id': tId, 'ronda': 'SEMIFINALES', 'numero_partido': 2, 'equipo_local_id': null, 'equipo_visitante_id': null },
          // Final vacía
          { 'torneo_id': tId, 'ronda': 'FINAL', 'numero_partido': 1, 'equipo_local_id': null, 'equipo_visitante_id': null },
        ]);
      }

      if (partidosParaInsertar.isNotEmpty) {
        await supabase.from('liguilla_partidos').insert(partidosParaInsertar);
      }
      
      await fetchTorneoActivo();
      return true;
    } catch (e) {
      _error = 'Error generando bracket: $e';
      notifyListeners();
      return false;
    }
  }

  /// Edita un partido (para agendar fecha/hora o corregir algo)
  Future<bool> editarPartido(String id, Map<String, dynamic> data) async {
    try {
      await supabase.from('liguilla_partidos').update(data).eq('id', id);
      await fetchTorneoActivo();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Registra el resultado y avanza automáticamente al ganador a la siguiente ronda
  Future<bool> registrarResultado(String partidoId, int golesLocal, int golesVisitante) async {
    try {
      final p = _partidos.firstWhere((element) => element.id == partidoId);
      
      // Actualizar partido
      await supabase.from('liguilla_partidos').update({
        'goles_local': golesLocal,
        'goles_visitante': golesVisitante,
        'jugado': true,
        'estado': 'finalizado',
      }).eq('id', partidoId);

      // Si no es un empate, avanzar al ganador
      if (golesLocal != golesVisitante && p.ronda != 'FINAL') {
        final ganadorId = golesLocal > golesVisitante ? p.equipoLocalId : p.equipoVisitanteId;
        
        // Calcular a qué partido de la siguiente ronda va
        String nextRonda = '';
        if (p.ronda == 'OCTAVOS') nextRonda = 'CUARTOS';
        else if (p.ronda == 'CUARTOS') nextRonda = 'SEMIFINALES';
        else if (p.ronda == 'SEMIFINALES') nextRonda = 'FINAL';

        // El número de partido en la siguiente ronda es el índice actual / 2 redondeado hacia arriba
        // Ej: Octavos 1 y 2 van a Cuartos 1. Octavos 3 y 4 van a Cuartos 2.
        final nextPartidoNum = ((p.numeroPartido - 1) ~/ 2) + 1;
        
        // Es local si venía de un partido impar, visitante si venía de un par
        final isLocalInNext = p.numeroPartido % 2 != 0;

        // Actualizar el partido destino
        final nextPartidoData = isLocalInNext 
            ? {'equipo_local_id': int.parse(ganadorId!)}
            : {'equipo_visitante_id': int.parse(ganadorId!)};

        await supabase.from('liguilla_partidos')
            .update(nextPartidoData)
            .eq('torneo_id', _torneoActivo!.id)
            .eq('ronda', nextRonda)
            .eq('numero_partido', nextPartidoNum);
      }

      await fetchTorneoActivo();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Finaliza el torneo
  Future<bool> cerrarTorneo() async {
    if (_torneoActivo == null) return false;
    try {
      await supabase
          .from('liguilla_torneos')
          .update({'estado': 'finalizado'})
          .eq('id', _torneoActivo!.id);
      await fetchTorneoActivo();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
