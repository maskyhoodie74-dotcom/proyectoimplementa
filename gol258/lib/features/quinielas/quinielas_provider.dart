import 'package:flutter/material.dart';
import '../../core/supabase_config.dart';
import '../../models/quiniela.dart';

class QuinielasProvider extends ChangeNotifier {
  List<Quiniela> _quinielas = [];
  bool _loading = false;
  String? _error;

  List<Quiniela> get quinielas => _quinielas;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchQuinielas(int usuarioId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await supabase
          .from('quinielas')
          .select()
          .eq('usuario_id', usuarioId);
      _quinielas = (data as List).map((e) => Quiniela.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> guardarQuiniela(Quiniela quiniela) async {
    try {
      final data = {
        'usuario_id': quiniela.usuarioId,
        'partido_id': quiniela.partidoId,
        'goles_local_pred': quiniela.golesLocalPred,
        'goles_visit_pred': quiniela.golesVisitPred,
      };

      // Insert or update
      await supabase.from('quinielas').upsert(data, onConflict: 'usuario_id, partido_id');
      await fetchQuinielas(quiniela.usuarioId);
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error guardando quiniela: $e');
      notifyListeners();
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerRanking() async {
    try {
      // Obtenemos los puntos agrupados por usuario
      final data = await supabase.from('quinielas').select('usuario_id, puntos_obtenidos, usuario:usuario_id(nombre)');
      
      final Map<int, Map<String, dynamic>> rankingMap = {};
      
      for (final row in data as List) {
        final uId = row['usuario_id'] as int;
        final pts = row['puntos_obtenidos'] as int;
        final nombre = row['usuario']?['nombre'] ?? 'Usuario Desconocido';
        
        if (!rankingMap.containsKey(uId)) {
          rankingMap[uId] = {'id': uId, 'nombre': nombre, 'puntos': 0};
        }
        rankingMap[uId]!['puntos'] = (rankingMap[uId]!['puntos'] as int) + pts;
      }
      
      final ranking = rankingMap.values.toList();
      ranking.sort((a, b) => (b['puntos'] as int).compareTo(a['puntos'] as int));
      
      return ranking;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }
}
