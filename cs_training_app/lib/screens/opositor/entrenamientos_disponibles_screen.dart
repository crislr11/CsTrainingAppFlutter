import 'package:cs_training_app/services/entrenamiento_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/Opositor_service.dart';
import '../../widget/built_entrenamiento_card.dart';

class EntrenamientosDisponiblesScreen extends StatefulWidget {
  final String oposicion;

  const EntrenamientosDisponiblesScreen({
    super.key,
    required this.oposicion,
  });

  @override
  State<EntrenamientosDisponiblesScreen> createState() => _EntrenamientosDisponiblesScreenState();
}

class _EntrenamientosDisponiblesScreenState extends State<EntrenamientosDisponiblesScreen> {
  final OpositorService _service = OpositorService();
  final EntrenamientoService _entrenamientoService = EntrenamientoService();
  List<dynamic> _entrenamientos = [];
  bool _loading = true;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadUserId().then((_) => _cargarEntrenamientos());
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('id') ?? 0;
    });
  }

  Future<void> _cargarEntrenamientos() async {
    setState(() {
      _loading = true;
    });

    try {
      final entrenamientos = await _entrenamientoService.getFuturosEntrenamientosPorOposicion(widget.oposicion);
      final misEntrenamientos = await _service.getEntrenamientosDelOpositor(_userId);

      final entrenamientosDisponibles = entrenamientos.where((ent) =>
      !misEntrenamientos.any((me) => me.id == ent.id)
      ).toList();

      setState(() {
        _entrenamientos = entrenamientosDisponibles;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _apuntarseAEntrenamiento(int entrenamientoId) async {
    try {
      final result = await _service.apuntarseAEntrenamiento(entrenamientoId, _userId);
      if (!mounted) return;

      if (result != null) {
        // Si hay un mensaje, lo mostramos
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
        await _cargarEntrenamientos();
      }
      // Si result es null, no se muestra nada (fallo silencioso)
    } catch (_) {
      // Errores silenciosos (no mostrar nada)
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenamientos Disponibles'),
        backgroundColor: const Color(0xFFFFC107),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entrenamientos.isEmpty
          ? const Center(child: Text('No hay entrenamientos disponibles para esta oposición'))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _entrenamientos.length,
        itemBuilder: (context, index) {
          final entrenamiento = _entrenamientos[index];
          final inscrito = entrenamiento.alumnos.any((alumno) => alumno.id == _userId);

          return EntrenamientoCard(
            entrenamiento: entrenamiento,
            inscrito: inscrito,
            onApuntarse: () => _apuntarseAEntrenamiento(entrenamiento.id!),
            onDesapuntarse: null,
          );
        },
      ),
    );
  }

}