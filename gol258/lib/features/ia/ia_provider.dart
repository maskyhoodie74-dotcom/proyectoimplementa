import 'package:flutter/foundation.dart';
import '../../services/gemini_service.dart';

/// Modelo de un mensaje en el chat IA.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Provider que gestiona el estado de la IA: chat, análisis de tabla y predicciones.
class IaProvider extends ChangeNotifier {
  IaProvider() {
    GeminiService.instance.init();
  }

  // ──────────────── Estado del chat ────────────────

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _isChatLoading = false;
  bool get isChatLoading => _isChatLoading;

  // ──────────────── Estado del análisis de tabla ────────────────

  String? _analisisTabla;
  String? get analisisTabla => _analisisTabla;

  bool _isAnalysisLoading = false;
  bool get isAnalysisLoading => _isAnalysisLoading;

  bool _analisisYaCargado = false;

  // ──────────────────────────────────────────────────────────────
  // Chat
  // ──────────────────────────────────────────────────────────────

  /// Envía un mensaje del usuario y obtiene respuesta de Gemini.
  /// [contextoLiga] pasa datos actuales de la liga al modelo.
  Future<void> sendMessage(String text, {String? contextoLiga}) async {
    if (text.trim().isEmpty || _isChatLoading) return;

    final userMsg = ChatMessage(text: text.trim(), isUser: true);
    _messages.add(userMsg);
    _isChatLoading = true;
    notifyListeners();

    try {
      final response = await GeminiService.instance.sendChatMessage(
        userMessage: text.trim(),
        contextoLiga: contextoLiga,
      );

      _messages.add(ChatMessage(text: response, isUser: false));
    } catch (e) {
      _messages.add(ChatMessage(
        text: '❌ Error al conectar con la IA. Verifica tu conexión.',
        isUser: false,
      ));
    }

    _isChatLoading = false;
    notifyListeners();
  }

  /// Limpia el historial del chat (UI + sesión del modelo).
  void clearChat() {
    _messages.clear();
    GeminiService.instance.resetChat();
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────
  // Análisis de tabla
  // ──────────────────────────────────────────────────────────────

  /// Genera o refresca el análisis IA de la tabla de posiciones.
  Future<void> analizarTabla(
    List<Map<String, dynamic>> tablaData, {
    bool forzar = false,
  }) async {
    if (_isAnalysisLoading) return;
    if (_analisisYaCargado && !forzar) return;

    _isAnalysisLoading = true;
    _analisisTabla = null;
    notifyListeners();

    try {
      _analisisTabla = await GeminiService.instance.analizarTabla(tablaData);
      _analisisYaCargado = true;
    } catch (e) {
      _analisisTabla = '❌ No se pudo obtener el análisis.';
    }

    _isAnalysisLoading = false;
    notifyListeners();
  }

  /// Genera una predicción de partido entre dos equipos.
  Future<String> predecirPartido({
    required String equipo1,
    required Map<String, dynamic> stats1,
    required String equipo2,
    required Map<String, dynamic> stats2,
  }) async {
    return GeminiService.instance.predecirPartido(
      equipo1: equipo1,
      stats1: stats1,
      equipo2: equipo2,
      stats2: stats2,
    );
  }
}
