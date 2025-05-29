import 'package:cs_training_app/services/simulacro/ejercicio_service.dart';
import 'package:flutter/material.dart';
import 'package:cs_training_app/models/user.dart';
import 'package:cs_training_app/services/admin_services.dart';
import 'package:cs_training_app/models/simulacro/simulacro.dart';
import '../../models/simulacro/ejercicio.dart';
import '../../models/simulacro/ejercicio_marca.dart';
import '../../services/simulacro/simulacro.dart';

class CrearSimulacroScreen extends StatefulWidget {
  const CrearSimulacroScreen({super.key});

  @override
  State<CrearSimulacroScreen> createState() => _CrearSimulacroScreenState();
}

class _CrearSimulacroScreenState extends State<CrearSimulacroScreen> {
  List<User> _opositores = [];
  final AdminService _adminService = AdminService();
  final SimulacroService _simulacroService = SimulacroService();
  final EjercicioService _ejercicioService = EjercicioService();

  List<Simulacro> _simulacrosUsuario = [];
  String _nombreUsuarioSeleccionado = '';
  User? _usuarioSeleccionado;

  List<Ejercicio> _ejercicios = [];
  Ejercicio? _ejercicioSeleccionado;
  double _marca = 0;

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  DateTime? _fechaSeleccionada;


  Simulacro? _simulacroEnCreacion;
  bool _estaCreandoSimulacro = false;
  bool _estaAgregandoEjercicio = false;

