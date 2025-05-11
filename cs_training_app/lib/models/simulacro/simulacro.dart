import 'ejercicio_marca.dart';

class Simulacro {
  final int? id;
  final String titulo;
  final String fecha;
  final List<EjercicioMarca> ejercicios;

  Simulacro({
    this.id,
    required this.titulo,
    required this.fecha,
    required this.ejercicios,
  });

  factory Simulacro.fromJson(Map<String, dynamic> json) {
    return Simulacro(
      id: json['id'],
      titulo: json['titulo'],
      fecha: json['fecha'],
      ejercicios: (json['ejercicios'] as List<dynamic>?)
          ?.map((e) => EjercicioMarca.fromJson(e))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'titulo': titulo,
      'fecha': fecha,
      'ejercicios': ejercicios.map((e) => e.toJson()).toList(),
    };
  }
}
