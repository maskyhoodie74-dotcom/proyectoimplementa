# 🛡️ Guía de Seguridad y Buenas Prácticas — GOL 258

> Documento generado a partir de los errores y aprendizajes del desarrollo del proyecto.  
> **Leelo ANTES de hacer cualquier cambio importante o push a Git.**

---

## ⚠️ 1. NUNCA subas claves de API al repositorio

### El error
Se cometió el error de incluir directamente la clave de Google Gemini y la URL/anon key de Supabase dentro de los archivos de código fuente Dart (`.dart`). Estos archivos estaban siendo rastreados por Git, lo que significa que cualquier `git push` a GitHub o similar **habría expuesto las claves públicamente**, permitiendo que terceros las roben y las usen a tu costo.

### ¿Qué archivos tenían claves expuestas?
- `lib/core/gemini_config.dart` → API Key de Google Gemini
- `lib/core/supabase_config.dart` → URL y anon key de Supabase

### La solución correcta
1. **Crea un archivo `secrets.json`** en la raíz del proyecto con las claves:
   ```json
   {
     "GEMINI_API_KEY": "tu_clave_aqui"
   }
   ```
2. **Agrégalo al `.gitignore`** para que Git lo ignore:
   ```
   # Local secrets
   secrets.json
   ```
3. **Léelo en el código con `String.fromEnvironment`**:
   ```dart
   const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
   ```
4. **Lanza la app pasando el archivo de secretos**:
   ```bash
   flutter run --dart-define-from-file=secrets.json
   ```

### Regla de oro
> 🔴 Si ves una clave, token, password o URL privada escrita directamente en el código Dart → ES UN ERROR. Muévela a `secrets.json`.

---

## ⚠️ 2. NO cambies el modelo de Gemini sin verificar compatibilidad

### El error
Al cambiar el modelo de `gemini-2.5-flash` a `gemini-1.5-flash` (o cualquier otra versión), la app fallaba en tiempo de ejecución porque:
- Diferentes versiones tienen nombres de modelos exactos distintos.
- Algunos modelos están en beta y responden con errores `404 Not Found` si el nombre es incorrecto.
- El cambio causaba crashes o respuestas vacías en el chat de IA y el análisis de tabla.

