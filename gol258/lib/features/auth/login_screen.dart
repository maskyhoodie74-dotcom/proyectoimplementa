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
  bool _obscure = true;
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
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.loginAdmin(
        _usuarioCtrl.text.trim(), _claveCtrl.text.trim());
    if (ok && mounted) context.go('/home');
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
                        // LOGO
                        _buildLogo(),
                        const SizedBox(height: 28),
                        // TITLE
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
                        const SizedBox(height: 32),
                        // LOGIN CARD
                        _buildLoginCard(auth),
                        const SizedBox(height: 20),
                        // ESPECTADOR
                        _buildEspectadorButton(),
                        const SizedBox(height: 32),
                        // FOOTER
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
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text('PERSONAL\nAUTORIZADO',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
                height: 1.1,
              )),
          const SizedBox(height: 6),
          Text('Ingrese sus credenciales para gestionar la liga.',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          // Usuario
          Text('ID / USUARIO',
              style: GoogleFonts.inter(
                color: AppColors.gold,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              )),
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
          // Clave
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CLAVE DE SEGURIDAD',
                  style: GoogleFonts.inter(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  )),
              Text('¿Olvidó la clave?',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  )),
            ],
          ),
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
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _login(),
          ),
          if (auth.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(auth.error!,
                        style: GoogleFonts.inter(
                            color: AppColors.error, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: auth.loading ? null : AppColors.goldGradient,
              color: auth.loading ? AppColors.bgCardLight : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: auth.loading ? null : AppColors.goldGlow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onPressed: auth.loading ? null : _login,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: auth.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: AppColors.gold, strokeWidth: 2))
                        : Text('AUTENTICAR',
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
          ),
        ],
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
          onPressed: _enterAsEspectador,
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
