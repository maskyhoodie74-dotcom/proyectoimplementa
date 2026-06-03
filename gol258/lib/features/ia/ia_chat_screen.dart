import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../partidos/partidos_provider.dart';
import '../equipos/equipos_provider.dart';
import 'ia_provider.dart';

class IaChatScreen extends StatefulWidget {
  const IaChatScreen({super.key});

  @override
  State<IaChatScreen> createState() => _IaChatScreenState();
}

class _IaChatScreenState extends State<IaChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _typingController;

  final List<String> _sugerencias = [
    '¿Quién lidera la tabla?',
    '¿Cuál es el mejor goleador?',
    'Predice el próximo campeón 🏆',
    '¿Qué equipo tiene mejor defensa?',
    'Analiza la liguilla actual',
  ];

  @override
  void initState() {
    super.initState();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  String _buildContextoLiga() {
    final partidos = context.read<PartidosProvider>();
    final equipos = context.read<EquiposProvider>();
    final tabla = partidos.obtenerTablaConTendencia(equipos.equipos);
    if (tabla.isEmpty) return '';
    final resumen = tabla.take(5).map((e) {
      final s = e['stats'] as Map<String, dynamic>;
      return '${e['nombre']}: ${s['Pts']} pts';
    }).join(', ');
    return 'Top 5 tabla: $resumen';
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    FocusScope.of(context).unfocus();

    final ia = context.read<IaProvider>();
    final contexto = _buildContextoLiga();
    await ia.sendMessage(text, contextoLiga: contexto.isNotEmpty ? contexto : null);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ia = context.watch<IaProvider>();
    final messages = ia.messages;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: _buildAppBar(ia),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildWelcome()
                : _buildMessageList(messages, ia.isChatLoading),
          ),
          _buildInputArea(ia.isChatLoading),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(IaProvider ia) {
    return AppBar(
      backgroundColor: const Color(0xFF1A0610),
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(CupertinoIcons.chevron_left, color: AppColors.gold),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.maroonGradient,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                child: Text(
                  'Asistente GOL 258',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Gemini 2.5 Flash · En línea',
                    style: GoogleFonts.inter(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (ia.messages.isNotEmpty)
          IconButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ia.clearChat();
            },
            icon: const Icon(
              CupertinoIcons.trash,
              color: AppColors.textSecondary,
              size: 20,
            ),
            tooltip: 'Limpiar chat',
          ),
      ],
    );
  }

  // ─────────────── BIENVENIDA ───────────────

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.maroonGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.maroon.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 40)),
            ),
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (b) => AppColors.goldGradient.createShader(b),
            child: Text(
              '¡Hola! Soy tu\nAsistente IA',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pregúntame sobre la liga GOL 258,\nestadísticas, predicciones y más ⚽',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SUGERENCIAS RÁPIDAS',
              style: GoogleFonts.inter(
                color: AppColors.gold,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sugerencias.map(_buildSugerenciaChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSugerenciaChip(String text) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _controller.text = text;
        _send();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─────────────── LISTA DE MENSAJES ───────────────

  Widget _buildMessageList(List<ChatMessage> messages, bool isLoading) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == messages.length) return _buildTypingIndicator();
        return _buildMessageBubble(messages[i]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: AppColors.maroonGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF8B0000), Color(0xFF5C1A1A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : AppColors.bgCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        width: 0.5,
                      )
                    : Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: isUser
                  ? Text(
                      msg.text,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    )
                  : MarkdownBody(
                      data: msg.text,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        strong: GoogleFonts.inter(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        em: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser)
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'T',
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: AppColors.maroonGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 14)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _typingController,
                  builder: (BuildContext context, Widget? child) {
                    final double delay = i * 0.2;
                    final double val =
                        (_typingController.value - delay).clamp(0.0, 1.0);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 6 + val * 4,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.5 + val * 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── INPUT ───────────────

  Widget _buildInputArea(bool isLoading) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A0610),
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Pregunta sobre la liga...',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => isLoading ? null : _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isLoading
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    _send();
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: isLoading ? null : AppColors.maroonGradient,
                color: isLoading ? AppColors.bgCard : null,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: isLoading
                      ? AppColors.divider
                      : AppColors.gold.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.gold,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        CupertinoIcons.arrow_up,
                        color: AppColors.gold,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
