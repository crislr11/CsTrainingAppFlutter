import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Aquí iría la lógica para iniciar sesión
            // Redirigir al usuario a la pantalla principal o a la dashboard
          },
          child: Text('Iniciar sesión'),
        ),
      ),
    );
  }
}
