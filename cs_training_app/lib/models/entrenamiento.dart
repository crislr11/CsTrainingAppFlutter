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
    final fechaStr = json['fecha'] as String?;
    final lugarStr = json['lugar'] as String?;

    if (fechaStr == null) {
      throw Exception('El campo fecha es obligatorio y viene null');
    }
    if (lugarStr == null) {
      throw Exception('El campo lugar es obligatorio y viene null');
    }

    return Entrenamiento(
      id: json['id'] as int?,
      oposicion: json['oposicion'] as String? ?? 'Sin oposicion',
      profesores: List<User>.from(json['profesores']?.map((x) => User.fromJson(x)) ?? []),
      alumnos: List<User>.from(json['alumnos']?.map((x) => User.fromJson(x)) ?? []),
      fecha: DateTime.parse(fechaStr),
      lugar: lugarStr,
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
