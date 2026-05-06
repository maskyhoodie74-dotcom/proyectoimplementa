import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usuarioCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _claveJugadorCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureJugador = true;
  int _tabIndex = 0; // 0 = Admin, 1 = Jugador
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _usuarioCtrl.dispose();
    _claveCtrl.dispose();
    _correoCtrl.dispose();
    _claveJugadorCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginAdmin() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginAdmin(
        _usuarioCtrl.text.trim(), _claveCtrl.text.trim());
    if (ok && mounted) context.go('/admin');
  }

  Future<void> _loginJugador() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginUsuario(
        _correoCtrl.text.trim(), _claveJugadorCtrl.text.trim());
    if (ok && mounted) {
      if (auth.jugadorId != null) {
        context.go('/jugador-dashboard');
      } else {
        context.go('/home');
      }
    }
  }

  void _enterAsEspectador() {
    context.read<AuthProvider>().enterAsEspectador();
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.5,
            colors: [
              AppColors.maroonDark,
              AppColors.bgDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _buildLogo(),
                        const SizedBox(height: 28),
                        Text(
                          'ACCESO AL\nCAMPEONATO',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gold,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 28),
                        // TAB SELECTOR
                        _buildTabSelector(),
                        const SizedBox(height: 20),
                        // LOGIN CARD
                        _buildLoginCard(auth),
                        const SizedBox(height: 20),
                        // ESPECTADOR
                        _buildEspectadorButton(),
                        const SizedBox(height: 32),
                        Text(
                          'SISTEMA DE GESTIÓN DE LIGA GOL 258 • VER 1.0',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'CBTis 258   •   COBRAS',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.maroonDark,
        border: Border.all(color: AppColors.gold, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚽', style: TextStyle(fontSize: 32)),
            Text(
              'GOL',
              style: GoogleFonts.inter(
                color: AppColors.gold,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            Text(
              '258',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _buildTab(0, Icons.admin_panel_settings_outlined, 'ADMIN'),
          _buildTab(1, Icons.sports_soccer_outlined, 'JUGADOR'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.goldGradient : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? AppColors.goldGlow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? AppColors.bgDark : AppColors.textSecondary,
                  size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? AppColors.bgDark : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(AuthProvider auth) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCardLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            boxShadow: AppColors.glassShadow,
          ),
          padding: const EdgeInsets.all(24),
          child: _tabIndex == 0 ? _buildAdminForm(auth) : _buildJugadorForm(auth),
        ),
      ),
    );
  }

  Widget _buildAdminForm(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 3, height: 40,
              decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('PERSONAL\nAUTORIZADO',
                style: GoogleFonts.inter(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary, letterSpacing: -0.5, height: 1.1)),
          ]),
        ]),
        const SizedBox(height: 6),
        Text('Ingrese sus credenciales de administrador.',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        Text('ID / USUARIO',
            style: GoogleFonts.inter(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: _usuarioCtrl,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Ingrese ID',
            prefixIcon: Icon(Icons.person_outline, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        Text('CLAVE DE SEGURIDAD',
            style: GoogleFonts.inter(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: _claveCtrl,
          obscureText: _obscure,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18, color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          onSubmitted: (_) => _loginAdmin(),
        ),
        _buildErrorWidget(auth),
        const SizedBox(height: 20),
        _buildActionButton(auth.loading, 'AUTENTICAR COMO ADMIN', _loginAdmin),
      ],
    );
  }

  Widget _buildJugadorForm(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 3, height: 40,
              decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ACCESO\nJUGADOR',
                style: GoogleFonts.inter(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary, letterSpacing: -0.5, height: 1.1)),
          ]),
        ]),
        const SizedBox(height: 6),
        Text('Ingresa con tu correo y contraseña de jugador.',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        Text('CORREO',
            style: GoogleFonts.inter(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: _correoCtrl,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'jugador@gol258.com',
            prefixIcon: Icon(Icons.email_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        Text('CONTRASEÑA',
            style: GoogleFonts.inter(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: _claveJugadorCtrl,
          obscureText: _obscureJugador,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureJugador ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18, color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscureJugador = !_obscureJugador),
            ),
          ),
          onSubmitted: (_) => _loginJugador(),
        ),
        _buildErrorWidget(auth),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.maroonDark.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gold.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, color: AppColors.gold, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'El coordinador te proporcionará tu correo y contraseña al registrarte.',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
            )),
          ]),
        ),
        const SizedBox(height: 20),
        _buildActionButton(auth.loading, 'INGRESAR COMO JUGADOR', _loginJugador),
      ],
    );
  }

  Widget _buildErrorWidget(AuthProvider auth) {
    if (auth.error == null) return const SizedBox.shrink();
    return Column(children: [
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(auth.error!,
              style: GoogleFonts.inter(color: AppColors.error, fontSize: 12))),
        ]),
      ),
    ]);
  }

  Widget _buildActionButton(bool loading, String label, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: loading ? null : AppColors.goldGradient,
        color: loading ? AppColors.bgCardLight : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: loading ? null : AppColors.goldGlow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: loading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2))
                  : Text(label,
                      style: GoogleFonts.inter(
                        color: AppColors.bgDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      )),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEspectadorButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgCardLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _enterAsEspectador,
          splashColor: AppColors.gold.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.remove_red_eye_outlined,
                    color: AppColors.gold, size: 18),
                const SizedBox(width: 8),
                Text(
                  'ENTRAR COMO ESPECTADOR',
                  style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
