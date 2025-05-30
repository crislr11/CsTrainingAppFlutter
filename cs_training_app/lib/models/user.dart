import 'package:cs_training_app/models/simulacro/simulacro.dart';
import 'auth_response.dart';

class User {
  final int id;
  final String nombre;
  final String nombreUsuario;
  final String email;
  final String oposicion;
  final String role;
  final bool active;
  final int creditos;
  bool pagado;
  final List<Simulacro> simulacros;

  User({
    required this.id,
    required this.nombre,
    required this.nombreUsuario,
    required this.email,
    required this.oposicion,
    required this.role,
    required this.active,
    required this.creditos,
    required this.pagado,
    required this.simulacros,
  });

  factory User.fromAuthResponse(AuthResponse authResponse) {
    return User(
      id: authResponse.id,
      nombre: authResponse.nombre,
      nombreUsuario: authResponse.nombreUsuario,
      email: authResponse.email,       // <-- Aquí asignamos email
      oposicion: authResponse.oposicion,
      role: authResponse.role,
      active: true, // Asumo que siempre es true, pero puedes ajustarlo
      creditos: authResponse.creditos,
      pagado: authResponse.pagado ?? false, // Si `pagado` es null, se asigna false
      simulacros: authResponse.simulacros,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? "Desconocido",
      nombreUsuario: json['nombreUsuario'] ?? "Desconocido",
      email: json['email'] ?? "Sin email",       // <-- Aquí agregamos email desde JSON
      oposicion: json['oposicion'] ?? "NINGUNA",
      role: json['role'] ?? "Usuario",
      active: json['active'] ?? false, // Se asigna false si es null
      creditos: json['creditos'] ?? 0,
      pagado: json['pagado'] ?? false, // Si `pagado` es null, se asigna false
      simulacros: (json['simulacros'] as List<dynamic>?)
          ?.map((e) => Simulacro.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'nombreUsuario': nombreUsuario,
      'email': email,                   // <-- Incluido en JSON de salida
      'oposicion': oposicion,
      'role': role,
      'active': active,
      'creditos': creditos,
      'pagado': pagado,
      'simulacros': simulacros.map((s) => s.toJson()).toList(),
    };
  }

  Map<String, dynamic> toMinimalJson() {
    return {
      'id': id,
    };
  }
}
