import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/entrenamiento.dart';
import '../../models/user.dart';
import '../../services/admin_services.dart';
import '../../services/entrenamiento_service.dart';

class CrearClaseScreen extends StatefulWidget {
  const CrearClaseScreen({super.key});

  @override
  State<CrearClaseScreen> createState() => _CrearClaseScreenState();
}

class _CrearClaseScreenState extends State<CrearClaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();
  final _entrenamientoService = EntrenamientoService();

  List<User> profesoresDisponibles = [];
  String? oposicionSeleccionada;
  String? lugarSeleccionado;
  User? profesor1;
  User? profesor2;
  DateTime? fechaSeleccionada;

  final List<String> oposiciones = [
    'BOMBERO',
    'POLICIA_NACIONAL',
    'POLICIA_LOCAL',
    'SUBOFICIAL',
    'GUARDIA_CIVIL',
    'SERVICIO_VIGILANCIA_ADUANERA',
    'INGRESO_FUERZAS_ARMADAS',
    'NINGUNA',
  ];

  final List<String> lugares = ['NAVE', 'PISTA'];

  @override
  void initState() {
    super.initState();
    _cargarProfesores();
  }

  Future<void> _cargarProfesores() async {
    try {
      final usuarios = await _adminService.getAllUsers();
      setState(() {
        profesoresDisponibles = usuarios.where((u) => u.role == 'PROFESOR').toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar profesores: $e')),
      );
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (fecha != null) {
      final TimeOfDay? hora = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (hora != null) {
        setState(() {
          fechaSeleccionada = DateTime(
            fecha.year,
            fecha.month,
            fecha.day,
            hora.hour,
            hora.minute,
          );
        });
      }
    }
  }

  Future<void> _guardarClase() async {
    if (!_formKey.currentState!.validate() || profesor1 == null || profesor2 == null || fechaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    final nuevoEntrenamiento = Entrenamiento(
      id: 0,
      oposicion: oposicionSeleccionada!,
      profesores: [profesor1!.nombreUsuario, profesor2!.nombreUsuario],
      alumnos: [],
      fecha: fechaSeleccionada!.toIso8601String(),
      lugar: lugarSeleccionado!,
    );

    try {
      await _entrenamientoService.createTraining(nuevoEntrenamiento);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clase creada con éxito')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear clase: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Clase'),
        backgroundColor: const Color(0xFFFFC107),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Oposición'),
                items: oposiciones.map((op) => DropdownMenuItem(value: op, child: Text(op))).toList(),
                onChanged: (value) => setState(() => oposicionSeleccionada = value),
                validator: (value) => value == null ? 'Selecciona una oposición' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Lugar'),
                items: lugares.map((lugar) => DropdownMenuItem(value: lugar, child: Text(lugar))).toList(),
                onChanged: (value) => setState(() => lugarSeleccionado = value),
                validator: (value) => value == null ? 'Selecciona un lugar' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<User>(
                decoration: const InputDecoration(labelText: 'Profesor 1'),
                items: profesoresDisponibles.map((profesor) {
                  return DropdownMenuItem(value: profesor, child: Text(profesor.nombreUsuario));
                }).toList(),
                onChanged: (value) => setState(() => profesor1 = value),
                validator: (value) => value == null ? 'Selecciona un profesor' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<User>(
                decoration: const InputDecoration(labelText: 'Profesor 2'),
                items: profesoresDisponibles.map((profesor) {
                  return DropdownMenuItem(value: profesor, child: Text(profesor.nombreUsuario));
                }).toList(),
                onChanged: (value) => setState(() => profesor2 = value),
                validator: (value) => value == null ? 'Selecciona un profesor' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  fechaSeleccionada == null
                      ? 'Seleccionar fecha y hora'
                      : DateFormat('yyyy-MM-dd – kk:mm').format(fechaSeleccionada!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _seleccionarFecha,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _guardarClase,
                icon: const Icon(Icons.save),
                label: const Text('Guardar clase'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC107),
                  foregroundColor: Colors.black,
                  textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
