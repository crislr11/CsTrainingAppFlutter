import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cs_training_app/models/auth_response.dart';
import 'package:cs_training_app/models/register_request.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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



  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

}
