import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../../core/theme.dart';

// ─── PANTALLA PRINCIPAL ───────────────────────────────────────────────────────
// Ahora la pantalla de inicio muestra una bienvenida para espectadores.
// El login de admin está oculto en el icono de tuerca (⚙️) en la esquina.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _shineCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _shineAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _shineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _shineAnim = Tween<double>(begin: -1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _shineCtrl, curve: Curves.easeInOut));

    _fadeCtrl.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _shineCtrl.repeat(period: const Duration(seconds: 4));
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _shineCtrl.dispose();
    super.dispose();
  }

  void _enterAsEspectador() {
    context.read<AuthProvider>().enterAsEspectador();
    context.go('/home');
  }

  void _openAdminLogin() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AdminLoginSheet(),
    );
  }

  void _openRegistro() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RegistroSheet(),
    );
  }

  void _openJugadorLogin() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _JugadorLoginSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          // ── Fondo degradado ──
          _buildBackground(),
          // ── Círculos decorativos ──
          _buildDecoCircles(),
          // ── Tuerca Admin (esquina superior derecha) ──
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Tooltip(
                  message: 'Acceso personal autorizado',
                  child: GestureDetector(
                    onTap: _openAdminLogin,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.divider,
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.settings,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ── Contenido principal ──
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 40,
                    vertical: 24,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        children: [
                          SizedBox(height: isMobile ? 32 : 52),
                          // Logo
                          _buildLogo(),
                          const SizedBox(height: 20),
                          // Brand
                          _buildBrandText(),
                          const SizedBox(height: 48),
                          // Botón principal — Continuar como espectador
                          _buildEspectadorHero(),
                          const SizedBox(height: 16),
                          // Crear cuenta
                          _buildCrearCuentaBtn(),
                          const SizedBox(height: 12),
                          // Ya tengo cuenta (jugador)
                          _buildJugadorLoginBtn(),
                          const SizedBox(height: 40),
                          _buildFooter(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FONDO ──────────────────────────────────────────
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.5, -0.6),
          radius: 1.8,
          colors: [Color(0xFF3A0B17), Color(0xFF150208), Color(0xFF000000)],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildDecoCircles() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.gold.withValues(alpha: 0.12),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.maroon.withValues(alpha: 0.22),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ── LOGO ──────────────────────────────────────────
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _shineAnim,
      builder: (_, __) => Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.3),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Image.asset(
                'assets/images/logo_no_bg.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            ClipOval(
              child: Positioned.fill(
                child: Transform.translate(
                  offset: Offset(_shineAnim.value * 200, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.16),
                        Colors.transparent,
                      ], stops: const [
                        0,
                        0.5,
                        1,
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandText() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: Text(
            'CAMPEONATO GOL 258',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sistema Oficial • CBTis 258',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            letterSpacing: 1,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── BOTONES PRINCIPALES ──────────────────────────────────────────
  Widget _buildEspectadorHero() {
    return GestureDetector(
      onTap: _enterAsEspectador,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.goldGlow,
        ),
        child: Column(
          children: [
            const Text('⚽', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text(
              'VER LIGA',
              style: GoogleFonts.inter(
                color: AppColors.bgDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Entrar como espectador',
              style: GoogleFonts.inter(
                color: AppColors.bgDark.withValues(alpha: 0.65),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrearCuentaBtn() {
    return GestureDetector(
      onTap: _openRegistro,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.person_crop_circle_badge_plus,
                color: AppColors.gold, size: 20),
            const SizedBox(width: 10),
            Text(
              'CREAR CUENTA',
              style: GoogleFonts.inter(
                color: AppColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJugadorLoginBtn() {
    return GestureDetector(
      onTap: _openJugadorLogin,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.sportscourt_fill,
                color: AppColors.textSecondary, size: 14),
            const SizedBox(width: 7),
            Text(
              'Ya tengo cuenta de jugador',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'LIGA GOL 258 • COBRAS • VER 1.0',
      style: GoogleFonts.inter(
        color: AppColors.textTertiary,
        fontSize: 10,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ─── SHEET: LOGIN ADMIN ───────────────────────────────────────────────────────
class _AdminLoginSheet extends StatefulWidget {
  const _AdminLoginSheet();

  @override
  State<_AdminLoginSheet> createState() => _AdminLoginSheetState();
}

class _AdminLoginSheetState extends State<_AdminLoginSheet> {
  final _usuarioCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _claveCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginAdmin(
        _usuarioCtrl.text.trim(), _claveCtrl.text.trim());
    if (ok && mounted) {
      Navigator.pop(context);
      context.go('/admin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgSecondary.withValues(alpha: 0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.maroonGradient,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            width: 0.5),
                      ),
                      child: const Icon(CupertinoIcons.shield_fill,
                          color: AppColors.gold, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal Autorizado',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Acceso exclusivo para administradores',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Campo usuario
                _sheetLabel('ID / USUARIO'),
                const SizedBox(height: 8),
                TextField(
                  controller: _usuarioCtrl,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Ingrese ID de administrador',
                    prefixIcon: Icon(CupertinoIcons.person, size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                _sheetLabel('CLAVE DE SEGURIDAD'),
                const SizedBox(height: 8),
                TextField(
                  controller: _claveCtrl,
                  obscureText: _obscure,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(CupertinoIcons.lock, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(message: auth.error!),
                ],
                const SizedBox(height: 24),
                _ActionBtn(
                  loading: auth.loading,
                  label: 'AUTENTICAR',
                  onTap: _login,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
          color: AppColors.gold,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      );
}

// ─── SHEET: REGISTRO ESPECTADOR ───────────────────────────────────────────────
class _RegistroSheet extends StatefulWidget {
  const _RegistroSheet();

  @override
  State<_RegistroSheet> createState() => _RegistroSheetState();
}

class _RegistroSheetState extends State<_RegistroSheet> {
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  static const _dominiosValidos = [
    '@gmail.com', '@hotmail.com', '@yahoo.com', '@cbtis258.edu.mx'
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _claveCtrl.dispose();
    super.dispose();
  }

  bool _correoValido(String correo) {
    return _dominiosValidos.any((d) => correo.toLowerCase().endsWith(d));
  }

  Future<void> _registrar() async {
    final nombre = _nombreCtrl.text.trim();
    final correo = _correoCtrl.text.trim();
    final clave = _claveCtrl.text.trim();

    if (nombre.isEmpty || correo.isEmpty || clave.isEmpty) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }
    if (nombre.split(' ').length > 30) {
      setState(() => _error = 'El nombre es demasiado largo');
      return;
    }
    if (correo.length > 100 || correo.split(' ').length > 1) {
      setState(() => _error = 'Correo no válido');
      return;
    }
    if (!_correoValido(correo)) {
      setState(() => _error =
          'Solo se permiten correos @gmail.com, @hotmail.com, @yahoo.com o @cbtis258.edu.mx');
      return;
    }
    if (clave.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (clave.length > 30) {
      setState(() => _error = 'La contraseña no puede exceder 30 caracteres');
      return;
    }

    setState(() { _loading = true; _error = null; });
    final ok = await context
        .read<AuthProvider>()
        .registrarEspectador(nombre: nombre, correo: correo, contrasena: clave);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      context.go('/home');
    } else {
      setState(() {
        _error = context.read<AuthProvider>().error ?? 'Error al registrarse';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgSecondary.withValues(alpha: 0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.maroonGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                            CupertinoIcons.person_crop_circle_badge_plus,
                            color: AppColors.gold,
                            size: 22),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Crear Cuenta',
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Únete como espectador de la liga',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _label('NOMBRE COMPLETO'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nombreCtrl,
                    maxLength: 60,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Tu nombre',
                      prefixIcon: Icon(CupertinoIcons.person, size: 18),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _label('CORREO ELECTRÓNICO'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _correoCtrl,
                    keyboardType: TextInputType.emailAddress,
                    maxLength: 100,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'usuario@gmail.com',
                      prefixIcon: Icon(CupertinoIcons.mail, size: 18),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Solo: @gmail.com · @hotmail.com · @yahoo.com · @cbtis258.edu.mx',
                    style: GoogleFonts.inter(
                        color: AppColors.textTertiary, fontSize: 10),
                  ),
                  const SizedBox(height: 16),
                  _label('CONTRASEÑA'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _claveCtrl,
                    obscureText: _obscure,
                    maxLength: 30,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: '6–30 caracteres',
                      prefixIcon: const Icon(CupertinoIcons.lock, size: 18),
                      counterText: '',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? CupertinoIcons.eye_slash
                              : CupertinoIcons.eye,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _ErrorBanner(message: _error!),
                  ],
                  const SizedBox(height: 24),
                  _ActionBtn(
                    loading: _loading,
                    label: 'CREAR CUENTA',
                    onTap: _registrar,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          color: AppColors.gold,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      );
}

// ─── SHEET: LOGIN JUGADOR ─────────────────────────────────────────────────────
class _JugadorLoginSheet extends StatefulWidget {
  const _JugadorLoginSheet();

  @override
  State<_JugadorLoginSheet> createState() => _JugadorLoginSheetState();
}

class _JugadorLoginSheetState extends State<_JugadorLoginSheet> {
  final _correoCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _claveCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginUsuario(
        _correoCtrl.text.trim(), _claveCtrl.text.trim());
    if (ok && mounted) {
      Navigator.pop(context);
      if (auth.jugadorId != null) {
        context.go('/jugador-dashboard');
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgSecondary.withValues(alpha: 0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.maroonGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(CupertinoIcons.sportscourt_fill,
                          color: AppColors.gold, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Acceso Jugador',
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        Text('Ingresa con tus credenciales',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _label('CORREO ELECTRÓNICO'),
                const SizedBox(height: 8),
                TextField(
                  controller: _correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'jugador@gol258.com',
                    prefixIcon: Icon(CupertinoIcons.mail, size: 18),
                  ),
                ),
                const SizedBox(height: 16),
                _label('CONTRASEÑA'),
                const SizedBox(height: 8),
                TextField(
                  controller: _claveCtrl,
                  obscureText: _obscure,
                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(CupertinoIcons.lock, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onSubmitted: (_) => _login(),
                ),
                // Info
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.maroonDeep.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        width: 0.5),
                  ),
                  child: Row(children: [
                    const Icon(CupertinoIcons.info_circle_fill,
                        color: AppColors.gold, size: 15),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'El coordinador te proporcionará tus credenciales al registrarte.',
                        style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4),
                      ),
                    ),
                  ]),
                ),
                if (auth.error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(message: auth.error!),
                ],
                const SizedBox(height: 24),
                _ActionBtn(
                  loading: auth.loading,
                  label: 'INGRESAR',
                  onTap: _login,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          color: AppColors.gold,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      );
}

// ─── WIDGETS COMPARTIDOS ──────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(children: [
        const Icon(CupertinoIcons.xmark_circle_fill,
            color: AppColors.error, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: GoogleFonts.inter(
                  color: AppColors.error, fontSize: 12, height: 1.4)),
        ),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final bool loading;
  final String label;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.loading, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: loading ? null : AppColors.goldGradient,
        color: loading ? AppColors.bgCardLight : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: loading ? null : AppColors.goldGlow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 17),
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: AppColors.gold, strokeWidth: 2))
                  : Text(
                      label,
                      style: GoogleFonts.inter(
                        color: AppColors.bgDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
