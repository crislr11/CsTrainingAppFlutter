import 'auth_response.dart';

class User {
  final String nombre;
  final String oposicion;
  final String role;

  User({
    required this.nombre,
    required this.oposicion,
    required this.role,
  });

  // Método para crear un User desde un AuthResponse
  factory User.fromAuthResponse(AuthResponse authResponse) {
    return User(
      nombre: authResponse.nombre,
      oposicion: authResponse.oposicion,
      role: authResponse.role,
    );
  }

  // Método para crear un User desde un Map (para cuando recibimos un JSON de la API)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nombre: json['username'], // Ajustado para que coincida con el JSON recibido
      oposicion: json['oposicion'] ?? 'NINGUNA',
      role: json['role'],
    );
  }

  // Método toJson si es necesario para enviar el User a la API
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'oposicion': oposicion,
      'role': role,
    };
  }
}
