import 'package:cs_training_app/models/user.dart';

class Entrenamiento {
  final int? id;
  final String oposicion;
  final List<User> profesores;
  final List<User> alumnos;
  final String fecha;
  final String lugar;

  Entrenamiento({
    required this.id,
    required this.oposicion,
    required this.profesores,
    required this.alumnos,
    required this.fecha,
    required this.lugar,
  });

  // Convertir JSON a objeto Entrenamiento
  factory Entrenamiento.fromJson(Map<String, dynamic> json) {
    return Entrenamiento(
      id: json['id'],
      oposicion: json['oposicion'],
      profesores: List<User>.from(json['profesores'].map((x) => User.fromJson(x))),
      alumnos: List<User>.from(json['alumnos'].map((x) => User.fromJson(x))),
      fecha: json['fecha'],
      lugar: json['lugar'],
    );
  }


  // Convertir el objeto Entrenamiento a JSON para enviarlo a la API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'oposicion': oposicion,
      'profesores': profesores.map((x) => x.toJson()).toList(), // Convertir cada User a un Map
      'alumnos': alumnos.map((x) => x.toJson()).toList(), // Convertir cada User a un Map
      'fecha': fecha,
      'lugar': lugar,
    };
  }
}
