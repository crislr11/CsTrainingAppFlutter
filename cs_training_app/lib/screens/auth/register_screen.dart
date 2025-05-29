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
    'SUBOFICIAL',
    'GUARDIA_CIVIL',
    'SERVICIO_VIGILANCIA_ADUANERA',
    'INGRESO_FUERZAS_ARMADAS',
    'NINGUNA',
  ];

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(""),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ),
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/cs22.jpg', // Cambia esta ruta a tu imagen
              fit: BoxFit.cover,
            ),
          ),
          // Contenedor con el formulario
          Center(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(16.0),
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7), // Fondo blanco semi-transparente
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título "REGISTRO" en el cuadro
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Center(
                        child: Text(
                          "REGISTRO",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Nombre de usuario
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Nombre de Usuario',
                              filled: true,
                              fillColor: Colors.grey[300],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu nombre de usuario';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 10),
                          // Correo electrónico
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Correo Electrónico',
                              filled: true,
                              fillColor: Colors.grey[300],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu correo electrónico';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 10),
                          // Contraseña
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              filled: true,
                              fillColor: Colors.grey[300],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu contraseña';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 10),

                          // Dropdown para el Rol
                          SizedBox(
                            width: double.infinity,
                            child: DropdownButtonFormField<String>(
                              value: _role,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[300],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                prefixIcon: Icon(Icons.person, color: Colors.black),
                              ),
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
                          ),
                          SizedBox(height: 10),

                          if (_role == 'OPOSITOR')
                            SizedBox(
                              width: double.infinity,
                              child: DropdownButtonFormField<String>(
                                value: _oposicion,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[300],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12), // menos padding
                                  prefixIcon: Icon(Icons.security, color: Colors.black, size: 18), // icono más pequeño
                                ),
                                onChanged: (newValue) {
                                  setState(() {
                                    _oposicion = newValue!;
                                  });
                                },
                                items: _oposiciones.map((oposicion) {
                                  return DropdownMenuItem<String>(
                                    value: oposicion,
                                    child: Text(
                                      oposicion.replaceAll('_', ' '),
                                      style: TextStyle(fontSize: 10), // texto un poco más pequeño
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                          SizedBox(height: 20),


                          // Botón de registro
                          ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black, // Botón oscuro
                              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Registrar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellow, // Texto blanco
                              ),
                            ),
                          ),
                          SizedBox(height: 10),

                          // Enlace a login
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: Text(
                              '¿Ya tienes una cuenta? Inicia sesión aquí',
                              style: TextStyle(
                                color: Colors.black, // Color amarillo
                              ),
                            ),
                          )

                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        await _authService.register(registerRequest);
        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}
