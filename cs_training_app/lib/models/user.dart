import 'auth_response.dart';

class User {
  final int id;
  final String nombre;
  final String nombreUsuario;
  final String oposicion;
  final String role;
  final bool active;
  final int creditos;
  final bool pagado;
  User({
    required this.id,
    required this.nombre,
    required this.nombreUsuario,
    required this.oposicion,
    required this.role,
    required this.active,
    required this.creditos,
    required this.pagado
  });

  factory User.fromAuthResponse(AuthResponse authResponse) {
    return User(
      id: authResponse.id,
      nombre: authResponse.nombre ?? "Desconocido",  // Aseguramos que nunca sea nulo
      nombreUsuario: authResponse.nombreUsuario ?? "Desconocido",  // Aseguramos que nunca sea nulo
      oposicion: authResponse.oposicion ?? "NINGUNA",  // Si es nulo, asignamos "NINGUNA"
      role: authResponse.role ?? "Usuario",  // Si es nulo, asignamos "Usuario"
      active: true, // Definimos el valor por defecto como `true`
      creditos: authResponse.creditos ?? 0,
      pagado: authResponse.pagado
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
      creditos: json['creditos'] ?? 0,
      pagado: json['pagado']
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
      'creditos':creditos
    };
  }
}
