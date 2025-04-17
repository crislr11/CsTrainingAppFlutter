import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/entrenamiento.dart';
import '../../routes/routes.dart';
import '../../services/entrenamiento_service.dart';

class ClasesScreen extends StatefulWidget {
  const ClasesScreen({super.key});

  @override
  State<ClasesScreen> createState() => _ClasesScreenState();
}

class _ClasesScreenState extends State<ClasesScreen> {
  bool isLoading = true;
  List<Entrenamiento> entrenamientos = [];
  final EntrenamientoService entrenamientoService = EntrenamientoService();

  @override
  void initState() {
    super.initState();
    _cargarEntrenamientos();
  }

  Future<void> _cargarEntrenamientos() async {
    try {
      final resultado = await entrenamientoService.getAllTrainings();
      setState(() {
        entrenamientos = resultado;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los entrenamientos: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Entrenamientos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFC107),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : entrenamientos.isEmpty
          ? const Center(child: Text('No hay entrenamientos disponibles'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: entrenamientos.length,
        itemBuilder: (context, index) {
          final entrenamiento = entrenamientos[index];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(
                entrenamiento.oposicion,
                style: GoogleFonts.rubik(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Fecha: ${entrenamiento.fecha}\nLugar: ${entrenamiento.lugar}',
                style: GoogleFonts.poppins(),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded),
              onTap: () {
                // Aquí podrías mostrar detalles o editar el entrenamiento
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.crearClase);
          _cargarEntrenamientos(); // Recarga los entrenamientos al volver
        },
      ),
    );
  }
}
