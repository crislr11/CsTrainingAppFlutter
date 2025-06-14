import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/entrenamiento.dart';
import '../../routes/routes.dart';
import '../../services/entrenamiento_service.dart';
import '../../widget/built_entrenamiento_card.dart';
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
  String? oposicionSeleccionada = 'todos';

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
    return oposicion.replaceAll('_', ' ');
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
        resultado = await entrenamientoService.getTrainingsByOpposition(oposicion);
        if (inicio != null && fin != null) {
          resultado = resultado.where((entrenamiento) {
            DateTime fechaEntrenamiento = entrenamiento.fecha;
            return fechaEntrenamiento.isAfter(inicio.subtract(const Duration(days: 1))) &&
                fechaEntrenamiento.isBefore(fin.add(const Duration(days: 1)));
          }).toList();
        }
      } else if (inicio != null && fin != null) {
        resultado = await entrenamientoService.getTrainingsByDateRange(inicio, fin);
      } else {
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

  Future<void> _confirmarEliminar(Entrenamiento entrenamiento) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirmar eliminación',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro de que deseas eliminar este entrenamiento?',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatearOposicion(entrenamiento.oposicion),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(entrenamiento.fecha)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Lugar: ${entrenamiento.lugar}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Alumnos inscritos: ${entrenamiento.alumnos.length}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Esta acción no se puede deshacer y eliminará todas las inscripciones.',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFF666666),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await entrenamientoService.deleteTraining(entrenamiento.id ?? 0);
        _cargarEntrenamientos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Entrenamiento eliminado correctamente'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Error al eliminar: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _editarEntrenamiento(Entrenamiento entrenamiento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrearClaseScreen(entrenamiento: entrenamiento),
      ),
    ).then((_) {
      _cargarEntrenamientos();
    });
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
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.black),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.adminHome);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetearFiltro,
            tooltip: 'Resetear filtros',
          ),
        ],
      ),

      // Body
      body: Column(
        children: [
          // Filtros mejorados
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Filtro de fechas
                Row(
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
                              : DateFormat('dd/MM/yyyy').format(fechaInicio!),
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
                              : DateFormat('dd/MM/yyyy').format(fechaFin!),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (fechaInicio != null && fechaFin != null) {
                          _cargarEntrenamientos(inicio: fechaInicio, fin: fechaFin, oposicion: oposicionSeleccionada);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Selecciona ambas fechas')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      ),
                      child: const Icon(Icons.search),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Desplegable para elegir oposición
                Row(
                  children: [
                    const Text(
                      'Oposición: ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFFFC107)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: oposicionSeleccionada,
                          underline: const SizedBox(),
                          items: oposiciones.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                _formatearOposicion(value),
                                overflow: TextOverflow.ellipsis,
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
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contador de entrenamientos encontrados
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFFFC107).withOpacity(0.1),
            child: Text(
              'Entrenamientos encontrados: ${entrenamientos.length}',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // Lista de entrenamientos usando EntrenamientoCard
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
                : noHayResultados
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay entrenamientos disponibles',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
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

                return Stack(
                  children: [
                    // Usamos el EntrenamientoCard pero sin funcionalidad de apuntarse
                    EntrenamientoCard(
                      entrenamiento: entrenamiento,
                      inscrito: false,
                      onApuntarse: null,
                      onDesapuntarse: null,
                    ),

                    // Botones de administración superpuestos
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                              onPressed: () => _editarEntrenamiento(entrenamiento),
                              tooltip: 'Editar entrenamiento',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _confirmarEliminar(entrenamiento),
                              tooltip: 'Eliminar entrenamiento',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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