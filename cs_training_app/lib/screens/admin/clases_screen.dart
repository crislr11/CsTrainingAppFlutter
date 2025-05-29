import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';  // Importa intl para formatear fechas
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
  bool noHayResultados = false;
  List<Entrenamiento> entrenamientos = [];
  final EntrenamientoService entrenamientoService = EntrenamientoService();
  DateTime? fechaInicio;
  DateTime? fechaFin;
  String? oposicionSeleccionada = 'todos'; // Oposición seleccionada

  // Lista de oposiciones con sus valores originales
  final List<String> oposiciones = [
    'todos',
    'POLICIA_NACIONAL',
    'POLICIA_LOCAL',
    'SUBOFICIAL',
    'GUARDIA_CIVIL',
    'SERVICIO_VIGILANCIA_ADUANERA'
  ];

  // Función para convertir el valor de la oposición a una forma legible
  String _formatearOposicion(String oposicion) {
    if (oposicion == 'todos') return 'Todos';
    return oposicion.replaceAll('_', ' '); // Mantiene el valor original pero reemplaza _ por espacio
  }

  @override
  void initState() {
    super.initState();
    _cargarEntrenamientos();
  }

  Future<void> _cargarEntrenamientos({DateTime? inicio, DateTime? fin, String? oposicion}) async {
    setState(() {
      isLoading = true;
      noHayResultados = false;
    });

    try {
      List<Entrenamiento> resultado;

      if (oposicion != null && oposicion != 'todos') {
        // Si hay oposición, primero filtramos por oposición
        resultado = await entrenamientoService.getTrainingsByOpposition(oposicion);
        if (inicio != null && fin != null) {
          // Luego filtramos manualmente por fechas (localmente)
          resultado = resultado.where((entrenamiento) {
            DateTime fechaEntrenamiento = entrenamiento.fecha;
            return fechaEntrenamiento.isAfter(inicio.subtract(const Duration(days: 1))) &&
                fechaEntrenamiento.isBefore(fin.add(const Duration(days: 1)));
          }).toList();
        }
      } else if (inicio != null && fin != null) {
        // Si no hay oposición pero sí fechas
        resultado = await entrenamientoService.getTrainingsByDateRange(inicio, fin);
      } else {
        // Si no hay nada filtrado
        resultado = await entrenamientoService.getAllTrainings();
      }

      // Ordenar los entrenamientos de mayor a menor fecha
      resultado.sort((a, b) {
        DateTime fechaA = a.fecha;
        DateTime fechaB = b.fecha;
        return fechaB.compareTo(fechaA);
      });

      setState(() {
        entrenamientos = resultado;
        isLoading = false;
        noHayResultados = resultado.isEmpty;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        entrenamientos = [];
        noHayResultados = true;
      });
    }
  }

  Future<void> _seleccionarFechaInicio() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      if (fechaFin != null && picked.isAfter(fechaFin!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La fecha de inicio no puede ser mayor que la fecha fin')),
        );
      } else {
        setState(() {
          fechaInicio = picked;
        });
      }
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      if (fechaInicio != null && picked.isBefore(fechaInicio!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La fecha de fin no puede ser menor que la fecha de inicio')),
        );
      } else {
        setState(() {
          fechaFin = picked;
        });
      }
    }
  }

  void _resetearFiltro() {
    setState(() {
      fechaInicio = null;
      fechaFin = null;
      oposicionSeleccionada = 'todos';
    });
    _cargarEntrenamientos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: AppBar(
        title: Text(
          'Entrenamientos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFC107),
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.black),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.adminHome);
          },
        ),
      ),

      // Body
      body: Column(
        children: [
          // Filtro de fechas y oposición
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _seleccionarFechaInicio,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      fechaInicio == null
                          ? 'Fecha Inicio'
                          : DateFormat('yyyy-MM-dd').format(fechaInicio!),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _seleccionarFechaFin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      fechaFin == null
                          ? 'Fecha Fin'
                          : DateFormat('yyyy-MM-dd').format(fechaFin!),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black),
                  onPressed: () {
                    if (fechaInicio != null && fechaFin != null) {
                      _cargarEntrenamientos(inicio: fechaInicio, fin: fechaFin, oposicion: oposicionSeleccionada);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecciona ambas fechas')),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black),
                  onPressed: _resetearFiltro,
                ),
              ],
            ),
          ),

          // Desplegable para elegir oposición
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Oposición: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), // fuente más pequeña
                ),
                const SizedBox(width: 10),
                Expanded(  // para que ocupe espacio disponible sin overflow
                  child: DropdownButton<String>(
                    isExpanded: true,  // importante para que el dropdown ocupe todo el ancho del Expanded
                    value: oposicionSeleccionada,
                    items: oposiciones.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          _formatearOposicion(value),
                          overflow: TextOverflow.ellipsis, // recorta texto largo con puntos suspensivos
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        oposicionSeleccionada = newValue;
                      });
                      _cargarEntrenamientos(inicio: fechaInicio, fin: fechaFin, oposicion: oposicionSeleccionada);
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Contador de entrenamientos encontrados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Entrenamientos encontrados: ${entrenamientos.length}',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Lista de entrenamientos
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : noHayResultados
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No hay entrenamientos disponibles'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _resetearFiltro,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Resetear Filtro'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entrenamientos.length,
              itemBuilder: (context, index) {
                final entrenamiento = entrenamientos[index];
                final fechaHoraFormateada = DateFormat('d MMM y · HH:mm', 'es_ES')
                    .format(entrenamiento.fecha);

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    title: Text(
                      _formatearOposicion(entrenamiento.oposicion),
                      style: GoogleFonts.rubik(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📅 $fechaHoraFormateada',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('📍 Lugar: ${entrenamiento.lugar}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirmar eliminación'),
                                content: const Text('¿Estás seguro de que deseas eliminar este entrenamiento?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                await entrenamientoService.deleteTraining(entrenamiento.id ?? 0);
                                _cargarEntrenamientos();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Entrenamiento eliminado')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error al eliminar: $e')),
                                );
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CrearClaseScreen(entrenamiento: entrenamiento),
                              ),
                            ).then((_) {
                              _cargarEntrenamientos();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),

      // Botón de añadir nuevo entrenamiento
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.crearClase);
          _cargarEntrenamientos();
        },
      ),
    );
  }
}
