import 'package:flutter/material.dart';
import 'package:cs_training_app/models/entrenamiento.dart';
import 'package:cs_training_app/services/entrenamiento_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes/routes.dart';

class ProfesorHomeScreen extends StatefulWidget {
  const ProfesorHomeScreen({super.key});

  @override
  State<ProfesorHomeScreen> createState() => _ProfesorHomeScreenState();
}

class _ProfesorHomeScreenState extends State<ProfesorHomeScreen> {
  late Future<List<Entrenamiento>> _futureEntrenamientos;
  final EntrenamientoService _entrenamientoService = EntrenamientoService();

  @override
  void initState() {
    super.initState();
    _cargarEntrenamientos();
  }

  void _cargarEntrenamientos() async {
    final prefs = await SharedPreferences.getInstance();
    final profesorId = prefs.getInt('userId');

    if (profesorId == null) {
      setState(() {
        _futureEntrenamientos = Future.error(
          'No se encontró el ID del profesor en SharedPreferences',
        );
      });
      return;
    }

    setState(() {
      _futureEntrenamientos = _entrenamientoService.getFutureTrainingsByProfessor(profesorId);
    });
  }

  // Método para cerrar sesión y regresar al login
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId'); // Eliminar el ID del usuario (sesión)
    Navigator.pushReplacementNamed(context, AppRoutes.login); // Redirigir al login
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Entrenamientos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEntrenamientos,
          ),
          IconButton(
            icon: const Icon(Icons.logout), // Icono de cerrar sesión
            onPressed: _logout, // Llamar al método _logout
          ),
        ],
      ),
      body: FutureBuilder<List<Entrenamiento>>(
        future: _futureEntrenamientos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains('NO_ENTRENAMIENTOS')) {
              return const Center(
                child: Text('No tienes entrenamientos asignados'),
              );
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $error'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _cargarEntrenamientos,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No tienes entrenamientos asignados'),
            );
          } else {
            final entrenamientos = snapshot.data!;
            return ListView.builder(
              itemCount: entrenamientos.length,
              itemBuilder: (context, index) {
                final entrenamiento = entrenamientos[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      'Entrenamiento ${entrenamiento.oposicion}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fecha: ${_formatearFecha(entrenamiento.fecha)}'),
                        Text('Lugar: ${entrenamiento.lugar}'),
                        if (entrenamiento.alumnos.isNotEmpty)
                          Text(
                            'Alumnos: ${entrenamiento.alumnos.length}',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navegar a detalles del entrenamiento si es necesario
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fecha;
    }
  }
}
