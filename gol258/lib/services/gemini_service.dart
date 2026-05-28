import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/gemini_config.dart';

/// Servicio singleton para interactuar con la API de Google Generative AI (Gemini).
///
/// Provee:
/// - [analizarTabla] — análisis inteligente de la tabla de posiciones
/// - [predecirPartido] — predicción de resultado entre dos equipos
/// - [sendChatMessage] — chat con historial alternado user/model
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  late final GenerativeModel _model;

  // El chat se mantiene vivo entre mensajes para conservar el contexto
  ChatSession? _chatSession;

  bool _initialized = false;

  /// Inicializa el servicio. Debe llamarse antes de usar cualquier método.
  void init() {
    if (_initialized) return;
    _model = GenerativeModel(
      model: geminiModel,
      apiKey: geminiApiKey,
      systemInstruction: Content.system(
        'Eres el Asistente IA de GOL 258, la app de la liga de fútbol del '
        'CBTis 258. Eres experto en fútbol y en los datos de este torneo. '
        'Responde siempre en español, de forma amigable, concisa y con emojis '
        'cuando sea apropiado. Si el usuario pregunta algo fuera del fútbol o '
        'de la liga, redirige amablemente la conversación.',
      ),
      generationConfig: GenerationConfig(
        temperature: 0.8,
        maxOutputTokens: 600,
      ),
    );
    _initialized = true;
  }

  // ──────────────────────────────────────────────────────────────
  // Análisis de tabla de posiciones
  // ──────────────────────────────────────────────────────────────

  /// Genera un análisis breve e inteligente de la tabla de posiciones actual.
  Future<String> analizarTabla(List<Map<String, dynamic>> tablaData) async {
    _ensureInitialized();
    if (tablaData.isEmpty) return 'No hay datos de la tabla para analizar aún.';

    final tabla = tablaData
        .asMap()
        .entries
        .map((e) {
          final i = e.key + 1;
          final d = e.value;
          return '$i. ${d['nombre']} — PJ:${d['PJ']} PG:${d['PG']} '
              'PE:${d['PE']} PP:${d['PP']} Pts:${d['Pts']}';
        })
        .join('\n');

    final prompt =
        'Analiza brevemente esta tabla de posiciones de la liga de fútbol GOL 258 '
        'del CBTis 258. Destaca al líder, equipos en forma y cualquier dato '
        'interesante. Máximo 3 oraciones, usa emojis. Tabla:\n$tabla';

    try {
      // Para análisis usamos generateContent directo (sin historial)
      final analysisModel = GenerativeModel(
        model: geminiModel,
        apiKey: geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 512,
        ),
      );
      final response = await analysisModel.generateContent(
        [Content.text(prompt)],
      );
      return response.text?.trim() ?? 'No se pudo generar el análisis.';
    } catch (e) {
      return _handleError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Predicción de partido
  // ──────────────────────────────────────────────────────────────

  /// Predice el resultado de un partido entre dos equipos.
  Future<String> predecirPartido({
    required String equipo1,
    required Map<String, dynamic> stats1,
    required String equipo2,
    required Map<String, dynamic> stats2,
  }) async {
    _ensureInitialized();

    final prompt =
        'Predice el resultado del partido entre $equipo1 y $equipo2 '
        'en la liga GOL 258 del CBTis 258. '
        'Stats de $equipo1: PJ:${stats1['PJ']} PG:${stats1['PG']} '
        'PE:${stats1['PE']} PP:${stats1['PP']} Pts:${stats1['Pts']}. '
        'Stats de $equipo2: PJ:${stats2['PJ']} PG:${stats2['PG']} '
        'PE:${stats2['PE']} PP:${stats2['PP']} Pts:${stats2['Pts']}. '
        'Da una predicción corta y divertida con probabilidades y marcador sugerido. '
        'Máximo 2 oraciones.';

    try {
      final predModel = GenerativeModel(
        model: geminiModel,
        apiKey: geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.9,
          maxOutputTokens: 256,
        ),
      );
      final response = await predModel.generateContent(
        [Content.text(prompt)],
      );
      return response.text?.trim() ?? 'No se pudo generar la predicción.';
    } catch (e) {
      return _handleError(e);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Chat multi-turno (sesión persistente)
  // ──────────────────────────────────────────────────────────────

  /// Envía un mensaje al chat. La sesión se mantiene viva para
  /// conservar el contexto multi-turno completo.
  ///
  /// [userMessage] mensaje del usuario
  /// [contextoLiga] datos opcionales de la liga para contextualizar
  Future<String> sendChatMessage({
    required String userMessage,
    String? contextoLiga,
  }) async {
    _ensureInitialized();

    // Crear sesión la primera vez (o tras un reset)
    _chatSession ??= _model.startChat();

    final msgFinal = contextoLiga != null && contextoLiga.isNotEmpty
        ? '$userMessage\n\n[Contexto actual de la liga: $contextoLiga]'
        : userMessage;

    try {
      final response = await _chatSession!.sendMessage(
        Content.text(msgFinal),
      );
      return response.text?.trim() ?? 'No obtuve respuesta. Intenta de nuevo.';
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Reinicia la sesión de chat (borra el historial del modelo).
  void resetChat() {
    _chatSession = null;
  }

  // ──────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────

  void _ensureInitialized() {
    if (!_initialized) init();
  }

  String _handleError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('503') || msg.contains('unavailable') || msg.contains('high demand')) {
      return '☁️ Servidores de Google saturados temporalmente. Intenta de nuevo en unos segundos.';
    }
    if (msg.contains('quota') || msg.contains('429')) {
      return '⚠️ Límite de la API alcanzado. Intenta en unos momentos.';
    }
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection')) {
      return '📵 Sin conexión a internet. Verifica tu red.';
    }
    if (msg.contains('api_key') || msg.contains('401') || msg.contains('403')) {
      return '🔑 Error de autenticación con la API. Revisa la clave.';
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return '🔍 Modelo no disponible o error: ${e.toString()}';
    }
    return '❌ Error al conectar con Gemini: ${e.toString()}';
  }
}
