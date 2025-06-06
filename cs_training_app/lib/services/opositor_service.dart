import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/entrenamiento.dart';
import '../models/marca.dart';
import 'entrenamiento_service.dart';

class OpositorService {
  static const String _baseUrl = 'http://35.181.152.177:8080/api/opositor';

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

  // Apuntarse a un entrenamiento
  Future<String?> apuntarseAEntrenamiento(int entrenamientoId, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    int creditos = prefs.getInt('creditos') ?? 0;

    // Verificar si hay créditos antes de hacer la petición
    if (creditos <= 0) {
      return 'No tienes suficientes créditos';
    }

    final url = Uri.parse('$_baseUrl/inscripciones/apuntar');
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'entrenamientoId': entrenamientoId,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        // Restar crédito después de una inscripción exitosa
        await prefs.setInt('creditos', creditos - 1);
        return '¡Te has apuntado al entrenamiento correctamente!';
      }
    } catch (e) {

    }
    return null;
  }


// Desapuntarse de un entrenamiento
  Future<String?> desapuntarseDeEntrenamiento(int entrenamientoId, int userId) async {
    final url = Uri.parse('$_baseUrl/inscripciones/desapuntar');
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'entrenamientoId': entrenamientoId,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        int creditos = prefs.getInt('creditos') ?? 0;
        await prefs.setInt('creditos', creditos + 1);

        return '¡Te has desapuntado del entrenamiento correctamente!';
      }
    } catch (e) {
      // Silencioso: no hacer nada
    }

    // Retorna null si falla
    return null;
  }


  Future<List<Entrenamiento>> getEntrenamientosDelOpositor(int userId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$_baseUrl/entrenamientos/$userId');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final body = response.body;

        // Verifica si es un mensaje de texto plano
        if (body.trim().startsWith('[')) {
          final data = jsonDecode(body);
          if (data is List) {
            return data.map<Entrenamiento>((e) => Entrenamiento.fromJson(e)).toList();
          }
        } else {
          debugPrint('Mensaje del servidor: $body');
        }
      } else {
        debugPrint('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en getEntrenamientosDelOpositor: $e');
    }

    // Si hay cualquier error o no se puede procesar, retorna lista vacía
    return [];
  }

  // Añadir marca
  Future<String> addMarca(Marca marca) async {
    final url = Uri.parse(_baseUrl);
    final headers = await _getHeaders();

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(marca.toJson()),
      );

      if (response.statusCode == 200) {
        return 'Marca añadida correctamente.';
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al añadir marca');
      }
    } catch (e) {
      throw Exception('Error al añadir marca: ${e.toString()}');
    }
  }


  Future<String> removeMarca(Marca marca) async {
    final url = Uri.parse(_baseUrl);
    final headers = await _getHeaders();

    try {
      final response = await http.delete(
        url,
        headers: headers,
        body: jsonEncode(marca.toJson()),
      );

      if (response.statusCode == 200) {
        return 'Marca eliminada correctamente.';
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al eliminar marca');
      }
    } catch (e) {
      throw Exception('Error al eliminar marca: ${e.toString()}');
    }
  }

  // Obtener todas las marcas
  Future<List<dynamic>> getTodasLasMarcas(int userId) async {
    final url = Uri.parse('$_baseUrl/$userId/todas');
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al obtener marcas');
      }
    } catch (e) {
      throw Exception('Error al obtener todas las marcas: ${e.toString()}');
    }
  }

  // Obtener marcas por ejercicio
  Future<List<dynamic>> getMarcasPorEjercicio(
      int userId, int ejercicioId) async {
    final url = Uri.parse('$_baseUrl/$userId/ejercicio/$ejercicioId');
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al obtener marcas');
      }
    } catch (e) {
      throw Exception(
          'Error al obtener marcas por ejercicio: ${e.toString()}');
    }
  }

  // Subir foto de usuario
  Future<String> uploadUserPhoto(int userId, File foto) async {
    final url = Uri.parse('$_baseUrl/usuarios/$userId/foto');
    final token = await _getToken();

    try {
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(await http.MultipartFile.fromPath(
        'foto',
        foto.path,
      ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return 'Foto subida correctamente';
      } else {
        final errorData = jsonDecode(responseData);
        throw Exception(errorData['message'] ?? 'Error al subir foto');
      }
    } catch (e) {
      throw Exception('Error al subir foto de usuario: ${e.toString()}');
    }
  }

  // Obtener foto de usuario por ID
  Future<http.Response> getUserPhoto(int userId) async {
    final url = Uri.parse('$_baseUrl/usuarios/$userId/foto');
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);

      // Imprimir el estado y si la respuesta es válida
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Content-Type: ${response.headers['content-type']}');
      debugPrint('Body length: ${response.bodyBytes.length} bytes');

      return response;
    } catch (e) {
      debugPrint('Error al cargar la foto: ${e.toString()}');
      throw Exception('Error al cargar la foto: ${e.toString()}');
    }
  }


  Future<List<dynamic>> getFutureTrainingsByOpposition(String oposicion) async {
    final url = Uri.parse('$_baseUrl/futurosEntrenos/$oposicion');
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Error al obtener entrenamientos futuros');
      }
    } catch (e) {
      throw Exception('Error al obtener entrenamientos futuros: ${e.toString()}');
    }
  }

}