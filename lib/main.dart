import 'package:flutter/material.dart';
import 'dart:async';

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

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int index = 0;
  void changePage(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    final List<Widget> mainPages = [
      CapturarView(onSaved: () => changePage(1)),
      const RevisarOrganizarView(),
      const TareasProyectoView(),
      const PerfilView(), // ← NUEVO
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

// --- 1. CAPTURA ---
class CapturarView extends StatefulWidget {
  final VoidCallback onSaved;
  const CapturarView({super.key, required this.onSaved});
  @override
  State<CapturarView> createState() => _CapturarViewState();
}

class _CapturarViewState extends State<CapturarView> {
  int sec = 0;
  Timer? timer;
  bool isRecording = false;

  void toggleRecording() {
    if (!isRecording) {
      setState(() {
        isRecording = true;
        sec = 0;
        timer = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => sec++));
      });
    } else {
      timer?.cancel();
      showSaveDialog();
    }
  }

  void showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Guardar grabación?"),
        content: const Text("¿Deseas guardar este audio para revisarlo y organizarlo ahora?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Descartar")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isRecording = false);
              widget.onSaved();
            },
            child: const Text("Guardar y Revisar"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    String time = "${(sec ~/ 60).toString().padLeft(2, '0')}:${(sec % 60).toString().padLeft(2, '0')}";
    return Scaffold(
      backgroundColor: const Color(0xFF1A73E8),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(isRecording ? "Escuchando..." : "Listo para grabar", style: const TextStyle(color: Colors.white70, fontSize: 18)),
        const SizedBox(height: 20),
        Text(time, style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold)),
        const SizedBox(height: 60),
        GestureDetector(
          onTap: toggleRecording,
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(isRecording ? Icons.stop : Icons.mic, color: Colors.blue, size: 45),
          ),
        ),
        const SizedBox(height: 20),
        Text(isRecording ? "Toca para finalizar" : "Toca para iniciar", style: const TextStyle(color: Colors.white60)),
      ])),
    );
  }
}

// --- 2. REVISAR Y ORGANIZAR ---
class RevisarOrganizarView extends StatefulWidget {
  const RevisarOrganizarView({super.key});
  @override
  State<RevisarOrganizarView> createState() => _RevisarOrganizarViewState();
}

class _RevisarOrganizarViewState extends State<RevisarOrganizarView> {
  double audioPos = 0.0;
  bool isPlaying = false;
  Timer? audioTimer;
  int currentMillis = 0;
  final int totalMillis = 252000;
  final List<String> tagsList = ["#tareas", "#UAPA"];

  void togglePlay() {
    setState(() {
      isPlaying = !isPlaying;
      if (isPlaying) {
        audioTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
          setState(() {
            currentMillis += 500;
            audioPos = currentMillis / totalMillis;
            if (audioPos >= 1.0) { audioPos = 1.0; isPlaying = false; audioTimer?.cancel(); }
          });
        });
      } else { audioTimer?.cancel(); }
    });
  }

  String formatTime(int millis) {
    int seconds = (millis ~/ 1000) % 60;
    int minutes = (millis ~/ 1000) ~/ 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() { audioTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.close),
        title: const Text("Revisar y Organizar", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [TextButton(onPressed: () {}, child: const Text("Listo", style: TextStyle(fontSize: 16)))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          buildAudioCard(),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: actionBtn(Icons.check_circle_outline, "Convertir en Tarea")),
            const SizedBox(width: 10),
            Expanded(child: actionBtn(Icons.description_outlined, "Guardar como Nota")),
          ]),
          const SizedBox(height: 25),
          const Text("TRANSCRIPCIÓN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE1E8F5))),
            child: const Text(
              "Vamos a proceder con el diseño de Ambar, una aplicación de gestión de tareas y notas de voz. "
              "El objetivo es implementar una interfaz intuitiva que permita a los usuarios capturar ideas rápidamente.",
              style: TextStyle(color: Colors.black87, height: 1.5),
            ),
          ),
          const SizedBox(height: 25),
          Row(children: [
            Expanded(child: buildDrop("PROYECTO", "Personal", ["Personal", "Estudios", "Trabajo"])),
            const SizedBox(width: 15),
            Expanded(child: buildDrop("PRIORIDAD", "Alta", ["Alta", "Media", "Baja"])),
          ]),
          const SizedBox(height: 25),
          const Text("TAGS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            ...tagsList.map((t) => Chip(
              label: Text(t, style: const TextStyle(color: Colors.blue, fontSize: 12)),
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              side: BorderSide.none,
            )),
            IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.blue), onPressed: () => setState(() => tagsList.add("#nuevo"))),
          ]),
        ]),
      ),
    );
  }

  Widget buildAudioCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(children: [
        Row(children: [
          const CircleAvatar(backgroundColor: Color(0xFFF1F4F9), child: Icon(Icons.mic, color: Colors.blue)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Tarea III Programación...", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Grabado hoy • 04:12", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
          CircleAvatar(backgroundColor: Colors.blue, child: IconButton(icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white), onPressed: togglePlay)),
        ]),
        Slider(value: audioPos > 1.0 ? 1.0 : audioPos, onChanged: (v) => setState(() { audioPos = v; currentMillis = (v * totalMillis).toInt(); }), activeColor: Colors.blue),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(formatTime(currentMillis), style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(formatTime(totalMillis), style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ]),
    );
  }

  Widget buildDrop(String label, String val, List<String> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: val,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: (v) {},
        decoration: InputDecoration(
          filled: true, fillColor: const Color(0xFFF1F4F9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    ]);
  }

  Widget actionBtn(IconData i, String l) => OutlinedButton.icon(onPressed: () {}, icon: Icon(i, size: 18), label: Text(l, style: const TextStyle(fontSize: 11)));
}

