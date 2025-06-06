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
  final String? fotoUrl; // Nuevo campo para la URL de la foto

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
    this.fotoUrl, // Añadido como parámetro opcional
  });

  factory User.fromAuthResponse(AuthResponse authResponse) {
    return User(
      id: authResponse.id,
      nombre: authResponse.nombre,
      nombreUsuario: authResponse.nombreUsuario,
      email: authResponse.email,
      oposicion: authResponse.oposicion,
      role: authResponse.role,
      active: true,
      creditos: authResponse.creditos,
      pagado: authResponse.pagado ?? false,
      simulacros: authResponse.simulacros,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? "Desconocido",
      nombreUsuario: json['nombreUsuario'] ?? "Desconocido",
      email: json['email'] ?? "Sin email",
      oposicion: json['oposicion'] ?? "NINGUNA",
      role: json['role'] ?? "Usuario",
      active: json['active'] ?? false,
      creditos: json['creditos'] ?? 0,
      pagado: json['pagado'] ?? false,
      simulacros: (json['simulacros'] as List<dynamic>?)
          ?.map((e) => Simulacro.fromJson(e))
          .toList() ?? [],
      fotoUrl: json['fotoUrl'], // Añadido desde JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'nombreUsuario': nombreUsuario,
      'email': email,
      'oposicion': oposicion,
      'role': role,
      'active': active,
      'creditos': creditos,
      'pagado': pagado,
      'simulacros': simulacros.map((s) => s.toJson()).toList(),
      'fotoUrl': fotoUrl, // Incluido en JSON de salida
    };
  }

  Map<String, dynamic> toMinimalJson() {
    return {
      'id': id,
      'fotoUrl': fotoUrl, // Opcional: incluir foto en versión mínima
    };
  }

  Map<String, dynamic> toUpdateDtoJson() {
    return {
      'username': nombreUsuario,
      'email': email,
      'isActive': active,
      'oposicion': oposicion,
      'creditos': creditos,
      'pagado': pagado,
      'fotoUrl': fotoUrl, // Incluido en DTO de actualización
    };
  }

  // Método para actualizar solo la foto
  User copyWith({String? fotoUrl}) {
    return User(
      id: id,
      nombre: nombre,
      nombreUsuario: nombreUsuario,
      email: email,
      oposicion: oposicion,
      role: role,
      active: active,
      creditos: creditos,
      pagado: pagado,
      simulacros: simulacros,
      fotoUrl: fotoUrl ?? this.fotoUrl,
    );
  }
}