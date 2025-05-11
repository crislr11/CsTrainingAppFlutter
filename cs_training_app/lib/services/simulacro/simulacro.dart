import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/simulacro/simulacro.dart';


class SimulacroService {
  final String baseUrl = 'http://localhost:8080/api/simulacro';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Obtener simulacros por usuario
  Future<List<Simulacro>> getSimulacrosPorUsuario(int userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/usuario/$userId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List jsonList = jsonDecode(response.body);
      return jsonList.map((e) => Simulacro.fromJson(e)).toList();
    } else {
      print('Error al obtener simulacros del usuario');
      return [];
    }
  }

  Future<Simulacro?> saveSimulacro(Simulacro simulacro) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode(simulacro.toJson());

      debugPrint('Enviando a ${baseUrl} con body: $body'); // Log para diagnóstico

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: body,
      );

      debugPrint('Respuesta del servidor: ${response.statusCode} - ${response.body}'); // Log respuesta

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          return Simulacro.fromJson(responseData);
        } catch (e) {
          debugPrint('Error al parsear respuesta: $e');
          throw Exception('Error procesando la respuesta del servidor');
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error en saveSimulacro: $e');
      rethrow; // Re-lanzamos la excepción para manejarla en el UI
    }
  }

  //Eliminar simulacro
  Future<bool> deleteSimulacro(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    return response.statusCode == 204;
  }

  //Asignar simulacro a usuario
  Future<Simulacro?> asignarSimulacroAUsuario(int simulacroId, int userId) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/a%C3%B1adir/$simulacroId/usuario/$userId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Simulacro.fromJson(jsonDecode(response.body));
    } else {
      print('Error al asignar simulacro al usuario');
      return null;
    }
  }


  Future<Simulacro?> agregarEjercicioASimulacro({
    required int simulacroId,
    required int ejercicioId,
    required double marca,
    required String nombre,  // Añadimos el parámetro nombre
  }) async {
    final headers = await _getHeaders();

    // Crear el objeto EjercicioMarca en formato JSON
    final ejercicioMarca = {
      'id': 0,
      'marca': marca,
      'simulacroId': simulacroId,
      'ejercicioId': ejercicioId,
      'nombre': nombre,
    };


    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$simulacroId/agregar-ejercicio'),
        headers: headers,
        body: jsonEncode(ejercicioMarca),
      );

      print(response.body);

      if (response.statusCode == 200) {
        return Simulacro.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        print('Simulacro o ejercicio no encontrado');
        return null;
      } else if (response.statusCode == 400) {
        print('Datos inválidos: ${response.body}');
        return null;
      } else {
        print('Error desconocido: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Excepción al agregar ejercicio: $e');
      return null;
    }
  }



}
