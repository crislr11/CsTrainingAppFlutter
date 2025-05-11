import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/simulacro/ejercicio_marca.dart';



class EjercicioMarcaService {
  final String baseUrl = 'http://localhost:8080/api/ejercicio-marca';

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

  //Obtener todas las marcas de un ejercicio (solo PROFESOR)
  Future<List<EjercicioMarca>> getMarcasPorEjercicio(int ejercicioId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/marcas/$ejercicioId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List jsonList = jsonDecode(response.body);
      return jsonList.map((json) => EjercicioMarca.fromJson(json)).toList();
    } else {
      print('Error al obtener marcas del ejercicio');
      return [];
    }
  }

  // Obtener el top 5 de marcas por ejercicio (solo OPOSITOR)
  Future<List<EjercicioMarca>> getTop5PorEjercicio(int ejercicioId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/ranking/$ejercicioId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List jsonList = jsonDecode(response.body);
      return jsonList.map((json) => EjercicioMarca.fromJson(json)).toList();
    } else {
      print('Error al obtener top 5 del ejercicio');
      return [];
    }
  }

  //Obtener las marcas por simulacro (solo PROFESOR)
  Future<List<EjercicioMarca>> getMarcasPorSimulacro(int simulacroId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/simulacro/$simulacroId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List jsonList = jsonDecode(response.body);
      return jsonList.map((json) => EjercicioMarca.fromJson(json)).toList();
    } else {
      print('Error al obtener marcas por simulacro');
      return [];
    }
  }

  //Guardar una marca nueva (solo PROFESOR)
  Future<EjercicioMarca?> saveMarca(EjercicioMarca marca) async {
    final headers = await _getHeaders();
    final body = jsonEncode(marca.toJson());

    final response = await http.post(
      Uri.parse('$baseUrl/marca'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      return EjercicioMarca.fromJson(jsonDecode(response.body));
    } else {
      print('Error al guardar la marca');
      return null;
    }
  }

  // Eliminar una marca por ID (solo PROFESOR)
  Future<bool> deleteMarca(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/marca/$id'),
      headers: headers,
    );

    return response.statusCode == 204;
  }
}
