

import 'package:cs_training_app/models/simulacro/simulacro.dart';

class AuthResponse {
  final String token;
  final String nombre;
  final String nombreUsuario;
  final String oposicion;
  final String role;
  final int id;
  final int creditos;
  final bool pagado;
  final List<Simulacro> simulacros;

  AuthResponse({
    required this.token,
    required this.nombre,
    required this.nombreUsuario,
    required this.oposicion,
    required this.role,
    required this.id,
    required this.creditos,
    required this.pagado,
    required this.simulacros,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? "",
      nombre: json['nombre'] ?? "",
      nombreUsuario: json['nombreUsuario'] ?? "Desconocido",
      oposicion: json['oposicion'] ?? "No definida",
      role: json['role'] ?? "Usuario",
      id: json['id'] ?? 0,
      creditos: json['creditos'] ?? 0,
      pagado: json['pagado'],
      simulacros: (json['simulacros'] as List<dynamic>?)
          ?.map((e) => Simulacro.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'nombre': nombre,
      'nombreUsuario': nombreUsuario,
      'oposicion': oposicion,
      'role': role,
      'id': id,
      'creditos': creditos,
      'pagado': pagado,
      'simulacros': simulacros.map((s) => s.toJson()).toList(),
    };
  }
}
