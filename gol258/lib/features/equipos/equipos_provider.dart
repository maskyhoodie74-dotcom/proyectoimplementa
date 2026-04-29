import 'package:flutter/material.dart';
import '../../core/supabase_config.dart';
import '../../models/equipo.dart';

class EquiposProvider extends ChangeNotifier {
  List<Equipo> _equipos = [];
  bool _loading = false;
  String? _error;

  List<Equipo> get equipos => _equipos;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchEquipos() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await supabase
          .from('equipos')
          .select('*')
          .order('nombre_equipo');
      _equipos = (data as List).map((e) => Equipo.fromMap(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> crearEquipo(Map<String, dynamic> data) async {
    try {
      await supabase.from('equipos').insert(data);
      await fetchEquipos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> editarEquipo(String id, Map<String, dynamic> data) async {
    try {
      await supabase.from('equipos').update(data).eq('id', id);
      await fetchEquipos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarEquipo(String id) async {
    try {
      await supabase.from('equipos').delete().eq('id', id);
      await fetchEquipos();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
