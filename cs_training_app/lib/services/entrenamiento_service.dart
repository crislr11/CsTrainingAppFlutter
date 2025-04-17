import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/entrenamiento.dart';

// Definir la URL base en un archivo de constantes
const String baseUrl = "http://localhost:8080"; // Cambia a tu URL base real

class EntrenamientoService {
  // Obtener todos los entrenamientos
  Future<List<Entrenamiento>> getAllTrainings() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/entrenamientos'));

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
      final response = await http.get(Uri.parse('$baseUrl/api/entrenamientos/profesor/$profesorId'));

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
      final response = await http.get(Uri.parse('$baseUrl/api/entrenamientos/oposicion/$oposicion'));

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
      final response = await http.get(Uri.parse('$baseUrl/api/entrenamientos/$id'));

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
        headers: {"Content-Type": "application/json"},
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
        headers: {"Content-Type": "application/json"},
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
      final response = await http.delete(Uri.parse('$baseUrl/api/entrenamientos/$id'));

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar el entrenamiento: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
