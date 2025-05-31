import 'package:flutter/material.dart';
import '../models/pago.dart';
class PagoCard extends StatelessWidget {
  final Pago pago;
  final VoidCallback? onDelete;
  final Color primaryColor;
  final Color backgroundColor;

  const PagoCard({
    super.key,
    required this.pago,
    this.onDelete,
    required this.primaryColor,
    required this.backgroundColor,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Monto con estilo circular
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '\$${pago.monto.toStringAsFixed(0)}',
              style: TextStyle(
                color: backgroundColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Fecha del pago
          Expanded(
            child: Text(
              _formatDate(pago.fechaPago),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: onDelete,
              tooltip: 'Eliminar pago',
            ),
        ],
      ),
    );
  }
}
