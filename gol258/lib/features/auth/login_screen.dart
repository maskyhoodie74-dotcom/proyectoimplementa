import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
    with TickerProviderStateMixin {
  final _usuarioCtrl = TextEditingController();
  final _claveCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _claveJugadorCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureJugador = true;
  int _tabIndex = 0;

  late AnimationController _fadeCtrl;
  late AnimationController _shineCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _shineAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _shineCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _shineAnim = Tween<double>(begin: -1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _shineCtrl, curve: Curves.easeInOut));

    _fadeCtrl.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _shineCtrl.repeat(period: const Duration(seconds: 4));
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _shineCtrl.dispose();
    _usuarioCtrl.dispose();
    _claveCtrl.dispose();
    _correoCtrl.dispose();
    _claveJugadorCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginAdmin() async {
    final auth = context.read<AuthProvider>();
    final ok =
        await auth.loginAdmin(_usuarioCtrl.text.trim(), _claveCtrl.text.trim());
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
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildBackground(),
          // Decorative elements
          _buildDecoElements(isMobile),
          // Content
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
                          SizedBox(height: isMobile ? 20 : 40),
                          _buildLogo(),
                          const SizedBox(height: 24),
                          _buildBrandText(),
                          const SizedBox(height: 36),
                          _buildTabSelector(),
                          const SizedBox(height: 20),
                          _buildLoginCard(auth),
                          const SizedBox(height: 16),
                          _buildEspectadorButton(),
                          const SizedBox(height: 32),
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

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.7, -0.8),
          radius: 1.8,
          colors: [
            Color(0xFF3A0B17),
            Color(0xFF150208),
            Color(0xFF000000),
          ],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildDecoElements(bool isMobile) {
    return Stack(
      children: [
        // Gold circle top-right
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.gold.withOpacity(0.15),
                  AppColors.gold.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
        // Maroon circle bottom-left
        Positioned(
          bottom: -100,
          left: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.maroon.withOpacity(0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _shineAnim,
      builder: (context, child) {
        return Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.35),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo_no_bg.png',
                  width: 130,
                  height: 130,
                  fit: BoxFit.contain,
                ),
              ),
              // Shine effect
              ClipOval(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(_shineAnim.value * 200, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.18),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrandText() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppColors.goldGradient.createShader(bounds),
          child: Text(
            'CAMPEONATO GOL 258',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 24,
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
            fontSize: 13,
            letterSpacing: 1,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 0.5),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          _buildTab(0, CupertinoIcons.shield_fill, 'ADMIN'),
          _buildTab(1, CupertinoIcons.sportscourt_fill, 'JUGADOR'),
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
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.goldGradient : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? AppColors.goldGlowSubtle : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? AppColors.bgDark : AppColors.textSecondary,
                  size: 16),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? AppColors.bgDark : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
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
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 0.5),
            boxShadow: AppColors.glassShadow,
          ),
          padding: const EdgeInsets.all(28),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _tabIndex == 0
                ? _buildAdminForm(auth)
                : _buildJugadorForm(auth),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminForm(AuthProvider auth) {
    return Column(
      key: const ValueKey('admin'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormHeader(
          icon: CupertinoIcons.shield_fill,
          title: 'Personal\nAutorizado',
          subtitle: 'Credenciales de administrador',
        ),
        const SizedBox(height: 24),
        _buildFieldLabel('ID / USUARIO'),
        const SizedBox(height: 8),
        TextField(
          controller: _usuarioCtrl,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Ingrese ID',
            prefixIcon: Icon(CupertinoIcons.person, size: 18),
          ),
        ),
        const SizedBox(height: 16),
        _buildFieldLabel('CLAVE DE SEGURIDAD'),
        const SizedBox(height: 8),
        TextField(
          controller: _claveCtrl,
          obscureText: _obscure,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(CupertinoIcons.lock, size: 18),
            suffixIcon: _buildObscureButton(_obscure,
                () => setState(() => _obscure = !_obscure)),
          ),
          onSubmitted: (_) => _loginAdmin(),
        ),
        _buildErrorWidget(auth),
        const SizedBox(height: 24),
        _buildActionButton(auth.loading, 'AUTENTICAR', _loginAdmin),
      ],
    );
  }

  Widget _buildJugadorForm(AuthProvider auth) {
    return Column(
      key: const ValueKey('jugador'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFormHeader(
          icon: CupertinoIcons.sportscourt_fill,
          title: 'Acceso\nJugador',
          subtitle: 'Correo y contraseña de jugador',
        ),
        const SizedBox(height: 24),
        _buildFieldLabel('CORREO ELECTRÓNICO'),
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
        _buildFieldLabel('CONTRASEÑA'),
        const SizedBox(height: 8),
        TextField(
          controller: _claveJugadorCtrl,
          obscureText: _obscureJugador,
          style: GoogleFonts.inter(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(CupertinoIcons.lock, size: 18),
            suffixIcon: _buildObscureButton(_obscureJugador,
                () => setState(() => _obscureJugador = !_obscureJugador)),
          ),
          onSubmitted: (_) => _loginJugador(),
        ),
        _buildErrorWidget(auth),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.maroonDeep.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 0.5),
          ),
          child: Row(children: [
            const Icon(CupertinoIcons.info_circle_fill,
                color: AppColors.gold, size: 15),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'El coordinador te proporcionará tus credenciales al registrarte.',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        _buildActionButton(auth.loading, 'INGRESAR', _loginJugador),
      ],
    );
  }

  Widget _buildFormHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: AppColors.maroonGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 0.5),
          ),
          child: Icon(icon, color: AppColors.gold, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: AppColors.gold,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildObscureButton(bool obscure, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
        size: 18,
        color: AppColors.textSecondary,
      ),
      onPressed: onTap,
    );
  }

  Widget _buildErrorWidget(AuthProvider auth) {
    if (auth.error == null) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withOpacity(0.4), width: 0.5),
          ),
          child: Row(children: [
            const Icon(CupertinoIcons.xmark_circle_fill,
                color: AppColors.error, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(auth.error!,
                  style: GoogleFonts.inter(
                      color: AppColors.error, fontSize: 12, height: 1.4)),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildActionButton(bool loading, String label, VoidCallback onTap) {
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
          splashColor: Colors.white.withOpacity(0.1),
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

  Widget _buildEspectadorButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _enterAsEspectador,
        splashColor: AppColors.gold.withOpacity(0.1),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.bgCard.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withOpacity(0.25), width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.eye,
                  color: AppColors.gold, size: 17),
              const SizedBox(width: 8),
              Text(
                'CONTINUAR COMO ESPECTADOR',
                style: GoogleFonts.inter(
                  color: AppColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.divider.withOpacity(0.4))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '⚽',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(child: Divider(color: AppColors.divider.withOpacity(0.4))),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'LIGA GOL 258 • COBRAS • VER 1.0',
          style: GoogleFonts.inter(
            color: AppColors.textTertiary,
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
