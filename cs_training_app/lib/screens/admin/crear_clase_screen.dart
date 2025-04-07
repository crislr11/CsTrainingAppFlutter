import 'package:flutter/material.dart';

import '../../routes/routes.dart';

class CrearClaseScreen extends StatefulWidget {
  @override
  _CrearClaseScreenState createState() => _CrearClaseScreenState();
}

class _CrearClaseScreenState extends State<CrearClaseScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedOposicion;
  String? _selectedProfesor1;
  String? _selectedProfesor2;
  String? _selectedLugar;
  DateTime? _selectedDate;

  final List<String> _oposiciones = [
    'BOMBERO',
    'POLICIA_NACIONAL',
    'POLICIA_LOCAL',
    'SUBOFICIAL',
    'GUARDIA_CIVIL',
    'SERVICIO_VIGILANCIA_ADUANERA',
    'INGRESO_FUERZAS_ARMADAS',
  ];

  final List<String> _profesores = ['Profesor A', 'Profesor B', 'Profesor C'];
  final List<String> _lugares = ['NAVE', 'PISTA'];

  Future<void> _pickDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  String _formatearOposicion(String oposicion) {
    return oposicion.replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crear Entrenamiento"),
        backgroundColor: Colors.grey[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedOposicion,
                decoration: InputDecoration(labelText: 'Oposición'),
                items: _oposiciones
                    .map((op) => DropdownMenuItem(
                  value: op,
                  child: Text(_formatearOposicion(op)),
                ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedOposicion = val),
                validator: (val) =>
                val == null ? 'Selecciona una oposición' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedProfesor1,
                decoration: InputDecoration(labelText: 'Profesor 1'),
                items: _profesores
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedProfesor1 = val),
                validator: (val) =>
                val == null ? 'Selecciona el profesor 1' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedProfesor2,
                decoration: InputDecoration(labelText: 'Profesor 2'),
                items: _profesores
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedProfesor2 = val),
                validator: (val) =>
                val == null ? 'Selecciona el profesor 2' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLugar,
                decoration: InputDecoration(labelText: 'Lugar'),
                items: _lugares
                    .map((lugar) => DropdownMenuItem(value: lugar, child: Text(lugar)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedLugar = val),
                validator: (val) => val == null ? 'Selecciona el lugar' : null,
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Selecciona una fecha'
                    : 'Fecha seleccionada: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
                trailing: Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && _selectedDate != null) {
                    // Aquí iría la lógica de creación del entrenamiento (en otra clase)

                    // Mostramos un SnackBar de éxito
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Entrenamiento creado correctamente'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Future.delayed(Duration(seconds: 2), () {
                      Navigator.pushNamed(context, AppRoutes.home);
                    });
                  } else if (_selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Por favor selecciona una fecha')),
                    );
                  }
                },
                child: Text("Crear Entrenamiento"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
