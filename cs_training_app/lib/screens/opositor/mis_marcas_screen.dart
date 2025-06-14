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
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadEjerciciosYMarcas();
  }

  // Carga inicial de datos
  Future<void> _loadEjerciciosYMarcas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ejercicios = await _ejercicioService.getAllEjercicios();
      await _loadMarcasParaEjercicios(ejercicios);
    } catch (e) {
      _showErrorDialog('Error al cargar datos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Carga las marcas para todos los ejercicios
  Future<void> _loadMarcasParaEjercicios(List<Ejercicio> ejercicios) async {
    final Map<int, List<Marca>> marcasPorEjercicio = {};

    for (Ejercicio ejercicio in ejercicios) {
      try {
        final marcasJson = await _opositorService.getMarcasPorEjercicio(widget.userId, ejercicio.id);
        final marcas = marcasJson.map((e) => Marca.fromJson(e)).toList().cast<Marca>();
        marcas.sort((a, b) => a.fecha.compareTo(b.fecha));

        if (marcas.isNotEmpty) {
          marcasPorEjercicio[ejercicio.id] = marcas;
        }
      } catch (e) {
        debugPrint('Error cargando marcas para ejercicio ${ejercicio.id}: $e');
      }
    }

    // Ordenar ejercicios por cantidad de marcas
    ejercicios.sort((a, b) {
      final countA = marcasPorEjercicio[a.id]?.length ?? 0;
      final countB = marcasPorEjercicio[b.id]?.length ?? 0;
      return countB.compareTo(countA);
    });

    setState(() {
      _ejercicios = ejercicios;
      _marcasPorEjercicio = marcasPorEjercicio;
    });
  }

  // Actualización en tiempo real con pull-to-refresh
  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadMarcasParaEjercicios(_ejercicios);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos actualizados'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error al actualizar: $e');
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  // Actualiza una marca específica después de eliminarla (optimista)
  void _onMarcaEliminada(Marca marcaEliminada) {
    setState(() {
      final ejercicioId = marcaEliminada.ejercicioId;
      if (_marcasPorEjercicio.containsKey(ejercicioId)) {
        _marcasPorEjercicio[ejercicioId]!.removeWhere((m) => m.id == marcaEliminada.id);

        // Si no quedan marcas, remover la entrada
        if (_marcasPorEjercicio[ejercicioId]!.isEmpty) {
          _marcasPorEjercicio.remove(ejercicioId);
        }
      }

      // Reordenar ejercicios
      _reorderEjercicios();
    });
  }

  // Añade una nueva marca y actualiza inmediatamente (optimista)
  void _onMarcaAnadida(Marca nuevaMarca) {
    setState(() {
      final ejercicioId = nuevaMarca.ejercicioId;

      if (_marcasPorEjercicio.containsKey(ejercicioId)) {
        _marcasPorEjercicio[ejercicioId]!.add(nuevaMarca);
        _marcasPorEjercicio[ejercicioId]!.sort((a, b) => a.fecha.compareTo(b.fecha));
      } else {
        _marcasPorEjercicio[ejercicioId] = [nuevaMarca];
      }

      // Reordenar ejercicios
      _reorderEjercicios();
    });
  }

  // Reordena ejercicios por cantidad de marcas
  void _reorderEjercicios() {
    _ejercicios.sort((a, b) {
      final countA = _marcasPorEjercicio[a.id]?.length ?? 0;
      final countB = _marcasPorEjercicio[b.id]?.length ?? 0;
      return countB.compareTo(countA);
    });
  }

  // Actualiza marcas específicas de un ejercicio desde el servidor
  Future<void> _refreshMarcasEjercicio(int ejercicioId) async {
    try {
      final marcasJson = await _opositorService.getMarcasPorEjercicio(widget.userId, ejercicioId);
      final marcas = marcasJson.map((e) => Marca.fromJson(e)).toList().cast<Marca>();
      marcas.sort((a, b) => a.fecha.compareTo(b.fecha));

      setState(() {
        if (marcas.isNotEmpty) {
          _marcasPorEjercicio[ejercicioId] = marcas;
        } else {
          _marcasPorEjercicio.remove(ejercicioId);
        }
        _reorderEjercicios();
      });
    } catch (e) {
      debugPrint('Error actualizando marcas del ejercicio $ejercicioId: $e');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E1),
        title: const Text("Error", style: TextStyle(color: Color(0xFF1A1A1A))),
        content: Text(message, style: const TextStyle(color: Color(0xFF1A1A1A))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK", style: TextStyle(color: Color(0xFFFFC107))),
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
        backgroundColor: const Color(0xFFFFF8E1),
        title: const Text(
          'Nueva Marca',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
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
                    borderSide: const BorderSide(color: Color(0xFFFFC107)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFC107), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _ejercicios.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(e.nombre, style: const TextStyle(color: Color(0xFF1A1A1A))),
                  );
                }).toList(),
                onChanged: (value) => ejercicioSeleccionado = value,
                validator: (value) => value == null ? 'Selecciona un ejercicio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Marca',
                  labelStyle: const TextStyle(color: Color(0xFF1A1A1A)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFC107)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFFC107), width: 2),
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
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF666666))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _guardarNuevaMarca(_formKey, ejercicioSeleccionado, marcaStr),
            child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarNuevaMarca(GlobalKey<FormState> formKey, Ejercicio? ejercicioSeleccionado, String? marcaStr) async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    formKey.currentState!.save();

    if (ejercicioSeleccionado == null || marcaStr == null) return;

    try {
      final double valorMarca = double.parse(marcaStr);
      final nuevaMarca = Marca(
        userId: widget.userId,
        ejercicioId: ejercicioSeleccionado.id,
        valor: valorMarca,
        fecha: DateTime.now(),
      );

      // Actualización optimista
      _onMarcaAnadida(nuevaMarca);
      Navigator.of(context).pop();

      // Guardar en servidor
      await _opositorService.addMarca(nuevaMarca);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marca creada correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Refrescar datos del ejercicio para sincronizar con servidor
      await _refreshMarcasEjercicio(ejercicioSeleccionado.id);

    } catch (e) {
      // Revertir cambio optimista en caso de error
      await _refreshMarcasEjercicio(ejercicioSeleccionado!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear marca: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Marcas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshData,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioCrearMarca,
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : _ejercicios.isEmpty || _marcasPorEjercicio.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFFFFC107),
        child: _buildMarcasList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          const Text(
            'No hay marcas registradas',
            style: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toca el botón + para añadir tu primera marca',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMarcasList() {
    final ejerciciosConMarcas = _ejercicios.where((e) => _marcasPorEjercicio.containsKey(e.id)).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ejerciciosConMarcas.length,
      itemBuilder: (context, index) {
        final ejercicio = ejerciciosConMarcas[index];
        final marcas = _marcasPorEjercicio[ejercicio.id] ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  ejercicio.nombre.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                    shadows: [
                      Shadow(
                        color: Color(0xFFFFC107),
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Grafica(
                  key: ValueKey('${ejercicio.id}_${marcas.length}_${marcas.isNotEmpty ? marcas.last.fecha.millisecondsSinceEpoch : 0}'),
                  marcas: marcas,
                  ejercicioNombre: ejercicio.nombre,
                  onDeleteMarca: _onMarcaEliminada,
                  onRefreshEjercicio: () => _refreshMarcasEjercicio(ejercicio.id),
                ),
                const SizedBox(height: 12),
                if (marcas.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.3)),
                    ),
                    child: Text(
                      'Última marca: ${marcas.last.valor.toStringAsFixed(2)} (${DateFormat('dd/MM/yyyy').format(marcas.last.fecha)})',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total de marcas: ${marcas.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}