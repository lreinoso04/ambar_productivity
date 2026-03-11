import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

void main() => runApp(const AmbarApp());

class AmbarApp extends StatelessWidget {
  const AmbarApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1A73E8),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        cardTheme: const CardThemeData(elevation: 0, color: Colors.white),
      ),
      home: const MainNavigation(),
    );
  }
}

// ─────────────────────────────────────────
// NAVEGACIÓN PRINCIPAL
// ─────────────────────────────────────────
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int index = 0;
  String transcripcionGuardada = "";

  void changePage(int i) => setState(() => index = i);

  void guardarTranscripcion(String texto) {
    setState(() {
      transcripcionGuardada = texto;
      index = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> mainPages = [
      CapturarView(onSaved: guardarTranscripcion),
      RevisarOrganizarView(transcripcion: transcripcionGuardada),
      const TareasProyectoView(),
      const PerfilView(),
    ];
    return Scaffold(
      body: mainPages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1A73E8),
        unselectedItemColor: Colors.grey,
        onTap: changePage,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: "Capturar"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Revisar"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Tareas"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 1. CAPTURA CON STT ROBUSTO
// ─────────────────────────────────────────
class CapturarView extends StatefulWidget {
  final Function(String) onSaved;
  const CapturarView({super.key, required this.onSaved});
  @override
  State<CapturarView> createState() => _CapturarViewState();
}

class _CapturarViewState extends State<CapturarView> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isInitializing = true;
  bool isRecording = false;
  int sec = 0;
  Timer? timer;
  String _transcripcionActual = "";
  double _confianza = 0.0;
  String _localeId = "";

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  // ── FIX: todos los setState tienen guard "if (!mounted) return" ──────────
  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _initSpeech() async {
    _safeSetState(() => _isInitializing = true);

    try {
      _speechAvailable = await _speech.initialize(
        onError: (error) {
          _safeSetState(() {
            isRecording = false;
          });
          if (isRecording && error.permanent == false) {
            Future.delayed(
                const Duration(milliseconds: 500), _restartListening);
          }
        },
        onStatus: (status) {
          if ((status == "done" || status == "notListening") && isRecording) {
            Future.delayed(
                const Duration(milliseconds: 300), _restartListening);
          }
        },
        debugLogging: false,
      );

      if (_speechAvailable && mounted) {
        final locales = await _speech.locales();
        final esLocales = locales
            .where((l) => l.localeId.toLowerCase().startsWith("es"))
            .toList();

        if (esLocales.isNotEmpty) {
          final esEs = esLocales.firstWhere(
            (l) =>
                l.localeId == "es_ES" ||
                l.localeId == "es-ES" ||
                l.localeId == "es",
            orElse: () => esLocales.first,
          );
          _localeId = esEs.localeId;
        } else if (locales.isNotEmpty) {
          _localeId =
              // ✅ CORRECCIÓN:
_localeId = locales.first.localeId;
        }
      }
    } catch (_) {
      _speechAvailable = false;
    }

    _safeSetState(() => _isInitializing = false);
  }

  Future<void> _restartListening() async {
    if (!mounted || !isRecording || !_speechAvailable) return;
    if (_speech.isListening) return;
    await _speech.listen(
      onResult: _onSpeechResult,
      localeId: _localeId.isNotEmpty ? _localeId : null,
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    // FIX: guard mounted antes de setState
    if (!mounted) return;
    setState(() {
      _transcripcionActual = result.recognizedWords;
      if (result.confidence > 0) _confianza = result.confidence;
    });
  }

  Future<void> toggleRecording() async {
    if (_isInitializing) return;

    if (!_speechAvailable) {
      _showErrorDialog(
        "Servicio de voz no disponible",
        "Asegúrate de:\n\n"
            "1. Tener Google App instalada\n"
            "2. Haber otorgado permisos de micrófono\n"
            "3. Tener conexión a internet\n\n"
            "En emuladores: activa el micrófono en la configuración del AVD.",
      );
      return;
    }

    if (!isRecording) {
      // ── INICIAR ──
      _safeSetState(() {
        isRecording = true;
        sec = 0;
        _transcripcionActual = "";
        _confianza = 0.0;
      });

      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        // FIX: cancelar timer si el widget ya no está montado
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => sec++);
      });

      await _speech.listen(
        onResult: _onSpeechResult,
        localeId: _localeId.isNotEmpty ? _localeId : null,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        ),
      );
    } else {
      // ── DETENER ──
      await _speech.stop();
      timer?.cancel();
      _safeSetState(() => isRecording = false);
      if (mounted) _showSaveDialog();
    }
  }

  void _showErrorDialog(String titulo, String mensaje) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 26),
          const SizedBox(width: 8),
          Flexible(
            child: Text(titulo,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ]),
        content: Text(mensaje,
            style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _initSpeech();
              },
              child: const Text("Reintentar")),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar")),
        ],
      ),
    );
  }

  void _showSaveDialog() {
    if (!mounted) return;
    final textoFinal = _transcripcionActual.trim().isEmpty
        ? "Sin transcripción detectada."
        : _transcripcionActual.trim();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Guardar grabación?",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Transcripción capturada:",
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              textoFinal,
              style: const TextStyle(fontSize: 14, height: 1.5),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_confianza > 0) ...[
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 4),
              Text(
                "Precisión: ${(_confianza * 100).toStringAsFixed(0)}%",
                style:
                    const TextStyle(fontSize: 12, color: Colors.green),
              ),
            ]),
          ],
        ]),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _safeSetState(() => _transcripcionActual = "");
              },
              child: const Text("Descartar")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onSaved(textoFinal);
            },
            child: const Text("Guardar y Revisar"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // FIX: cancelar todo limpiamente antes de destruir el widget
    timer?.cancel();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String time =
        "${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: const Color(0xFF1A73E8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 36),
            Text(
              _isInitializing
                  ? "Iniciando micrófono..."
                  : (isRecording ? "Grabando nota AI" : "Listo para grabar"),
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 1.2),
            ),
            if (_localeId.isNotEmpty && !_isInitializing)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "🎙 Idioma: $_localeId",
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              time,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4),
            ),
            const SizedBox(height: 24),

            // ── Caja transcripción tiempo real ──
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: _isInitializing
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                                color: Colors.white54),
                            SizedBox(height: 16),
                            Text("Verificando micrófono...",
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14)),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        reverse: true,
                        child: _transcripcionActual.isEmpty
                            ? Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 40),
                                  Icon(
                                    isRecording
                                        ? Icons.graphic_eq
                                        : Icons.mic_none,
                                    color: Colors.white54,
                                    size: 52,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    isRecording
                                        ? "Escuchando...\nhabla claramente"
                                        : (_speechAvailable
                                            ? "La transcripción\naparecerá aquí"
                                            : "⚠ Servicio de voz\nno disponible"),
                                    style: TextStyle(
                                        color: _speechAvailable
                                            ? Colors.white54
                                            : Colors.orangeAccent,
                                        fontSize: 15),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : Text(
                                _transcripcionActual,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  height: 1.7,
                                ),
                              ),
                      ),
              ),
            ),

            const SizedBox(height: 36),

            // ── Botón micrófono ──
            GestureDetector(
              onTap: _isInitializing ? null : toggleRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(isRecording ? 20 : 26),
                decoration: BoxDecoration(
                  color: _isInitializing
                      ? Colors.white38
                      : (isRecording
                          ? Colors.red.shade400
                          : Colors.white),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      spreadRadius: isRecording ? 6 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  _isInitializing
                      ? Icons.hourglass_top
                      : (isRecording ? Icons.stop_rounded : Icons.mic),
                  color: isRecording ? Colors.white : Colors.blue,
                  size: isRecording ? 50 : 45,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _isInitializing
                  ? "Espera un momento..."
                  : (isRecording
                      ? "Toca para finalizar"
                      : "Toca para iniciar"),
              style: const TextStyle(
                  color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 36),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 2. REVISAR Y ORGANIZAR
// ─────────────────────────────────────────
class RevisarOrganizarView extends StatefulWidget {
  final String transcripcion;
  const RevisarOrganizarView({super.key, this.transcripcion = ""});
  @override
  State<RevisarOrganizarView> createState() => _RevisarOrganizarViewState();
}

class _RevisarOrganizarViewState extends State<RevisarOrganizarView> {
  final FlutterTts _tts = FlutterTts();
  bool _ttsPlaying = false;
  bool _ttsPaused = false;
  double audioPos = 0.0;
  Timer? audioTimer;
  int currentMillis = 0;
  final int totalMillis = 252000;
  final List<String> tagsList = ["#tareas", "#UAPA"];

  String get _textoTranscripcion =>
      widget.transcripcion.isNotEmpty
          ? widget.transcripcion
          : "Vamos a proceder con el diseño de Ambar, una aplicación de gestión "
              "de tareas y notas de voz. El objetivo es implementar una interfaz "
              "intuitiva que permita a los usuarios capturar ideas rápidamente.";

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("es-ES");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (!mounted) return; // FIX
      setState(() {
        _ttsPlaying = false;
        _ttsPaused = false;
        audioPos = 0.0;
        currentMillis = 0;
        audioTimer?.cancel();
      });
    });
  }

  Future<void> _toggleTts() async {
    if (_ttsPlaying) {
      await _tts.pause();
      audioTimer?.cancel();
      if (!mounted) return; // FIX
      setState(() { _ttsPlaying = false; _ttsPaused = true; });
    } else if (_ttsPaused) {
      await _tts.speak(_textoTranscripcion);
      _startBarTimer();
      if (!mounted) return; // FIX
      setState(() { _ttsPlaying = true; _ttsPaused = false; });
    } else {
      audioPos = 0.0;
      currentMillis = 0;
      await _tts.speak(_textoTranscripcion);
      _startBarTimer();
      if (!mounted) return; // FIX
      setState(() { _ttsPlaying = true; _ttsPaused = false; });
    }
  }

  void _startBarTimer() {
    audioTimer?.cancel();
    audioTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (!mounted) { t.cancel(); return; } // FIX
      setState(() {
        currentMillis += 200;
        audioPos = currentMillis / totalMillis;
        if (audioPos >= 1.0) { audioPos = 1.0; t.cancel(); }
      });
    });
  }

  String formatTime(int millis) {
    int s = (millis ~/ 1000) % 60;
    int m = (millis ~/ 1000) ~/ 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _tts.stop();
    audioTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.close),
        title: const Text("Revisar y Organizar",
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
              onPressed: () {},
              child: const Text("Listo", style: TextStyle(fontSize: 16)))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tarjeta de audio ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10)],
              ),
              child: Column(children: [
                Row(children: [
                  const CircleAvatar(
                      backgroundColor: Color(0xFFF1F4F9),
                      child: Icon(Icons.mic, color: Colors.blue)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Tarea III Programación...",
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                          Text("Grabado hoy • 04:12",
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        ]),
                  ),
                  CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: IconButton(
                          icon: Icon(
                              _ttsPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white),
                          onPressed: _toggleTts)),
                ]),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12),
                  ),
                  child: Slider(
                    value: audioPos.clamp(0.0, 1.0),
                    onChanged: (v) => setState(() {
                      audioPos = v;
                      currentMillis = (v * totalMillis).toInt();
                    }),
                    activeColor: Colors.blue,
                    inactiveColor: const Color(0xFFE1E8F5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatTime(currentMillis),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        Text(formatTime(totalMillis),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ]),
                ),
              ]),
            ),

            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _actionBtn(Icons.check_circle_outline, "Convertir en Tarea")),
              const SizedBox(width: 10),
              Expanded(child: _actionBtn(Icons.description_outlined, "Guardar como Nota")),
            ]),
            const SizedBox(height: 25),

            // ── TRANSCRIPCIÓN ──
            Row(children: [
              const Text("TRANSCRIPCIÓN",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const Spacer(),
              GestureDetector(
                onTap: _toggleTts,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _ttsPlaying
                        ? Colors.orange.withValues(alpha: 0.12)
                        : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      _ttsPlaying
                          ? Icons.pause_circle_filled
                          : Icons.volume_up_rounded,
                      size: 16,
                      color: _ttsPlaying ? Colors.orange : Colors.blue,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _ttsPlaying
                          ? "Pausar"
                          : (_ttsPaused ? "Reanudar" : "Escuchar"),
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              _ttsPlaying ? Colors.orange : Colors.blue,
                          fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                    color: _ttsPlaying
                        ? Colors.blue.withValues(alpha: 0.5)
                        : const Color(0xFFE1E8F5)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _textoTranscripcion,
                      style: const TextStyle(
                          color: Colors.black87,
                          height: 1.6,
                          fontSize: 14),
                    ),
                    if (_ttsPlaying) ...[
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.graphic_eq,
                            color: Colors.blue, size: 18),
                        const SizedBox(width: 6),
                        Text("Leyendo en voz alta...",
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue
                                    .withValues(alpha: 0.8),
                                fontStyle: FontStyle.italic)),
                      ]),
                    ],
                  ]),
            ),

            const SizedBox(height: 25),
            Row(children: [
              Expanded(child: _buildDrop("PROYECTO", "Personal",
                  ["Personal", "Estudios", "Trabajo"])),
              const SizedBox(width: 15),
              Expanded(child: _buildDrop(
                  "PRIORIDAD", "Alta", ["Alta", "Media", "Baja"])),
            ]),
            const SizedBox(height: 25),
            const Text("TAGS",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, children: [
              ...tagsList.map((t) => Chip(
                    label: Text(t,
                        style: const TextStyle(
                            color: Colors.blue, fontSize: 12)),
                    backgroundColor:
                        Colors.blue.withValues(alpha: 0.1),
                    side: BorderSide.none,
                  )),
              IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: Colors.blue),
                  onPressed: () =>
                      setState(() => tagsList.add("#nuevo"))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDrop(String label, String val, List<String> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: val,
        items: items
            .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e,
                    style: const TextStyle(fontSize: 14))))
            .toList(),
        onChanged: (v) {},
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF1F4F9),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    ]);
  }

  Widget _actionBtn(IconData i, String l) => OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(i, size: 18),
      label: Text(l, style: const TextStyle(fontSize: 11)));
}

