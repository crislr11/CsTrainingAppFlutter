import 'auth_response.dart';

class User {
  final int id;
  final String nombre;
  final String nombreUsuario;
  final String oposicion;
  final String role;
  final bool active;

  User({
    required this.id,
    required this.nombre,
    required this.nombreUsuario,
    required this.oposicion,
    required this.role,
    required this.active,
  });

  factory User.fromAuthResponse(AuthResponse authResponse) {
    return User(
      id: authResponse.id,
      nombre: authResponse.nombre ?? "Desconocido",  // Aseguramos que nunca sea nulo
      nombreUsuario: authResponse.nombreUsuario ?? "Desconocido",  // Aseguramos que nunca sea nulo
      oposicion: authResponse.oposicion ?? "NINGUNA",  // Si es nulo, asignamos "NINGUNA"
      role: authResponse.role ?? "Usuario",  // Si es nulo, asignamos "Usuario"
      active: true, // Definimos el valor por defecto como `true`
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,  // Si es nulo, asignamos 0
      nombre: json['nombre'] ?? "Desconocido",  // Aseguramos que nunca sea nulo
      nombreUsuario: json['nombreUsuario'] ?? "Desconocido",  // Aseguramos que nunca sea nulo
      oposicion: json['oposicion'] ?? "NINGUNA",  // Si es nulo, asignamos "NINGUNA"
      role: json['role'] ?? "Usuario",  // Si es nulo, asignamos "Usuario"
      active: json['active'] ?? false,  // Si es nulo, asignamos `false`
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'nombreUsuario': nombreUsuario,
      'oposicion': oposicion,
      'role': role,
      'active': active,
    };
  }
}
