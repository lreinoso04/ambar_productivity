import 'package:flutter/material.dart';

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
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const TareasScreen(),
    );
  }
}

class Tarea {
  String titulo;
  String subtitulo;
  String prioridad;
  bool estaCompletada;
  Tarea(this.titulo, this.subtitulo, this.prioridad, this.estaCompletada);
}

// --- PANTALLA 1: Tareas de Proyecto ---
class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key});
  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  List<Tarea> misTareas = [
    Tarea("Implementar soporte Google Pay", "En curso • Vence mañana", "ALTA", false),
    Tarea("Entrevistas con usuarios", "Completado • Ayer", "MEDIA", true),
    Tarea("Rediseño de flujo de registro", "Por hacer • 24 Marzo", "ALTA", false),
    Tarea("Optimización de base de datos", "Por hacer • 28 Abril", "BAJA", false),
  ];

  @override
  Widget build(BuildContext context) {
    int activas = misTareas.where((t) => !t.estaCompletada).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text("Tareas de Proyecto", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.more_vert, color: Colors.black), onPressed: () {})],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 10),
          _priorityBadge(),
          const SizedBox(height: 8),
          const Text("Tarea III Programación Dispositivos Moviles", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _teamRow(activas),
          const SizedBox(height: 30),
          _listHeader(),
          const SizedBox(height: 10),
          ...misTareas.asMap().entries.map((entry) => _taskItem(entry.value, entry.key)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RevisarNotaScreen())),
        backgroundColor: const Color(0xFF1A73E8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNav(1, context),
    );
  }

  Widget _priorityBadge() {
    return Align(alignment: Alignment.centerLeft, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)), child: const Text("ALTA PRIORIDAD", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold))));
  }

  Widget _teamRow(int activas) {
    return Row(children: [
      CircleAvatar(radius: 12, backgroundColor: Colors.blue.shade100, child: const Text("LR", style: TextStyle(fontSize: 8))),
      const SizedBox(width: 4),
      CircleAvatar(radius: 12, backgroundColor: Colors.green.shade100, child: const Text("JM", style: TextStyle(fontSize: 8))),
      const SizedBox(width: 10),
      Text("$activas tareas activas", style: const TextStyle(color: Colors.grey, fontSize: 13)),
    ]);
  }

  Widget _listHeader() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Lista de Tareas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), TextButton.icon(onPressed: () {}, icon: const Icon(Icons.filter_list, size: 18), label: const Text("Filtrar"))]);
  }

  Widget _taskItem(Tarea tarea, int index) {
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade100)),
      child: ListTile(
        onTap: () => setState(() => tarea.estaCompletada = !tarea.estaCompletada),
        leading: Icon(tarea.estaCompletada ? Icons.check_circle : Icons.radio_button_unchecked, color: tarea.estaCompletada ? Colors.blue : Colors.grey),
        title: Text(tarea.titulo, style: TextStyle(fontWeight: FontWeight.bold, decoration: tarea.estaCompletada ? TextDecoration.lineThrough : null, color: tarea.estaCompletada ? Colors.grey : Colors.black)),
        subtitle: Text(tarea.subtitulo, style: const TextStyle(color: Colors.blue, fontSize: 12)),
        trailing: Text(tarea.prioridad, style: TextStyle(fontSize: 10, color: tarea.prioridad == "ALTA" ? Colors.red : (tarea.prioridad == "MEDIA" ? Colors.orange : Colors.green), fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// --- PANTALLA 2: Revisar y Organizar (CON LÓGICA DE VOZ) ---
class RevisarNotaScreen extends StatefulWidget {
  const RevisarNotaScreen({super.key});
  @override
  State<RevisarNotaScreen> createState() => _RevisarNotaScreenState();
}

class _RevisarNotaScreenState extends State<RevisarNotaScreen> {
  // Estado de la Interfaz
  String proyecto = 'Personal';
  String prioridad = 'Alta';
  List<String> tags = ['#tareas', '#UAPA'];
  bool esTarea = true;

  // Estado del Audio
  bool estaReproduciendo = false;
  double progresoAudio = 0.3;
  String tiempoActual = "1:14";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
        title: const Text("Revisar y Organizar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Listo"))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _reproductorVozInteractivo(), // NUEVO: Con lógica de Play/Pausa
            const SizedBox(height: 20),
            _buildTypeToggle(),
            const SizedBox(height: 30),
            const Text("TRANSCRIPCIÓN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 12),
            _buildTranscriptionBox(),
            const SizedBox(height: 25),
            _buildSelectors(),
            const SizedBox(height: 25),
            const Text("TAGS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const SizedBox(height: 12),
            _buildTagsSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(1, context),
    );
  }

  Widget _reproductorVozInteractivo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Row(children: [
          const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.mic, color: Colors.blue)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Tarea III Programación...", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Grabado hace 2m", style: TextStyle(color: Colors.grey, fontSize: 11)),
          ])),
          // Control de Play/Pausa
          IconButton(
            icon: Icon(estaReproduciendo ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.blue, size: 40),
            onPressed: () => setState(() => estaReproduciendo = !estaReproduciendo),
          ),
        ]),
        Slider(
          value: progresoAudio, 
          activeColor: Colors.blue,
          onChanged: (v) => setState(() => progresoAudio = v),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tiempoActual, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const Text("4:12", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildTypeToggle() {
    return Row(children: [
      _toggleBtn(Icons.check_circle_outline, "Convertir en Tarea", esTarea, () => setState(() => esTarea = true)),
      const SizedBox(width: 12),
      _toggleBtn(Icons.description_outlined, "Guardar como Nota", !esTarea, () => setState(() => esTarea = false)),
    ]);
  }

  Widget _toggleBtn(IconData icon, String label, bool active, VoidCallback tap) {
    return Expanded(child: GestureDetector(onTap: tap, child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: active ? Colors.grey.shade300 : Colors.transparent), boxShadow: active ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : []), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: active ? Colors.black : Colors.grey), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: active ? Colors.black : Colors.grey))]))));
  }

  Widget _buildTranscriptionBox() {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(16)), child: const Text("Vamos a proceder con el diseño de Ambar, una aplicación de gestión de tareas y notas de voz...", style: TextStyle(height: 1.5, fontSize: 13, color: Colors.black87)));
  }

  Widget _buildSelectors() {
    return Row(children: [
      Expanded(child: _customDropdown("PROYECTO", proyecto, ['Personal', 'UAPA', 'Trabajo'], (v) => setState(() => proyecto = v!))),
      const SizedBox(width: 16),
      Expanded(child: _customDropdown("PRIORIDAD", prioridad, ['Alta', 'Media', 'Baja'], (v) => setState(() => prioridad = v!), warn: true)),
    ]);
  }

  Widget _customDropdown(String label, String val, List<String> opts, Function(String?) change, {bool warn = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: val, isExpanded: true, icon: Icon(warn ? Icons.priority_high : Icons.keyboard_arrow_down, size: 18),
            items: opts.map((String o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: change,
          ),
        ),
      ),
    ]);
  }

  Widget _buildTagsSection() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF1F4F9), borderRadius: BorderRadius.circular(16)),
      child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        ...tags.map((tag) => _tagWidget(tag)),
        GestureDetector(onTap: () => setState(() => tags.add("#nuevo")), child: const CircleAvatar(radius: 14, backgroundColor: Colors.white, child: Icon(Icons.add, size: 16, color: Colors.grey))),
      ]),
    );
  }

  Widget _tagWidget(String text) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(text, style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(width: 4), GestureDetector(onTap: () => setState(() => tags.remove(text)), child: const Icon(Icons.close, size: 14, color: Colors.blue))]));
  }
}

Widget _buildBottomNav(int index, BuildContext context) {
  return BottomNavigationBar(
    currentIndex: index, type: BottomNavigationBarType.fixed,
    selectedItemColor: Colors.blue, unselectedItemColor: Colors.blueGrey,
    selectedFontSize: 10, unselectedFontSize: 10,
    onTap: (i) { if (i == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TareasScreen())); },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.mic_none), label: "Capturar"),
      BottomNavigationBarItem(icon: Icon(Icons.task_outlined), label: "Revisar Tareas"),
      BottomNavigationBarItem(icon: Icon(Icons.folder_open), label: "Proyectos"),
      BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "Ajustes"),
    ],
  );
}