import 'package:flutter/material.dart';
import 'package:cs_training_app/models/login_request.dart';
import 'package:cs_training_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

      if (response != null && response['token'] != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);
        await prefs.setString('nombre', response['nombre'] ?? "Desconocido");
        await prefs.setString('oposicion', response['oposicion'] ?? "No definida");
        await prefs.setString('role', response['role'] ?? "Usuario");

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showErrorDialog("No se pudo iniciar sesión. Verifica tus credenciales.");
      }
    } catch (e) {
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
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
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
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "Contraseña"),
                obscureText: true,
                validator: (value) => value!.isEmpty ? "Ingrese su contraseña" : null,
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _login,
                child: Text("Iniciar Sesión"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
