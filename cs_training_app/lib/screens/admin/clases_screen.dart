import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/entrenamiento.dart';
import '../../routes/routes.dart';
import '../../services/entrenamiento_service.dart';
import 'crear_clases_screen.dart';

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
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.black),  // Icono de la casa en negro
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.adminHome);
          },
        ),
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón de eliminar
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirmar eliminación'),
                          content: const Text(
                              '¿Estás seguro de que deseas eliminar este entrenamiento?'),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await entrenamientoService
                              .deleteTraining(entrenamiento.id ?? 0);
                          _cargarEntrenamientos();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                Text('Entrenamiento eliminado')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                                content:
                                Text('Error al eliminar: $e')),
                          );
                        }
                      }
                    },
                  ),
                  // Botón de editar
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CrearClaseScreen(
                            entrenamiento: entrenamiento,
                          ),
                        ),
                      ).then((_) {
                        _cargarEntrenamientos(); // Recargar entrenamientos
                      });
                    },
                  ),
                ],
              ),
              onTap: () {
                // Si quieres que también al tapear el ListTile pase algo más
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
