import 'ejercicio.dart';
import 'simulacro.dart';

class EjercicioMarca {
  final int id;
  final double marca;
  final Ejercicio? ejercicio;
  final Simulacro? simulacro;
  final String? nombre;

  EjercicioMarca({
    required this.id,
    required this.marca,
    this.ejercicio,
    this.simulacro,
    this.nombre,  // Constructor para nombre
  });

  factory EjercicioMarca.fromJson(Map<String, dynamic> json) {
    return EjercicioMarca(
      id: json['id'],
      marca: (json['marca'] as num).toDouble(),
      ejercicio: json['ejercicio'] != null
          ? Ejercicio.fromJson(json['ejercicio'])
          : null,
      simulacro: json['simulacro'] != null
          ? Simulacro.fromJson(json['simulacro'])
          : null,
      nombre: json['nombre'],
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'marca': marca,
      'ejercicio': ejercicio?.toJson(),
      'simulacro': simulacro?.toJson(),
      'nombre': nombre,
    };
  }
}