// --- 3. TAREAS ---
class TareasProyectoView extends StatefulWidget {
  const TareasProyectoView({super.key});
  @override
  State<TareasProyectoView> createState() => _TareasProyectoViewState();
}

class _TareasProyectoViewState extends State<TareasProyectoView> {
  final List<Map<String, dynamic>> tasksList = [
    {"t": "Implementar soporte Google Pay", "s": "En curso • Vence mañana", "p": "ALTA", "d": false},
    {"t": "Entrevistas con usuarios", "s": "Completado • Ayer", "p": "MEDIA", "d": true},
    {"t": "Rediseño de flujo de registro", "s": "Por hacer • 24 Marzo", "p": "ALTA", "d": false},
  ];

  void addNewTask() {
    setState(() => tasksList.add({"t": "Nueva tarea agregada", "s": "Pendiente • Hoy", "p": "BAJA", "d": false}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tareas de Proyecto", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: const [Icon(Icons.more_vert), SizedBox(width: 15)],
      ),
      floatingActionButton: FloatingActionButton(onPressed: addNewTask, backgroundColor: Colors.blue, child: const Icon(Icons.add, color: Colors.white)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          priorityBadge("ALTA PRIORIDAD"),
          const SizedBox(height: 8),
          const Text("Tarea III Programación Dispositivos Moviles", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 15),
          Row(children: [
            avatar("LR", Colors.blue),
            Transform.translate(offset: const Offset(-8, 0), child: avatar("JM", Colors.orange)),
            Transform.translate(offset: const Offset(-16, 0), child: conteoAvatar("+2")),
            const SizedBox(width: 10),
            Text("${tasksList.length + 9} tareas activas", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
          const SizedBox(height: 30),
          Row(children: [
            const Text("Lista de Tareas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Spacer(),
            const Icon(Icons.filter_list, size: 16, color: Colors.blue),
            const Text(" Filtrar", style: TextStyle(color: Colors.blue)),
          ]),
          const SizedBox(height: 15),
          ...tasksList.map((task) => buildTaskItem(task)),
        ],
      ),
    );
  }

  Widget priorityBadge(String t) => UnconstrainedBox(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(15)),
      child: Text(t, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 9)),
    ),
  );

  Widget avatar(String i, Color c) => CircleAvatar(radius: 14, backgroundColor: c.withValues(alpha: 0.2), child: Text(i, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.bold)));
  Widget conteoAvatar(String t) => CircleAvatar(radius: 14, backgroundColor: const Color(0xFFF1F4F9), child: Text(t, style: const TextStyle(fontSize: 10, color: Color(0xFF6C7B90), fontWeight: FontWeight.bold)));

  Widget buildTaskItem(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE1E8F5))),
      child: Row(children: [
        GestureDetector(onTap: () => setState(() => task['d'] = !task['d']), child: Icon(task['d'] ? Icons.check_circle : Icons.radio_button_unchecked, color: Colors.blue, size: 28)),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(task['t'], style: TextStyle(fontWeight: FontWeight.bold, color: task['d'] ? Colors.grey : Colors.black87, decoration: task['d'] ? TextDecoration.lineThrough : null)),
          Text(task['s'], style: TextStyle(color: task['d'] ? Colors.green : Colors.blue, fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: task['p'] == "ALTA" ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(4)),
          child: Text(task['p'], style: TextStyle(color: task['p'] == "ALTA" ? Colors.red : Colors.orange, fontWeight: FontWeight.bold, fontSize: 9)),
        ),
      ]),
    );
  }
}

// --- 4. PERFIL ← NUEVO ---
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
        title: const Text("Perfil", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.black87), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Foto + Nombre ---
            Center(
              child: Column(children: [
                Stack(children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange, width: 3),
                    ),
                    child: const CircleAvatar(
                      radius: 52,
                      backgroundImage: AssetImage('assets/foto_luis.jpg'), // ← tu foto
                    ),
                  ),
                  Positioned(
                    bottom: 2, right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: Color(0xFF1A73E8), shape: BoxShape.circle),
                      child: const Icon(Icons.edit, color: Colors.white, size: 13),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                const Text("Luis Reinoso", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 4),
                const Text("Producto Owner", style: TextStyle(fontSize: 14, color: Color(0xFF1A73E8), fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                const Text("100070497@p.uapa.edu.do", style: TextStyle(fontSize: 13, color: Colors.grey)),
              ]),
            ),
            const SizedBox(height: 32),

            // --- Configuración ---
            const Text("CONFIGURACIÓN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _menuItem(Icons.person_outline, Colors.blue, "Cuenta"),
            _menuItem(Icons.notifications_outlined, Colors.orange, "Notificaciones"),
            _menuItem(Icons.shield_outlined, Colors.indigo, "Seguridad"),
            _menuItem(Icons.help_outline, Colors.teal, "Ayuda y Soporte"),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, Color color, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE1E8F5))),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}