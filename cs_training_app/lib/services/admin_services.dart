import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AdminService {
  final String _baseUrl = 'http://localhost:8080/api/admin/user'; // para emulador Android

  // Obtiene el token de autenticación desde SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Obtiene los encabezados para las peticiones HTTP con el token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Obtiene la lista completa de usuarios desde el servidor
  Future<List<User>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/listar'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> usersJson = jsonDecode(response.body);
      return usersJson.map((userJson) => User.fromJson(userJson)).toList();
    } else {
      throw Exception('Error al cargar los usuarios');
    }
  }

  // Obtiene un usuario por su ID
  Future<User> getUserById(int id) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl/buscar/$id');

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_handleError(response));
    }
  }

  // Elimina un usuario por su ID
  Future<void> deleteUser(int id) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl/eliminar/$id');

    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(_handleError(response));
    }
  }

  // Cambia el estado de un usuario (activo/inactivo)
  Future<void> toggleUserStatus(int id) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl/$id/cambiarEstado');

    final response = await http.patch(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(_handleError(response));
    }
  }

  // Actualiza los créditos de un usuario
  Future<void> updateUserCredits(int id, int newCredits) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl/$id/actualizarCreditos');

    final response = await http.patch(
      url,
      headers: headers,
      body: jsonEncode({'creditos': newCredits}),
    );

    if (response.statusCode != 200) {
      throw Exception(_handleError(response));
    }
  }

  // Actualiza los detalles de un usuario
  Future<User> updateUser(int id, Map<String, dynamic> userDetails) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$_baseUrl/update/$id');

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(userDetails),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_handleError(response));
    }
  }


  // Manejo de errores, obtiene el mensaje del servidor
  String _handleError(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      return json is String ? json : json['message'] ?? 'Error desconocido';
    } catch (_) {
      return 'Error: ${response.statusCode} ${response.reasonPhrase}';
    }
  }
}