### La solución correcta
- Siempre usa el modelo que **ya funciona y está probado**: `gemini-2.5-flash`.
- Si necesitas cambiar el modelo, verifica primero en la [documentación oficial de Google AI](https://ai.google.dev/models) que el nombre exacto del modelo existe y está disponible.
- Solo cambia el modelo en `lib/core/gemini_config.dart`, **un solo lugar**:
  ```dart
  const String geminiModel = 'gemini-2.5-flash'; // ← Solo aquí
  ```

---

## ⚠️ 3. NUNCA edites múltiples partes de un archivo simultáneamente sin verificar los paréntesis

### El error
Al refactorizar `posiciones_screen.dart` para agregar efectos hover y micro-animaciones, se dejaron paréntesis y llaves sin cerrar (`)`/`}`) porque se reemplazaron bloques de código de forma parcial. Esto causó:
- **Errores de compilación** (`expected_class_member`, `undefined_method`)
- La función `_buildStandingsRow` fue eliminada pero `_StandingsRow` (que no existía) fue referenciada en su lugar.

### La solución correcta
1. **Después de cada edición**, ejecuta `flutter analyze` antes de continuar:
   ```bash
   flutter analyze
   ```
2. **Cuenta los paréntesis**: cada `(`, `{`, `[` que abres debe tener su correspondiente `)`, `}`, `]`.
3. Si el archivo queda roto, **restáuralo con Git**:
   ```bash
   git checkout lib/features/posiciones/posiciones_screen.dart
   ```
4. **Haz los cambios de forma incremental**: un widget a la vez, no todo el archivo de golpe.

---

## ⚠️ 4. Responsividad desde el inicio, no como parche al final

### El error
Se construyeron widgets con **anchos fijos en píxeles** (ej. `width: 90` para nombres de equipos en `MatchCard`), lo que causaba desbordamientos y colisiones en pantallas pequeñas o al redimensionar la ventana.

También el encabezado de `HomeScreen` colocaba el título y las tarjetas de estadísticas en un `Row` rígido sin considerar pantallas angostas, causando aplastamiento de texto.

### La solución correcta
- **Prefiere `Expanded`, `Flexible` y `double.infinity`** en lugar de anchos fijos cuando el contenido puede variar.
- **Usa `LayoutBuilder`** para detectar el ancho disponible y cambiar el layout:
  ```dart
  LayoutBuilder(builder: (context, constraints) {
    final isNarrow = constraints.maxWidth < 480;
    return isNarrow ? Column(...) : Row(...);
  });
  ```
- Breakpoints recomendados para este proyecto:
  | Tipo       | Ancho mínimo |
  |-----------|-------------|
  | Mobile    | < 480px     |
  | Tablet    | 600px–900px |
  | Desktop   | > 900px     |

---

## ⚠️ 5. No hagas Hot Reload cuando hay errores de compilación activos

### El error
Cuando había errores de sintaxis en el código y se intentaba hacer hot reload (`r`), Flutter intentaba recompilar y el error persiste o se propaga a más widgets, haciendo el diagnóstico más difícil.

### La solución correcta
- Primero **verifica con `flutter analyze`** que no hay errores.
- Si hay errores, **corrígelos todos antes** de hacer reload.
- Usa `R` (hot **restart** en mayúscula) cuando el estado de la app esté corrupto.
- Si el error es grave, simplemente **para la app y reinicia**:
  ```bash
  # Ctrl+C para detener, luego:
  flutter run -d windows --dart-define-from-file=secrets.json
  ```

---

## ✅ 6. Cómo hacer commits seguros

### Verificación antes de cada `git push`

```bash
# 1. Revisa qué archivos van a subir
git status

# 2. Verifica que secrets.json NO aparezca en la lista
# (si aparece, algo está mal con el .gitignore)

# 3. Analiza que no haya errores de compilación
flutter analyze

# 4. Solo entonces, sube
git add .
git commit -m "descripción del cambio"
git push
```

### Archivos que NUNCA deben aparecer en `git status` como "modified":
- `secrets.json` ← contiene API keys
- Cualquier archivo `.env`

---

## ✅ 7. Estructura de comandos para desarrollo diario

```bash
# Iniciar la app en Windows (con claves seguras)
flutter run -d windows --dart-define-from-file=secrets.json

# Verificar errores antes de push
flutter analyze

# Restaurar un archivo arruinado
git checkout lib/ruta/al/archivo.dart

# Ver qué cambió antes de hacer commit
git diff

# Hot reload (dentro de la sesión de flutter run)
r   → Hot Reload (rápido, mantiene estado)
R   → Hot Restart (lento, reinicia el estado)
```

---

## ✅ 8. Resumen rápido de reglas de oro

| # | Regla |
|---|-------|
| 🔴 | **Nunca** escribir API keys directamente en archivos `.dart` |
| 🔴 | **Nunca** hacer push sin verificar que `secrets.json` está ignorado |
| 🔴 | **Nunca** cambiar el modelo de Gemini sin verificar el nombre exacto |
| 🟡 | Ejecutar `flutter analyze` después de cada refactorización grande |
| 🟡 | Usar `git checkout <archivo>` para restaurar en lugar de deshacer manualmente |
| 🟢 | Usar `LayoutBuilder` para responsividad desde el diseño inicial |
| 🟢 | Lanzar siempre con `--dart-define-from-file=secrets.json` |
| 🟢 | Hacer commits pequeños y frecuentes con mensajes descriptivos |

---

*Última actualización: Mayo 2026 — Proyecto GOL 258 · CBTis 258*