  final TextEditingController _marcaController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadEjercicios();
  }

  @override
  void dispose() {
    _marcaController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      List<User> users = await _adminService.getAllUsers();
      setState(() {
        _opositores = users.where((user) => user.role == 'OPOSITOR').toList();
      });
    } catch (error) {
      _showErrorDialog("Hubo un error al cargar los usuarios: $error");
    }
  }

  Future<void> _loadEjercicios() async {
    try {
      List<Ejercicio> ejercicios = await _ejercicioService.getAllEjercicios();
      setState(() {
        _ejercicios = ejercicios;
      });
    } catch (error) {
      _showErrorDialog("Hubo un error al cargar los ejercicios: $error");
    }
  }


  Future<void> _seleccionarUsuario(User user) async {
    try {
      final simulacros = await _simulacroService.getSimulacrosPorUsuario(user.id);
      setState(() {
        _simulacrosUsuario = simulacros;
        _nombreUsuarioSeleccionado = user.nombreUsuario;
        _usuarioSeleccionado = user;
        _simulacroEnCreacion = null;
      });
    } catch (error) {
      _showErrorDialog("Error al cargar simulacros: $error");
    }
  }

  Future<void> _eliminarSimulacro(int simulacroId) async {
    try {
      await _simulacroService.deleteSimulacro(simulacroId);
      setState(() {
        _simulacrosUsuario.removeWhere((s) => s.id == simulacroId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simulacro eliminado correctamente')),
      );
    } catch (error) {
      _showErrorDialog("Error al eliminar simulacro: $error");
    }
  }

  Future<void> _crearSimulacro() async {
    if (_tituloController.text.isEmpty || _fechaSeleccionada == null || _usuarioSeleccionado == null) {
      _showErrorDialog("Debes completar título, fecha y seleccionar usuario.");
      return;
    }

    setState(() => _estaCreandoSimulacro = true);

    try {
      final simulacro = Simulacro(
        titulo: _tituloController.text,
        fecha: _fechaSeleccionada!.toIso8601String(),
        ejercicios: [],
      );

      // 1. Guardar simulacro
      final nuevoSimulacro = await _simulacroService.saveSimulacro(simulacro);

      if (nuevoSimulacro == null) {
        throw Exception('El servicio devolvió null al crear el simulacro');
      }

      // 2. Asignar a usuario
      final simulacroAsignado = await _simulacroService.asignarSimulacroAUsuario(
          nuevoSimulacro.id!,
          _usuarioSeleccionado!.id!
      );

      if (simulacroAsignado == null) {
        throw Exception('No se pudo asignar el simulacro al usuario');
      }

      setState(() {
        _simulacroEnCreacion = simulacroAsignado;
        _simulacrosUsuario.add(simulacroAsignado);
      });

      Navigator.of(context).pop();
      _mostrarDialogoAgregarEjercicios();

    } catch (e) {
      _showErrorDialog("Error al crear simulacro: ${e.toString()}");
      debugPrint('Error detallado: $e');
    } finally {
      setState(() => _estaCreandoSimulacro = false);
    }
  }

  void _mostrarFormularioCrearSimulacro() {
    _tituloController.clear();
    _fechaController.clear();
    _fechaSeleccionada = null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuevo Simulacro"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tituloController,
              decoration: InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: const Color(0xFFFFF8E1),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fechaController,
              readOnly: true,
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFFFFC107),
                          onPrimary: Colors.black,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  setState(() {
                    _fechaSeleccionada = pickedDate;
                    _fechaController.text =
                    '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Fecha',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: const Color(0xFFFFF8E1),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: _crearSimulacro,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black,
            ),
            child: _estaCreandoSimulacro
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text("Crear"),
          ),
        ],
      ),
    );
  }


  void _mostrarDialogoAgregarEjercicios() {
    // Resetear los campos al abrir el diálogo
    setState(() {
      _ejercicioSeleccionado = null;
      _marca = 0;
      _marcaController.clear();
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Añadir Ejercicio al Simulacro"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Ejercicio>(
                  value: _ejercicioSeleccionado,
                  onChanged: (newValue) {
                    setDialogState(() {
                      _ejercicioSeleccionado = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Ejercicio',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: const Color(0xFFFFF8E1),
                  ),
                  items: _ejercicios.map((ejercicio) {
                    return DropdownMenuItem<Ejercicio>(
                      value: ejercicio,
                      child: Text(ejercicio.nombre ?? 'Sin nombre'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _marcaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Marca',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: const Color(0xFFFFF8E1),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      _marca = double.tryParse(value) ?? 0;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Simulacro creado correctamente')),
                  );
                },
                child: const Text("Finalizar"),
              ),
              ElevatedButton(
                onPressed: () async {
                  setDialogState(() {
                    _estaAgregandoEjercicio = true;
                  });

                  await _agregarEjercicioASimulacro(); // Si esta función no es async, quítale el await

                  // Limpiar campos después de añadir
                  setDialogState(() {
                    _ejercicioSeleccionado = null;
                    _marca = 0;
                    _marcaController.clear();
                    _estaAgregandoEjercicio = false; // ¡Importante!
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black,
                ),
                child: _estaAgregandoEjercicio
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
                    : const Text("Añadir Ejercicio"),
              ),

            ],
          );
        },
      ),
    );
  }


  Ejercicio obtenerEjercicioPorId(int idEjercicio) {
    // Buscar el ejercicio en la lista _ejercicios por su id
    final ejercicio = _ejercicios.firstWhere(
          (ejercicio) => ejercicio.id == idEjercicio,
      orElse: () => Ejercicio(id: 0, nombre: 'Ejercicio no encontrado', marca: 0),
    );

    return ejercicio;
  }



  Future<void> _agregarEjercicioASimulacro() async {
    if (_ejercicioSeleccionado == null || _simulacroEnCreacion == null) {
      _showErrorDialog("Debes seleccionar un ejercicio");
      return;
    }

    setState(() {
      _estaAgregandoEjercicio = true;
    });


    try {
      // Obtén el nombre del ejercicio seleccionado
      String nombreEjercicio = _ejercicioSeleccionado!.nombre;

      // Llama al servicio para agregar el ejercicio al simulacro
      final simulacroActualizado = await _simulacroService.agregarEjercicioASimulacro(
        simulacroId: _simulacroEnCreacion!.id ?? 0,
        ejercicioId: _ejercicioSeleccionado!.id ?? 0,
        marca: _marca,
        nombre: nombreEjercicio,
      );

      if (simulacroActualizado != null) {
        setState(() {
          final index = _simulacrosUsuario.indexWhere((s) => s.id == _simulacroEnCreacion!.id);
          if (index != -1) {
            _simulacrosUsuario[index] = simulacroActualizado;
          }
          _simulacroEnCreacion = simulacroActualizado;
          _ejercicioSeleccionado = null;
          _marca = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ejercicio añadido correctamente')),
        );
      }
    } catch (error) {
      _showErrorDialog("Error al añadir ejercicio: $error");
    } finally {
      setState(() {
        _estaAgregandoEjercicio = false;
      });
    }
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (_) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Simulacro"),
        backgroundColor: const Color(0xFFFFC107),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Autocomplete<User>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return _opositores;
                }
                return _opositores.where((User user) {
                  return user.nombreUsuario.toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              displayStringForOption: (User user) => user.nombreUsuario,
              onSelected: (User user) {
                FocusScope.of(context).unfocus();
                _seleccionarUsuario(user);
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Buscar por nombre de usuario',
                    hintText: 'Escribe el nombre del opositor...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    suffixIcon: const Icon(Icons.search),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final User option = options.elementAt(index);
                        return ListTile(
                          title: Text(option.nombreUsuario),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _nombreUsuarioSeleccionado.isNotEmpty
                  ? _mostrarFormularioCrearSimulacro
                  : null,
              icon: _estaCreandoSimulacro
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Icon(Icons.add),
              label: const Text("Crear Simulacro"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC107),
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            if (_nombreUsuarioSeleccionado.isNotEmpty)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simulacros de $_nombreUsuarioSeleccionado',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _simulacrosUsuario.isEmpty
                        ? const Text(
                      'Este usuario no tiene simulacros asignados.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    )
                        : Expanded(
                      child: ListView.builder(
                        itemCount: _simulacrosUsuario.length,
                        itemBuilder: (context, index) {
                          final simulacro = _simulacrosUsuario[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                              collapsedBackgroundColor: const Color(0xFFFFC107),
                              backgroundColor: const Color(0xFFFFF8E1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          simulacro.titulo ?? '',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Fecha: ${_formatearFecha(simulacro.fecha)}',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Confirmar eliminación'),
                                          content: const Text('¿Estás seguro de que quieres eliminar este simulacro?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                _eliminarSimulacro(simulacro.id ?? 0);
                                              },
                                              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              children: simulacro.ejercicios.isEmpty
                                  ? [
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text(
                                    "Este simulacro no tiene ejercicios.",
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                              ]
                                  : simulacro.ejercicios.map((ejercicio) {
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  color: const Color(0xFFFFC107),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    title: Text(
                                      ejercicio.nombre ?? 'Nombre desconocido', // Acceder a 'nombre' directamente
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    subtitle: Text(
                                      'MARCA: ${ejercicio.marca.toString()}', // Mostrar la marca, asegurándose de que siempre sea una cadena
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),


                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}