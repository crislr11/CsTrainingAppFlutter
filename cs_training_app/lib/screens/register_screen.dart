import 'package:flutter/material.dart';
import 'package:cs_training_app/models/register_request.dart';
import 'package:cs_training_app/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _role = 'PROFESOR';
  String _oposicion = 'NINGUNA';

  final List<String> _oposiciones = [
    'BOMBERO',
    'POLICIA_NACIONAL',
    'POLICIA_LOCAL',
    'SUBOFOCIAL',
    'GUARDIA_CIVIL',
    'SERVICIO_VIGILANCIA_ADUANERA',
    'INGRESO_FUERZAS_ARMADAS',
    'NINGUNA',
  ];

  final AuthService _authService = AuthService();  // Instanciamos el servicio directamente

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registro")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Nombre de Usuario'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu nombre de usuario';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Correo Electrónico'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu correo electrónico';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Contraseña'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu contraseña';
                  }
                  return null;
                },
              ),
              DropdownButton<String>(
                value: _role,
                onChanged: (newValue) {
                  setState(() {
                    _role = newValue!;
                    if (_role == 'PROFESOR') {
                      _oposicion = 'NINGUNA';
                    }
                  });
                },
                items: ['PROFESOR', 'OPOSITOR'].map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
              ),
              if (_role == 'OPOSITOR') ...[
                DropdownButton<String>(
                  value: _oposicion,
                  onChanged: (newValue) {
                    setState(() {
                      _oposicion = newValue!;
                    });
                  },
                  items: _oposiciones.map((oposicion) {
                    return DropdownMenuItem<String>(
                      value: oposicion,
                      child: Text(oposicion),
                    );
                  }).toList(),
                ),
              ],
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final registerRequest = RegisterRequest(
        username: _usernameController.text,
        password: _passwordController.text,
        email: _emailController.text,
        role: _role,
        oposicion: _oposicion,
      );

      try {
        await AuthService().register(registerRequest);
        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}



