import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/marca.dart';
import '../../models/simulacro/ejercicio.dart';
import '../../services/opositor_service.dart';
import '../../services/simulacro/ejercicio_service.dart';
import '../../widget/grafica_widget.dart';

class MisMarcasScreen extends StatefulWidget {
  final int userId;

  const MisMarcasScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<MisMarcasScreen> createState() => _MisMarcasScreenState();
}

class _MisMarcasScreenState extends State<MisMarcasScreen> {
  final OpositorService _opositorService = OpositorService();
  final EjercicioService _ejercicioService = EjercicioService();
  List<Ejercicio> _ejercicios = [];
  Map<int, List<Marca>> _marcasPorEjercicio = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEjerciciosYMarcas();
  }

  Future<void> _loadEjerciciosYMarcas() async {
    try {
      final ejercicios = await _ejercicioService.getAllEjercicios();
      final Map<int, List<Marca>> marcasPorEjercicio = {};

      for (Ejercicio ejercicio in ejercicios) {
        final marcasJson =
        await _opositorService.getMarcasPorEjercicio(widget.userId, ejercicio.id);
        final marcas = marcasJson.map((e) => Marca.fromJson(e)).toList().cast<Marca>();
        marcas.sort((a, b) => a.fecha.compareTo(b.fecha));
        if (marcas.isNotEmpty) {
          marcasPorEjercicio[ejercicio.id] = marcas;
        }
      }

      // Ordenamos la lista de ejercicios según la cantidad de marcas, de mayor a menor
      ejercicios.sort((a, b) {
        final countA = marcasPorEjercicio[a.id]?.length ?? 0;
        final countB = marcasPorEjercicio[b.id]?.length ?? 0;
        return countB.compareTo(countA);
      });

      setState(() {
        _ejercicios = ejercicios; // ya ordenados
        _marcasPorEjercicio = marcasPorEjercicio;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error al cargar datos: $e');
    }
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Future<void> _mostrarFormularioCrearMarca() async {
    final _formKey = GlobalKey<FormState>();
    Ejercicio? ejercicioSeleccionado;
    String? marcaStr;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E1), // amarillo muy claro para fondo
        title: const Text(
          'Nueva Marca',
          style: TextStyle(color: Color(0xFF1A1A1A)), // texto oscuro
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Ejercicio>(
                decoration: InputDecoration(
                  labelText: 'Ejercicio',
                  labelStyle: const TextStyle(color: Color(0xFF1A1A1A)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFC107)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFC107), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _ejercicios.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(e.nombre, style: const TextStyle(color: Color(0xFF1A1A1A))),
                  );
                }).toList(),
                onChanged: (value) {
                  ejercicioSeleccionado = value;
                },
                validator: (value) => value == null ? 'Selecciona un ejercicio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Marca',
                  labelStyle: const TextStyle(color: Color(0xFF1A1A1A)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFC107)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFC107), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa la marca';
                  final v = double.tryParse(value);
                  if (v == null) return 'Marca inválida';
                  if (v <= 0) return 'Marca debe ser mayor a cero';
                  return null;
                },
                onSaved: (value) => marcaStr = value,
                style: const TextStyle(color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFFFFC107))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107), // amarillo
              foregroundColor: Colors.black, // texto negro
            ),
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                _formKey.currentState!.save();

                try {
                  if (ejercicioSeleccionado != null && marcaStr != null) {
                    final double valorMarca = double.parse(marcaStr!);
                    final nuevaMarca = Marca(
                      userId: widget.userId,
                      ejercicioId: ejercicioSeleccionado!.id,
                      valor: valorMarca,
                      fecha: DateTime.now(),
                    );
                    await _opositorService.addMarca(nuevaMarca);

                    Navigator.of(context).pop();

                    await _loadEjerciciosYMarcas();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marca creada correctamente')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al crear marca: $e')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _navegarACrearMarca() {
    _mostrarFormularioCrearMarca();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Marcas'),
        backgroundColor: const Color(0xFFFFC107),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarACrearMarca,
        backgroundColor: const Color(0xFFFFC107), // amarillo
        child: const Icon(Icons.add, color: Colors.black), // icono negro
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : _ejercicios.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No hay marcas registradas',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ejercicios.length,
        itemBuilder: (context, index) {
          final ejercicio = _ejercicios[index];
          final marcas = _marcasPorEjercicio[ejercicio.id] ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    ejercicio.nombre.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      shadows: [
                        Shadow(
                          color: Colors.yellow,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Grafica(
                    marcas: marcas,
                    ejercicioNombre: ejercicio.nombre,
                    // valor máximo por defecto (ajusta según contexto)
                  ),
                  const SizedBox(height: 8),
                  if (marcas.isNotEmpty)
                    Text(
                      'Última marca: ${marcas.last.valor.toStringAsFixed(2)} (${DateFormat('dd/MM/yyyy').format(marcas.last.fecha)})',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const Text(
                      'No hay marcas registradas para este ejercicio',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