// ─────────────────────────────────────────
// 3. TAREAS
// ─────────────────────────────────────────
class TareasProyectoView extends StatefulWidget {
  const TareasProyectoView({super.key});
  @override
  State<TareasProyectoView> createState() => _TareasProyectoViewState();
}

class _TareasProyectoViewState extends State<TareasProyectoView> {
  final List<Map<String, dynamic>> tasksList = [
    {"t": "Implementar soporte Google Pay","s": "En curso • Vence mañana","p": "ALTA","d": false},
    {"t": "Entrevistas con usuarios","s": "Completado • Ayer","p": "MEDIA","d": true},
    {"t": "Rediseño de flujo de registro","s": "Por hacer • 24 Marzo","p": "ALTA","d": false},
  ];

  void addNewTask() => setState(() => tasksList.add(
      {"t": "Nueva tarea agregada", "s": "Pendiente • Hoy", "p": "BAJA", "d": false}));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tareas de Proyecto",
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: const [Icon(Icons.more_vert), SizedBox(width: 15)],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: addNewTask,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add, color: Colors.white)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _priorityBadge("ALTA PRIORIDAD"),
          const SizedBox(height: 8),
          const Text("Tarea III Programación Dispositivos Moviles",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 15),
          Row(children: [
            _avatar("LR", Colors.blue),
            Transform.translate(
                offset: const Offset(-8, 0),
                child: _avatar("JM", Colors.orange)),
            Transform.translate(
                offset: const Offset(-16, 0),
                child: _conteoAvatar("+2")),
            const SizedBox(width: 10),
            Text("${tasksList.length + 9} tareas activas",
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13)),
          ]),
          const SizedBox(height: 30),
          Row(children: [
            const Text("Lista de Tareas",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            const Spacer(),
            const Icon(Icons.filter_list,
                size: 16, color: Colors.blue),
            const Text(" Filtrar",
                style: TextStyle(color: Colors.blue)),
          ]),
          const SizedBox(height: 15),
          ...tasksList.map((task) => _buildTaskItem(task)),
        ],
      ),
    );
  }

  Widget _priorityBadge(String t) => UnconstrainedBox(
        alignment: Alignment.centerLeft,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(15)),
          child: Text(t,
              style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 9)),
        ),
      );

  Widget _avatar(String i, Color c) => CircleAvatar(
      radius: 14,
      backgroundColor: c.withValues(alpha: 0.2),
      child: Text(i,
          style: TextStyle(
              fontSize: 10, color: c, fontWeight: FontWeight.bold)));

  Widget _conteoAvatar(String t) => CircleAvatar(
      radius: 14,
      backgroundColor: const Color(0xFFF1F4F9),
      child: Text(t,
          style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6C7B90),
              fontWeight: FontWeight.bold)));

  Widget _buildTaskItem(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE1E8F5))),
      child: Row(children: [
        GestureDetector(
            onTap: () => setState(() => task['d'] = !task['d']),
            child: Icon(
                task['d']
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: Colors.blue,
                size: 28)),
        const SizedBox(width: 15),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Text(task['t'],
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: task['d'] ? Colors.grey : Colors.black87,
                  decoration: task['d']
                      ? TextDecoration.lineThrough
                      : null)),
          Text(task['s'],
              style: TextStyle(
                  color: task['d'] ? Colors.green : Colors.blue,
                  fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: task['p'] == "ALTA"
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(4)),
          child: Text(task['p'],
              style: TextStyle(
                  color: task['p'] == "ALTA"
                      ? Colors.red
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 9)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// 4. PERFIL
// ─────────────────────────────────────────
class PerfilView extends StatelessWidget {
  const PerfilView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        title: const Text("Perfil",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.settings_outlined,
                  color: Colors.black87),
              onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(children: [
                Stack(children: [
                  Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.orange, width: 3)),
                    child: const CircleAvatar(
                      radius: 52,
                      backgroundImage:
                          AssetImage('assets/foto_luis.jpg'),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                          color: Color(0xFF1A73E8),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.edit,
                          color: Colors.white, size: 13),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                const Text("Luis Reinoso",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                const Text("Producto Owner",
                    style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A73E8),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                const Text("100070497@p.uapa.edu.do",
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey)),
              ]),
            ),
            const SizedBox(height: 32),
            const Text("CONFIGURACIÓN",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _menuItem(Icons.person_outline, Colors.blue, "Cuenta"),
            _menuItem(Icons.notifications_outlined, Colors.orange,
                "Notificaciones"),
            _menuItem(
                Icons.shield_outlined, Colors.indigo, "Seguridad"),
            _menuItem(Icons.help_outline, Colors.teal,
                "Ayuda y Soporte"),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, Color color, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE1E8F5))),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 15)),
        trailing: const Icon(Icons.chevron_right,
            color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}