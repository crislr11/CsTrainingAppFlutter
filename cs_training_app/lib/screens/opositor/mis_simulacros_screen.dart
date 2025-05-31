import 'package:cs_training_app/services/simulacro/simulacro_service.dart';
import 'package:flutter/material.dart';

import '../../models/simulacro/simulacro.dart';
import '../../widget/simulacro_card.dart';

class MisSimulacrosScreen extends StatefulWidget {
  final int userId;

  const MisSimulacrosScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _MisSimulacrosScreenState createState() => _MisSimulacrosScreenState();
}

class _MisSimulacrosScreenState extends State<MisSimulacrosScreen> {
  final SimulacroService _simulacroService = SimulacroService();
  List<Simulacro> _simulacros = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarSimulacros();
  }

  Future<void> _cargarSimulacros() async {
    try {
      final simulacros = await _simulacroService.getSimulacrosPorUsuario(widget.userId);
      setState(() {
        _simulacros = simulacros;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar simulacros: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Mis Simulacros'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFC107), // Amarillo simulacro
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
        ),
      )
          : _simulacros.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes simulacros asignados',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _cargarSimulacros,
        color: const Color(0xFFFFC107),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _simulacros.length,
          itemBuilder: (context, index) {
            final simulacro = _simulacros[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: SimulacroCard(
                simulacro: simulacro,
                showDeleteButton: false,
              ),
            );
          },
        ),
      ),
    );
  }
}