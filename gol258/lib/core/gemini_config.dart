/// Configuración de la API de Google Generative AI (Gemini)
/// 
/// ⚠️ NOTA: Cargado de forma segura desde variables de entorno (--dart-define)
/// o desde secrets.json (--dart-define-from-file) para evitar exponer la clave en Git.
const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

/// Modelo a utilizar — gemini-1.5-flash: rápido, eficiente, ideal para móvil
const String geminiModel = 'gemini-2.5-flash';
