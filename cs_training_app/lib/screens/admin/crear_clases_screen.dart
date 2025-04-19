import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/entrenamiento.dart';
import '../../models/user.dart';
import '../../services/admin_services.dart';
import '../../services/entrenamiento_service.dart';
import '../../routes/routes.dart';  // Asegúrate de importar las rutas si las usas

class CrearClaseScreen extends StatefulWidget {
  final Entrenamiento? entrenamiento;

  const CrearClaseScreen({super.key, this.entrenamiento});

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

        // Si estamos editando, inicializamos los valores
        final entrenamiento = widget.entrenamiento;
        if (entrenamiento != null) {
          oposicionSeleccionada = entrenamiento.oposicion;
          lugarSeleccionado = entrenamiento.lugar;
          fechaSeleccionada = DateTime.parse(entrenamiento.fecha);
          if (entrenamiento.profesores.length >= 2) {
            profesor1 = profesoresDisponibles.firstWhere((p) => p.id == entrenamiento.profesores[0].id);
            profesor2 = profesoresDisponibles.firstWhere((p) => p.id == entrenamiento.profesores[1].id);
          }
        }
      });
    } catch (e) {
      // Ya no mostramos el SnackBar en caso de error
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (fecha != null) {
      final TimeOfDay? hora = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(fechaSeleccionada ?? DateTime.now()),
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
    if (!_formKey.currentState!.validate()) {
      return; // Ya no mostramos el SnackBar de fallo
    }

    if (profesor1 == null || profesor2 == null || fechaSeleccionada == null) {
      return; // Ya no mostramos el SnackBar de fallo
    }

    final nuevoEntrenamiento = Entrenamiento(
      id: widget.entrenamiento?.id,
      oposicion: oposicionSeleccionada!,
      profesores: [profesor1!, profesor2!],
      alumnos: widget.entrenamiento?.alumnos ?? [],
      fecha: fechaSeleccionada!.toIso8601String(),  // Guardar la fecha en formato ISO 8601
      lugar: lugarSeleccionado!,
    );

    try {
      if (widget.entrenamiento == null) {
        // Si es una creación
        await _entrenamientoService.createTraining(nuevoEntrenamiento);
      } else {
        // Si es una actualización
        await _entrenamientoService.updateTraining(nuevoEntrenamiento.id!, nuevoEntrenamiento);
      }
    } catch (e) {

    }

    Navigator.pushNamed(context, AppRoutes.clasesAdmin);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.entrenamiento != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Clase' : 'Crear Clase'),
        backgroundColor: const Color(0xFFFFC107),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: oposicionSeleccionada,
                decoration: const InputDecoration(labelText: 'Oposición'),
                items: oposiciones.map((op) => DropdownMenuItem(value: op, child: Text(op))).toList(),
                onChanged: (value) => setState(() => oposicionSeleccionada = value),
                validator: (value) => value == null ? 'Selecciona una oposición' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: lugarSeleccionado,
                decoration: const InputDecoration(labelText: 'Lugar'),
                items: lugares.map((lugar) => DropdownMenuItem(value: lugar, child: Text(lugar))).toList(),
                onChanged: (value) => setState(() => lugarSeleccionado = value),
                validator: (value) => value == null ? 'Selecciona un lugar' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<User>(
                value: profesor1,
                decoration: const InputDecoration(labelText: 'Profesor 1'),
                items: profesoresDisponibles.map((profesor) {
                  return DropdownMenuItem(value: profesor, child: Text(profesor.nombreUsuario));
                }).toList(),
                onChanged: (value) => setState(() => profesor1 = value),
                validator: (value) => value == null ? 'Selecciona un profesor' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<User>(
                value: profesor2,
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
                label: Text(esEdicion ? 'Actualizar clase' : 'Guardar clase'),
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
