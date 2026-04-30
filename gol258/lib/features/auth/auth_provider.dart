import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/supabase_config.dart';

enum AuthRole { none, usuario, admin }

class AuthProvider extends ChangeNotifier {
  AuthRole _role = AuthRole.none;
  String _userName = '';
  String? _usuarioId;
  String? _equipoId;
  String? _jugadorId;
  bool _loading = false;
  String? _error;

  AuthRole get role => _role;
  String get userName => _userName;
  String? get usuarioId => _usuarioId;
  String? get equipoId => _equipoId;
  String? get jugadorId => _jugadorId;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAdmin => _role == AuthRole.admin;
  bool get isLoggedIn => _role != AuthRole.none;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString('auth_role');
    final savedName = prefs.getString('auth_name') ?? '';
    if (savedRole == 'admin') {
      _role = AuthRole.admin;
      _userName = savedName;
    } else if (savedRole == 'usuario') {
      _role = AuthRole.usuario;
      _userName = savedName;
      _usuarioId = prefs.getString('auth_uid');
      _equipoId = prefs.getString('auth_equipo_id');
      _jugadorId = prefs.getString('auth_jugador_id');
    }
    notifyListeners();
  }

  /// Login admin por nombre + contraseña (según diagrama ER: tabla "admin")
  Future<bool> loginAdmin(String nombre, String contrasena) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await supabase
          .from('admin')
          .select('nombre')
          .eq('nombre', nombre.trim())
          .eq('contrasena', contrasena.trim())
          .maybeSingle();

      if (response == null) {
        _error = 'Credenciales incorrectas';
        _loading = false;
        notifyListeners();
        return false;
      }
      _role = AuthRole.admin;
      _userName = response['nombre'] ?? nombre;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_role', 'admin');
      await prefs.setString('auth_name', _userName);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login usuario por correo + contraseña (según diagrama ER: tabla "usuario")
  Future<bool> loginUsuario(String correo, String contrasena) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await supabase
          .from('usuario')
          .select('id, nombre, correo')
          .eq('correo', correo.trim().toLowerCase())
          .eq('contrasena', contrasena.trim())
          .maybeSingle();

      if (response == null) {
        _error = 'Correo o contraseña incorrectos';
        _loading = false;
        notifyListeners();
        return false;
      }
      
      _role = AuthRole.usuario;
      _userName = response['nombre'] ?? correo;
      _usuarioId = response['id'].toString();

      // Check if user is linked to a team
      final eqResp = await supabase
          .from('usuario_equipos')
          .select('equipo_id')
          .eq('usuario_id', _usuarioId!)
          .maybeSingle();
      if (eqResp != null) _equipoId = eqResp['equipo_id'].toString();

      // Check if user is linked to a player
      final jugResp = await supabase
          .from('usuario_jugadores')
          .select('jugador_id')
          .eq('usuario_id', _usuarioId!)
          .maybeSingle();
      if (jugResp != null) _jugadorId = jugResp['jugador_id'].toString();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_role', 'usuario');
      await prefs.setString('auth_name', _userName);
      await prefs.setString('auth_uid', _usuarioId!);
      if (_equipoId != null) await prefs.setString('auth_equipo_id', _equipoId!);
      if (_jugadorId != null) await prefs.setString('auth_jugador_id', _jugadorId!);
      
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void enterAsEspectador() async {
    _role = AuthRole.usuario;
    _userName = 'Espectador';
    _usuarioId = null;
    _equipoId = null;
    _jugadorId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_role', 'usuario');
    await prefs.setString('auth_name', 'Espectador');
    await prefs.remove('auth_uid');
    await prefs.remove('auth_equipo_id');
    await prefs.remove('auth_jugador_id');
    notifyListeners();
  }

  Future<void> logout() async {
    _role = AuthRole.none;
    _userName = '';
    _usuarioId = null;
    _equipoId = null;
    _jugadorId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_role');
    await prefs.remove('auth_name');
    await prefs.remove('auth_uid');
    await prefs.remove('auth_equipo_id');
    await prefs.remove('auth_jugador_id');
    notifyListeners();
  }
}
