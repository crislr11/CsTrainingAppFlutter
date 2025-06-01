import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/entrenamiento.dart';


const String baseUrl = "http://35.180.5.103:8080";

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

class EntrenamientoService {
  // Obtener todos los entrenamientos
  Future<List<Entrenamiento>> getAllTrainings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/entrenamientos'), headers: await _getHeaders());

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((entrenamiento) => Entrenamiento.fromJson(entrenamiento)).toList();
      } else {
        throw Exception('Error al obtener los entrenamientos: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Entrenamiento>> getFutureTrainingsByProfessor(int profesorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/entrenamientos/profesor/$profesorId/futuros'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((entrenamiento) => Entrenamiento.fromJson(entrenamiento)).toList();
      } else if (response.statusCode == 403) {
        throw Exception('Acceso denegado: No tienes permisos para realizar esta acción');
      } else {
        throw Exception('Error al obtener los entrenamientos futuros: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Entrenamiento>> getFuturosEntrenamientosPorOposicion(String oposicion) async {
    final url = Uri.parse('$baseUrl/api/entrenamientos/futurosEntrenos/$oposicion');
    final headers = await _getHeaders();
    debugPrint('URL: $url');

    try {
      final response = await http.get(url, headers: headers);
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = response.body;
        // Si el body empieza con [ asumimos que es un JSON válido tipo lista
        if (body.trim().startsWith('[')) {
          final data = jsonDecode(body);
          if (data is List) {
            return data.map<Entrenamiento>((e) => Entrenamiento.fromJson(e)).toList();
          } else {
            throw Exception('Formato inesperado en la respuesta');
          }
        } else {
          debugPrint('Mensaje del servidor (no JSON): $body');
          return []; // o lanza una excepción si prefieres
        }
      } else {
        throw Exception('Error en la respuesta del servidor: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en getFuturosEntrenamientosPorOposicion: $e');
      throw Exception('Error al obtener entrenamientos futuros por oposición: ${e.toString()}');
    }
  }



  // Obtener entrenamientos por oposición
  Future<List<Entrenamiento>> getTrainingsByOpposition(String oposicion) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/entrenamientos/oposicion/$oposicion'), headers: await _getHeaders(),);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((entrenamiento) => Entrenamiento.fromJson(entrenamiento)).toList();
      } else {
        throw Exception('Error al obtener los entrenamientos por oposición: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
  // Obtener entrenamientos futuros por oposición
  Future<List<Entrenamiento>> getFutureTrainingsByOpposition(String oposicion) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/entrenamientos/futurosEntrenos/$oposicion'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((entrenamiento) => Entrenamiento.fromJson(entrenamiento)).toList();
      } else if (response.statusCode == 403) {
        throw Exception('Acceso denegado: No tienes permisos para realizar esta acción');
      } else {
        throw Exception('Error al obtener entrenamientos futuros por oposición: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Obtener entrenamiento por ID
  Future<Entrenamiento> getTrainingById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/entrenamientos/$id'),headers: await _getHeaders(),);

      if (response.statusCode == 200) {
        return Entrenamiento.fromJson(json.decode(response.body));
      } else {
        throw Exception('Entrenamiento no encontrado: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Crear entrenamiento
  Future<Entrenamiento> createTraining(Entrenamiento entrenamiento) async {
    print('Nuevo Entrenamiento: ${entrenamiento.toJson()}');
    try {
      print(entrenamiento.toString());
      final response = await http.post(
        Uri.parse('$baseUrl/api/entrenamientos'),
          headers: await _getHeaders(),
        body: json.encode(entrenamiento.toJson()),
      );
      if (response.statusCode == 201) {
        return Entrenamiento.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al crear el entrenamiento: ${response.statusCode}');
      }

    } catch (e) {
      rethrow;
    }
  }

  // Actualizar entrenamiento
  Future<Entrenamiento> updateTraining(int id, Entrenamiento entrenamiento) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/entrenamientos/$id'),
        headers: await _getHeaders(),
        body: json.encode(entrenamiento.toJson()),
      );
      if (response.statusCode == 200) {
        return Entrenamiento.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al actualizar el entrenamiento: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Eliminar entrenamiento
  Future<void> deleteTraining(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/api/entrenamientos/$id'),headers: await _getHeaders(),);

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar el entrenamiento: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Obtener entrenamientos filtrados por rango de fechas
  Future<List<Entrenamiento>> getTrainingsByDateRange(DateTime inicio, DateTime fin) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/entrenamientos/filtrar-por-fechas?inicio=${inicio.toIso8601String()}&fin=${fin.toIso8601String()}',
        ),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((entrenamiento) => Entrenamiento.fromJson(entrenamiento)).toList();
      } else {
        throw Exception('Error al obtener entrenamientos por rango de fechas: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

}
