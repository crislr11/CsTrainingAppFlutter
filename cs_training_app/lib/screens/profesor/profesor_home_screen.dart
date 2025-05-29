import 'package:flutter/material.dart';
import 'package:cs_training_app/models/entrenamiento.dart';
import 'package:cs_training_app/services/entrenamiento_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cs_training_app/models/user.dart';
import '../../routes/routes.dart';
import 'package:intl/intl.dart';


class ProfesorHomeScreen extends StatefulWidget {
  const ProfesorHomeScreen({super.key});

  @override
  State<ProfesorHomeScreen> createState() => _ProfesorHomeScreenState();
}

class _ProfesorHomeScreenState extends State<ProfesorHomeScreen> {
  late Future<List<Entrenamiento>> _futureEntrenamientos;
  final EntrenamientoService _entrenamientoService = EntrenamientoService();
  String _nombreProfesor = '';
  String _nombreUsuario = '';
  String _oposicion = '';


  @override
  void initState() {
    super.initState();
    _cargarDatosProfesor();
    _cargarEntrenamientos();
  }

  Future<void> _cargarDatosProfesor() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreProfesor = prefs.getString('nombre') ?? 'Profesor';
      _nombreUsuario = prefs.getString('nombreUsuario') ?? '';

    });
  }

  void _mostrarAlumnosDialog(BuildContext context, List<User> alumnos) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (_) {
        if (alumnos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No hay alumnos apuntados.'),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Alumnos apuntados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...alumnos.map((alumno) => ListTile(
                leading: const Icon(Icons.person),
                title: Text(alumno.nombreUsuario),
                subtitle: Text(alumno.nombre),
              )),
            ],
          ),
        );
      },
    );
  }


  void _cargarEntrenamientos() async {
    final prefs = await SharedPreferences.getInstance();
    final profesorId = prefs.getInt('id');

    if (profesorId == null) {
      setState(() {
        _futureEntrenamientos = Future.error(
          'No se encontró el ID del profesor en SharedPreferences',
        );
      });
      return;
    }

    // Asigna el Future a _futureEntrenamientos antes de llamar a setState
    final entrenamientos = _entrenamientoService.getFutureTrainingsByProfessor(profesorId);

    setState(() {
      _futureEntrenamientos = entrenamientos;
    });
  }


  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Entrenamientos'),
        backgroundColor: const Color(0xFFFFC107),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEntrenamientos,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Fondo negro que ocupa todo el ancho de la pantalla
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              width: double.infinity,  // Esto asegura que el contenedor ocupe todo el ancho disponible
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFFFC107),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _nombreProfesor,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$_nombreUsuario',
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.crearSimulacro);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  backgroundColor: const Color(0xFFFFC107),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('Crear Simulacro'),
              ),
            ),
            FutureBuilder<List<Entrenamiento>>(
              future: _futureEntrenamientos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  final error = snapshot.error.toString();
                  if (error.contains('NO_ENTRENAMIENTOS')) {
                    return const Center(child: Text('No tienes entrenamientos asignados'));
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
                  return const Center(child: Text('No tienes entrenamientos asignados'));
                } else {
                  final entrenamientos = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entrenamientos.length,
                    itemBuilder: (context, index) {
                      final entrenamiento = entrenamientos[index];
                      final fechaHoraFormateada =
                      DateFormat('d MMM y · HH:mm', 'es_ES').format(entrenamiento.fecha);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 3,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          title: Text(
                            entrenamiento.oposicion.replaceAll('_', ' '),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📅 Fecha: $fechaHoraFormateada',
                                  style: const TextStyle(color: Colors.black),
                                ),
                                Text(
                                  '📍 Lugar: ${entrenamiento.lugar}',
                                  style: const TextStyle(color: Colors.black),
                                ),
                                if (entrenamiento.alumnos.isNotEmpty)
                                  Text(
                                    '👥 Alumnos: ${entrenamiento.alumnos.length}',
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.black),
                          onTap: () {
                            // Acción al pulsar el entrenamiento
                          },
                          onLongPress: () {
                            _mostrarAlumnosDialog(context, entrenamiento.alumnos);
                          },
                        ),
                      );
                    },
                  );

                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(0, '0')}';
    } catch (_) {
      return fecha;
    }
  }
}
