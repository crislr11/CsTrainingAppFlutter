import 'package:flutter/material.dart';
import '../../models/entrenamiento.dart';

class EntrenamientoCard extends StatelessWidget {
  final Entrenamiento entrenamiento;
  final bool inscrito;
  final VoidCallback? onApuntarse;
  final VoidCallback? onDesapuntarse;

  const EntrenamientoCard({
    Key? key,
    required this.entrenamiento,
    required this.inscrito,
    this.onApuntarse,
    this.onDesapuntarse,
  }) : super(key: key);



  String _formatearOposicion(String oposicion) {
    return oposicion
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final fechaFormateada =
        '${entrenamiento.fecha.day}/${entrenamiento.fecha.month}/${entrenamiento.fecha.year} '
        '${entrenamiento.fecha.hour}:${entrenamiento.fecha.minute.toString().padLeft(2, '0')}';

    final plazasDisponibles = 25 - entrenamiento.alumnos.length;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          _formatearOposicion(entrenamiento.oposicion),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📅 $fechaFormateada', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('📍 Lugar: ${entrenamiento.lugar}'),
            Text('👥 Plazas disponibles: $plazasDisponibles/25'),
          ],
        ),
        trailing: inscrito
            ? IconButton(
          onPressed: onDesapuntarse,
          icon: const Icon(Icons.cancel, color: Colors.redAccent),
          tooltip: 'Desapuntarse',
        )
            : (onApuntarse != null
            ? ElevatedButton(
          onPressed: onApuntarse,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
          child: const Text('Apuntarse'),
        )
            : const SizedBox.shrink()),
      ),
    );
  }
}
