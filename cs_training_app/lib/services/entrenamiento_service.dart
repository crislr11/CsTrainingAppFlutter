import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/entrenamiento.dart';

// Definir la URL base en un archivo de constantes
const String baseUrl = "http://localhost:8080";

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

  // Obtener entrenamientos de un profesor
  Future<List<Entrenamiento>> getTrainingsByProfessor(int profesorId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/entrenamientos/profesor/$profesorId'), headers: await _getHeaders(),);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((entrenamiento) => Entrenamiento.fromJson(entrenamiento)).toList();
      } else {
        throw Exception('Error al obtener los entrenamientos del profesor: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
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
    try {
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
