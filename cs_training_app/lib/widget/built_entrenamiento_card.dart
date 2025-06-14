import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    final plazasDisponibles = 25 - entrenamiento.alumnos.length;
    final fechaFormateada = _formatearFecha(entrenamiento.fecha);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: inscrito
                ? [const Color(0xFFFFC107), const Color(0xFFFFE082)]
                : [Colors.white, const Color(0xFFFAFAFA)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header compacto con oposición e indicador de inscripción
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatearOposicion(entrenamiento.oposicion),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (inscrito)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Inscrito',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Información principal compacta
              _buildCompactInfoRow(fechaFormateada, entrenamiento.lugar, plazasDisponibles),

              const SizedBox(height: 8),

              // Información de profesores compacta
              _buildCompactProfesoresSection(),

              const SizedBox(height: 10),

              // Botones de acción compactos
              _buildCompactActionButtons(context, plazasDisponibles),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow(String fecha, String lugar, int plazasDisponibles) {
    return Column(
      children: [
        // Primera fila: Fecha y lugar
        Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: Colors.blue),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                fecha,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.location_on, size: 14, color: Colors.red),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                lugar,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            // Plazas en la misma fila
            Icon(
                Icons.group,
                size: 14,
                color: plazasDisponibles > 10 ? Colors.green :
                plazasDisponibles > 5 ? Colors.orange : Colors.red
            ),
            const SizedBox(width: 4),
            Text(
              '$plazasDisponibles/25',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: plazasDisponibles > 10 ? Colors.green :
                plazasDisponibles > 5 ? Colors.orange : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactProfesoresSection() {
    if (entrenamiento.profesores.isEmpty) {
      return Row(
        children: [
          Icon(Icons.person_off, color: Colors.grey[600], size: 14),
          const SizedBox(width: 4),
          Text(
            'Sin profesor',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    final profesoresText = entrenamiento.profesores
        .map((profesor) => profesor.nombreUsuario)
        .join(', ');

    return Row(
      children: [
        Icon(Icons.school, color: const Color(0xFFFFC107), size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Prof: $profesoresText',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactActionButtons(BuildContext context, int plazasDisponibles) {
    if (inscrito) {
      return SizedBox(
        width: double.infinity,
        height: 32,
        child: ElevatedButton(
          onPressed: onDesapuntarse,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Desapuntarse', style: TextStyle(fontSize: 12)),
        ),
      );
    }

    if (plazasDisponibles <= 0) {
      return SizedBox(
        width: double.infinity,
        height: 32,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Sin plazas', style: TextStyle(fontSize: 12)),
        ),
      );
    }

    if (onApuntarse != null) {
      return SizedBox(
        width: double.infinity,
        height: 32,
        child: ElevatedButton(
          onPressed: onApuntarse,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC107),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Apuntarse', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}