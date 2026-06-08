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

  Future<Map<String, String>?> crearEquipo(Map<String, dynamic> data) async {
    try {
      final nombre = data['nombre_equipo'] as String;

      // Verificar si el equipo ya existe
      final existing = await supabase
          .from('equipos')
          .select('id')
          .ilike('nombre_equipo', nombre.trim())
          .maybeSingle();
      if (existing != null) {
        _error = 'Ya existe un equipo con el nombre "$nombre".';
        notifyListeners();
        return null;
      }

      final slug = nombre.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final ts = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      final correo = 'equipo_${slug}_$ts@gol258.com';
      final contrasena = '123456';

      final usuarioResponse = await supabase.from('usuario').insert({
        'nombre': nombre,
        'correo': correo,
        'contrasena': contrasena,
      }).select().single();
      final usuarioId = usuarioResponse['id'];

      final equipoResponse = await supabase.from('equipos').insert(data).select().single();
      final equipoId = equipoResponse['id'];

      await supabase.from('usuario_equipos').insert({
        'usuario_id': usuarioId,
        'equipo_id': equipoId,
      });

      await fetchEquipos();
      return {'correo': correo, 'contrasena': contrasena};
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
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
