import 'package:flutter/material.dart';
import '../../routes/routes.dart';

class ClasesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: 10, // Simulamos clases para mostrar scroll
          itemBuilder: (context, index) => Card(
            elevation: 5,
            color: Colors.teal[50], // Color de fondo de la tarjeta
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                ),
              ),
              title: Text(
                'Clase ${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.teal[800],
                ),
              ),
              subtitle: Text(
                'Descripción breve de la clase',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.teal[600],
                ),
              ),
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.crearClase);
        },
        backgroundColor: Colors.amber,
        child: Icon(Icons.add),
        tooltip: 'Crear nueva clase',
      ),
    );
  }
}
