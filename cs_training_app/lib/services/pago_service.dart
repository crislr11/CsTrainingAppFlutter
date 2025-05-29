import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pago.dart';

class PagoService {
  final String _baseUrl = 'http://35.180.5.103:8080/api/pagos'; // Make sure this matches your server URL

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

  // Create payment for a user
  Future<String> crearPago(int userId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$_baseUrl/$userId');

      final response = await http.post(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      } else {
        throw Exception('Error al crear el pago: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al crear el pago: $e');
    }
  }

  // Get payment history for a user
  Future<List<Pago>> obtenerHistorialPagos(int userId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$_baseUrl/$userId/historial');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((json) => Pago.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      } else {
        throw Exception('Error al obtener historial: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener historial: $e');
    }
  }

  // Delete a payment
  Future<String> eliminarPago(int pagoId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$_baseUrl/$pagoId');

      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        return response.body;
      } else if (response.statusCode == 404) {
        throw Exception('Pago no encontrado');
      } else {
        throw Exception('Error al eliminar pago: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al eliminar pago: $e');
    }
  }

  // Reset payment status (monthly process)
  Future<String> restablecerPagos() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$_baseUrl/restablecer');

      final response = await http.put(url, headers: headers);

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Error al restablecer pagos: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al restablecer pagos: $e');
    }
  }
}