import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../features/ia/ia_provider.dart';

/// Tarjeta de análisis IA que muestra un insight generado por Gemini
/// sobre la tabla de posiciones actual.
class IaInsightCard extends StatelessWidget {
  /// Datos de la tabla actual para contextualizar el análisis.
  final List<Map<String, dynamic>> tablaData;

  const IaInsightCard({super.key, required this.tablaData});

  @override
  Widget build(BuildContext context) {
    final ia = context.watch<IaProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E0A0A), Color(0xFF1C1C1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.maroon.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                // Icono IA con brillo
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppColors.maroonGradient,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                  ),
                  child: const Text('✨', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ShaderMask(
                            shaderCallback: (b) =>
                                AppColors.goldGradient.createShader(b),
                            child: Text(
                              'ANÁLISIS IA',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Gemini',
                              style: GoogleFonts.inter(
                                color: AppColors.gold,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Generado por Google AI',
                        style: GoogleFonts.inter(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón refrescar
                GestureDetector(
                  onTap: ia.isAnalysisLoading
                      ? null
                      : () => ia.analizarTabla(tablaData, forzar: true),
                  child: AnimatedRotation(
                    turns: ia.isAnalysisLoading ? 1 : 0,
                    duration: const Duration(seconds: 1),
                    child: Icon(
                      CupertinoIcons.refresh,
                      color: ia.isAnalysisLoading
                          ? AppColors.textTertiary
                          : AppColors.gold,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(14),
            child: ia.isAnalysisLoading
                ? _buildShimmer()
                : ia.analisisTabla != null
                    ? _esError(ia.analisisTabla)
                        ? _buildErrorState(context, ia, ia.analisisTabla!)
                        : MarkdownBody(
                            data: ia.analisisTabla!,
                            styleSheet: MarkdownStyleSheet(
                              p: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                height: 1.5,
                              ),
                              strong: GoogleFonts.inter(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          )
                    : _buildEmptyAnalysisState(context, ia),
          ),
        ],
      ),
    );
  }

  bool _esError(String? texto) {
    if (texto == null) return false;
    return texto.startsWith('⚠️') ||
        texto.startsWith('📵') ||
        texto.startsWith('🔑') ||
        texto.startsWith('🔍') ||
        texto.startsWith('❌');
  }

  Widget _buildErrorState(BuildContext context, IaProvider ia, String errorText) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: AppColors.gold.withValues(alpha: 0.8),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'No se pudo generar el análisis',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              errorText,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => ia.analizarTabla(tablaData, forzar: true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.refresh,
                    color: AppColors.gold,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Reintentar análisis',
                    style: GoogleFonts.inter(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyAnalysisState(BuildContext context, IaProvider ia) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => AppColors.goldGradient.createShader(bounds),
              child: const Icon(
                CupertinoIcons.sparkles,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Análisis Táctico con IA',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Obtén un informe inmediato sobre el líder, sorpresas y tendencias de la liga usando Google Gemini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: ia.isAnalysisLoading
                ? null
                : () => ia.analizarTabla(tablaData),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.bolt_fill,
                    color: AppColors.bgDark,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'GENERAR INFORME',
                    style: GoogleFonts.inter(
                      color: AppColors.bgDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmerLine(double.infinity),
        const SizedBox(height: 6),
        _shimmerLine(double.infinity),
        const SizedBox(height: 6),
        _shimmerLine(180),
      ],
    );
  }

  Widget _shimmerLine(double width) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (BuildContext context, double val, Widget? child) => Container(
        height: 12,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.bgCardLight.withValues(alpha: val),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
