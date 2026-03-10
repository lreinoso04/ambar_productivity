import 'package:flutter/material.dart';

void main() {
  runApp(const AmbarApp());
}

class AmbarApp extends StatelessWidget {
  const AmbarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ambar Productivity',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
      ),
      home: const TareasScreen(),
    );
  }
}

class TareasScreen extends StatelessWidget {
  const TareasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.arrow_back, color: Colors.black),
        title: const Text("Tareas de Proyecto", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: Colors.black))
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ALTA PRIORIDAD", 
                style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              const Text("Tarea III Programación Disp. Moviles", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text("Lista de Tareas", 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              // Aquí llamamos a las tarjetas
              taskItem("Implementar soporte Google Pay", "En curso", "ALTA", Colors.red, true),
              taskItem("Entrevistas con usuarios", "Completado", "MEDIA", Colors.orange, false),
              taskItem("Rediseño de flujo de registro", "Por hacer", "ALTA", Colors.red, true),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A73E8),
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // AQUÍ ESTÁ EL CAMBIO: Usamos BorderSide en lugar de BorderStroke
  Widget taskItem(String titulo, String estado, String prioridad, Color colorPrioridad, bool isPending) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200, width: 1), // Corregido aquí
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isPending ? Icons.circle_outlined : Icons.check_circle,
              color: isPending ? Colors.grey : const Color(0xFF1A73E8),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(estado, style: const TextStyle(color: Color(0xFF1A73E8), fontSize: 12)),
                ],
              ),
            ),
            Text(prioridad, style: TextStyle(color: colorPrioridad, fontWeight: FontWeight.bold, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}