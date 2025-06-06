import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = "http://35.181.152.177:8080/api/files";

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

class FileService {
  final Dio dio = Dio();

  // Sube un archivo para un usuario específico
  Future<Map<String, dynamic>> uploadFile(int userId, File file) async {
    final String url = '$baseUrl/upload/$userId';

    try {
      String fileName = file.path.split('/').last;
      print('Subiendo archivo: $fileName al usuario: $userId');

      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final headers = await _getHeaders();
      print('Headers usados para la petición: $headers');
      print('URL de la petición: $url');
      print('FormData: $formData');

      final response = await dio.post(
        url,
        data: formData,
        options: Options(headers: headers),
      );

      print('Código de respuesta: ${response.statusCode}');
      print('Respuesta cruda: ${response.data}');
      print('Tipo de respuesta: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        // Si la respuesta es texto plano, la convertimos a Map
        if (response.data is String) {
          print('Respuesta es texto plano');
          return {'message': response.data};
        }
        print('Respuesta es JSON');
        return Map<String, dynamic>.from(response.data);
      } else {
        print('Error en la respuesta: ${response.statusMessage}');
        throw Exception('Error al subir archivo: ${response.statusMessage}');
      }
    } catch (e) {
      print('Error en uploadFile: $e');
      throw Exception('Error en uploadFile: $e');
    }
  }

  // Descarga la foto del usuario por userId (nuevo endpoint)
  Future<Uint8List> downloadUserPhoto(int userId) async {
    final String url = '$baseUrl/user-photo/$userId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Error al descargar foto del usuario: ${response.statusCode} ${response.reasonPhrase}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Error de cliente HTTP: $e');
    } on Exception catch (e) {
      throw Exception('Error en downloadUserPhoto: $e');
    }
  }

  // Descarga un archivo por nombre y retorna bytes (opcional mantener si se usa)
  Future<Uint8List> downloadFile(String filename) async {
    final String url = '$baseUrl/download/$filename';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Error al descargar archivo: ${response.statusCode} ${response.reasonPhrase}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Error de cliente HTTP: $e');
    } on Exception catch (e) {
      throw Exception('Error en downloadFile: $e');
    }
  }

  // Elimina el archivo de un usuario
  Future<Map<String, dynamic>> deleteUserFile(int userId) async {
    final String url = '$baseUrl/delete/$userId';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        throw Exception('Error al eliminar archivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en deleteUserFile: $e');
    }
  }

  // Obtiene info del archivo del usuario
  Future<Map<String, dynamic>> getFileInfo(int userId) async {
    final String url = '$baseUrl/info/$userId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      } else {
        throw Exception('Error al obtener info del archivo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en getFileInfo: $e');
    }
  }
}
