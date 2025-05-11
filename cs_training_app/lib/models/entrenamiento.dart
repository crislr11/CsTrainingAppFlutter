import 'package:cs_training_app/models/user.dart';

class Entrenamiento {
  final int? id;
  final String oposicion;
  final List<User> profesores;
  final List<User> alumnos;
  final DateTime fecha;
  final String lugar;

  Entrenamiento({
    this.id,
    required this.oposicion,
    required this.profesores,
    required this.alumnos,
    required this.fecha,
    required this.lugar,
  });

  factory Entrenamiento.fromJson(Map<String, dynamic> json) {
    return Entrenamiento(
      id: json['id'],
      oposicion: json['oposicion'],
      profesores: List<User>.from(json['profesores']?.map((x) => User.fromJson(x)) ?? []),
      alumnos: List<User>.from(json['alumnos']?.map((x) => User.fromJson(x)) ?? []),
      fecha: DateTime.parse(json['fecha']),
      lugar: json['lugar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'oposicion': oposicion,
      'profesores': profesores.map((x) => x.toJson()).toList(),
      'alumnos': alumnos.map((x) => x.toJson()).toList(),
      'fecha': fecha.toIso8601String(),
      'lugar': lugar,
    };
  }

  @override
  String toString() {
    return 'Entrenamiento{id: $id, oposicion: $oposicion, fecha: $fecha, lugar: $lugar}';
  }
}
