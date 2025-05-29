import 'package:flutter/material.dart';
import 'package:cs_training_app/models/login_request.dart';
import 'package:cs_training_app/models/user.dart';
import 'package:cs_training_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/auth_response.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    final loginRequest = LoginRequest(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    try {
      final response = await AuthService().login(loginRequest);

      print("Respuesta de login: $response");  // Imprimir la respuesta completa de login

      if (response != null && response['token'] != null) {
        // Procesar la respuesta y crear el objeto User
        User user = User.fromAuthResponse(AuthResponse.fromJson(response));



        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);
        await prefs.setInt('id', response['id']);
        print('ID guardado: ${response['id']}');
        await prefs.setString('nombre', user.nombre);
        await prefs.setString('nombreUsuario', user.nombreUsuario);
        await prefs.setString('email', response['email'] ?? 'Sin email'); // Solo si viene en el response
        await prefs.setString('oposicion', user.oposicion);
        await prefs.setString('role', user.role);
        await prefs.setBool('active', user.active);
        await prefs.setInt('creditos', user.creditos);
        await prefs.setBool('pagado', user.pagado);


        if (user.role == "ADMIN") {
          Navigator.pushReplacementNamed(context, '/admin_home');
        } else if (user.role == "PROFESOR") {
          Navigator.pushReplacementNamed(context, '/profesor_home');
        } else if (user.role == "OPOSITOR") {
          Navigator.pushReplacementNamed(context,'/opositor_profile',);
        } else {
          _showErrorDialog("Rol de usuario desconocido: ${user.role}");
        }

      } else {
        _showErrorDialog("No se pudo iniciar sesión. Verifica tus credenciales.");
      }
    } catch (e) {
      print("Error: $e");  // Imprimir el error en caso de excepción
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }

  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Aceptar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/cs.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.80,
              height: MediaQuery.of(context).size.height * 0.55,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.60),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "INICIAR SESIÓN",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[300],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        prefixIcon: Icon(Icons.email, color: Colors.black),
                      ),
                      style: TextStyle(color: Colors.black),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Ingrese su email";
                        }
                        if (!RegExp(r"^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value)) {
                          return "Ingrese un email válido";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[300],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        prefixIcon: Icon(Icons.lock, color: Colors.black),
                      ),
                      style: TextStyle(color: Colors.black),
                      obscureText: true,
                      validator: (value) => value!.isEmpty ? "Ingrese su contraseña" : null,
                    ),
                    SizedBox(height: 20),
                    _isLoading
                        ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                    )
                        : ElevatedButton.icon(
                      onPressed: _login,
                      label: Text(
                        "Iniciar Sesión",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellow,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/register');
                      },
                      child: Text(
                        'Aun no tienes cuenta? Pulsa aqui',
                        style: TextStyle(
                          color: Colors.yellow,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
