import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/simulacro/ejercicio.dart';



class EjercicioService {
  final String baseUrl = 'http://35.180.5.103:8080/api/ejercicio';

  // Obtener token de SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Encabezados con el token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  //Obtener ejercicio por nombre
  Future<Ejercicio?> getEjercicioPorNombre(String nombre) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/nombre/$nombre'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Ejercicio.fromJson(jsonDecode(response.body));
    } else {
      print('Error al obtener ejercicio: ${response.statusCode}');
      return null;
    }
  }

  // Crear o actualizar ejercicio
  Future<Ejercicio?> saveEjercicio(Ejercicio ejercicio) async {
    final headers = await _getHeaders();
    final body = jsonEncode(ejercicio.toJson());

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      return Ejercicio.fromJson(jsonDecode(response.body));
    } else {
      print('Error al guardar ejercicio: ${response.statusCode}');
      return null;
    }
  }

  // Eliminar ejercicio por ID
  Future<bool> deleteEjercicio(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    return response.statusCode == 204;
  }

  Future<List<Ejercicio>> getAllEjercicios() async {
    final url = Uri.parse('$baseUrl');

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        // Si la respuesta es exitosa, decodifica la respuesta JSON
        var data = json.decode(response.body);

        // Convertir la respuesta en una lista de Ejercicio
        List<Ejercicio> ejercicios = (data as List)
            .map((ejercicioJson) => Ejercicio.fromJson(ejercicioJson))
            .toList();

        return ejercicios;
      } else {
        // Si la respuesta es un error
        print('Error: ${response.statusCode}');
        return []; // Retorna lista vacía en caso de error
      }
    } catch (e) {
      print('Error al hacer la solicitud: $e');
      return []; // Retorna lista vacía si hay un error en la solicitud
    }
  }

}
