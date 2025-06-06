import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario_ranking.dart';

class RankingService {
  final baseUrl = "http://35.181.152.177:8080";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<UsuarioRanking>> obtenerRankingEjercicio({
    required int ejercicioId,
    required DateTime fecha,
    required String oposicion,
    required bool esTiempo,
  }) async {
    final uri = Uri.parse('$baseUrl/api/ranking/ejercicio').replace(queryParameters: {
      'ejercicioId': ejercicioId.toString(),
      'fecha': fecha.toIso8601String().split('T').first,
      'oposicion': oposicion,
      'esTiempo': esTiempo.toString(),
    });

    final headers = await _getHeaders();

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => UsuarioRanking.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener ranking: ${response.statusCode}');
    }
  }

  Future<List<DateTime>> obtenerFechasSimulacros({required String oposicion}) async {
    final uri = Uri.parse('$baseUrl/api/ranking/fechas').replace(queryParameters: {
      'oposicion': oposicion,
    });

    final headers = await _getHeaders();

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map<DateTime>((dateStr) => DateTime.parse(dateStr)).toList();
    } else if (response.statusCode == 204) {
      return [];
    } else {
      throw Exception('Error al obtener fechas: ${response.statusCode}');
    }
  }
}
