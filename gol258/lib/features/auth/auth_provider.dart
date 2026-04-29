import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/supabase_config.dart';

enum AuthRole { none, usuario, admin }

class AuthProvider extends ChangeNotifier {
  AuthRole _role = AuthRole.none;
  String _userName = '';
  bool _loading = false;
  String? _error;

  AuthRole get role => _role;
  String get userName => _userName;
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
          .select('nombre, correo')
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_role', 'usuario');
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

  void enterAsEspectador() async {
    _role = AuthRole.usuario;
    _userName = 'Espectador';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_role', 'usuario');
    await prefs.setString('auth_name', 'Espectador');
    notifyListeners();
  }

  Future<void> logout() async {
    _role = AuthRole.none;
    _userName = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_role');
    await prefs.remove('auth_name');
    notifyListeners();
  }
}
