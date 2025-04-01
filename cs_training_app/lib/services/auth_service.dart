import 'dart:convert';
import 'package:cs_training_app/models/login_request.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cs_training_app/models/auth_response.dart';
import 'package:cs_training_app/models/register_request.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String _url = 'http://localhost:8080/api/auth/register';
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> register(RegisterRequest registerRequest) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(registerRequest.toJson()),
      );

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(json.decode(response.body));
        await _storage.write(key: 'auth_token', value: authResponse.token);
        print('Token guardado: ${authResponse.token}');
      } else if (response.statusCode == 400) {
        final errorResponse = json.decode(response.body);
        throw errorResponse['token'];
      } else {
        final errorResponse = json.decode(response.body);
        throw 'Error desconocido: ${errorResponse['token']}';
      }
    } catch (e) {
      print('Error: $e');
      throw e;
    }
  }


  final String _loginUrl = 'http://localhost:8080/api/auth/login';

  Future<Map<String, dynamic>?> login(LoginRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(_loginUrl),
        body: jsonEncode(request.toJson()),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('token')) {
          return data;
        } else {
          throw Exception("Respuesta inválida del servidor: falta el token.");
        }
      } else if (response.statusCode == 401) {
        throw Exception("Credenciales incorrectas. Verifica tu email y contraseña.");
      } else if (response.statusCode == 500) {
        throw Exception("Error interno del servidor. Inténtalo más tarde.");
      } else {
        throw Exception("Error desconocido (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      print("Error en login: $e");
      return null;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}



