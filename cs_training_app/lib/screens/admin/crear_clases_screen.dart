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
      // Manejo de errores
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
      // Manejo de errores
    }

    Navigator.pushNamed(context, AppRoutes.clasesAdmin);
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.entrenamiento != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          esEdicion ? 'Editar Clase' : 'Crear Clase',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFC107), // Amarillo
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Oposición Dropdown
              _buildDropdownField<String>(
                label: 'Oposición',
                value: oposicionSeleccionada,
                items: oposiciones,
                onChanged: (value) => setState(() => oposicionSeleccionada = value),
                validator: (value) => value == null ? 'Selecciona una oposición' : null,
                displayText: (item) => item.replaceAll('_', ' '), // Formato sin guion bajo
              ),
              const SizedBox(height: 16),

              // Lugar Dropdown
              _buildDropdownField<String>(
                label: 'Lugar',
                value: lugarSeleccionado,
                items: lugares,
                onChanged: (value) => setState(() => lugarSeleccionado = value),
                validator: (value) => value == null ? 'Selecciona un lugar' : null,
                displayText: (lugar) {
                  return lugar.replaceAll('_', ' ');  // Reemplaza _ por espacio si es necesario
                },
              ),
              const SizedBox(height: 16),

              // Profesor 1 Dropdown
              _buildProfesorDropdownField(
                label: 'Profesor 1',
                value: profesor1,
                profesorExcluido: profesor2,
                onChanged: (value) => setState(() => profesor1 = value),
                validator: (value) => value == null ? 'Selecciona un profesor' : null,
              ),
              const SizedBox(height: 16),

              // Profesor 2 Dropdown
              _buildProfesorDropdownField(
                label: 'Profesor 2',
                value: profesor2,
                profesorExcluido: profesor1,
                onChanged: (value) => setState(() => profesor2 = value),
                validator: (value) => value == null ? 'Selecciona un profesor' : null,
              ),
              const SizedBox(height: 16),

              // Fecha Selección
              ListTile(
                title: Text(
                  fechaSeleccionada == null
                      ? 'Seleccionar fecha y hora'
                      : DateFormat('yyyy-MM-dd – kk:mm').format(fechaSeleccionada!),
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                ),
                trailing: const Icon(Icons.calendar_today, color: Color(0xFFFFC107)),
                onTap: _seleccionarFecha,
              ),
              const SizedBox(height: 24),

              // Botón Guardar
              Center(
                child: ElevatedButton.icon(
                  onPressed: _guardarClase,
                  icon: const Icon(Icons.save),
                  label: Text(
                    esEdicion ? 'Actualizar clase' : 'Guardar clase',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC107), // Amarillo
                    foregroundColor: Colors.black, // Negro
                    textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Función para crear el DropdownField con validación de campos vacíos
  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String? Function(T?) validator,
    required String Function(T) displayText,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8, // Reduce el tamaño
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 5,
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.black87),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
        items: items.map((T item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(displayText(item), style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87)),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildProfesorDropdownField({
    required String label,
    required User? value,
    required User? profesorExcluido,
    required ValueChanged<User?> onChanged,
    required String? Function(User?) validator,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8, // Reduce el tamaño
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 5,
          ),
        ],
      ),
      child: DropdownButtonFormField<User>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.black87),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black26, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFFFFC107), width: 2),
          ),
        ),
        items: profesoresDisponibles
            .where((profesor) => profesor != profesorExcluido)
            .map((profesor) {
          return DropdownMenuItem(value: profesor, child: Text(profesor.nombreUsuario));
        }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }
}
