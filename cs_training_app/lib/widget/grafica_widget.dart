import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/marca.dart';
import '../services/Opositor_service.dart';

class Grafica extends StatefulWidget {
  final List<Marca> marcas;
  final String ejercicioNombre;
  final Function(Marca) onDeleteMarca;
  final VoidCallback? onRefreshEjercicio;

  const Grafica({
    Key? key,
    required this.marcas,
    required this.ejercicioNombre,
    required this.onDeleteMarca,
    this.onRefreshEjercicio,
  }) : super(key: key);

  @override
  State<Grafica> createState() => _GraficaState();
}

class _GraficaState extends State<Grafica> with TickerProviderStateMixin {
  final OpositorService _opositorService = OpositorService();
  late List<Marca> _marcas;
  bool _isDeleting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _marcas = List.from(widget.marcas);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Grafica oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.marcas != oldWidget.marcas) {
      setState(() {
        _marcas = List.from(widget.marcas);
      });
    }
  }

  bool _esEjercicioDeTiempo(String nombreEjercicio) {
    final nombresTiempo = [
      '1000 resistencia',
      'barra(suspension)',
      'circuito agilidad',
      '50 metros velocidad',
      '2000 resistencia',
    ];
    return nombresTiempo.any((e) => nombreEjercicio.toLowerCase().contains(e.toLowerCase()));
  }

  double _calcularIntervalo(double rango) {
    if (rango <= 5) return 1;
    if (rango <= 10) return 2;
    if (rango <= 20) return 5;
    if (rango <= 50) return 10;
    if (rango <= 100) return 20;
    return (rango / 5).roundToDouble();
  }

  String _formatearValor(double value, bool esTiempo) {
    if (esTiempo) {
      final minutos = value ~/ 1;
      final segundos = ((value % 1) * 60).round();
      return segundos > 0 ? '${minutos}:${segundos.toString().padLeft(2, '0')}' : '${minutos}min';
    }
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }

  Future<void> _eliminarMarca(BuildContext context, Marca marca) async {
    setState(() {
      _isDeleting = true;
    });

    try {
      // Actualización optimista
      widget.onDeleteMarca(marca);

      // Eliminar del servidor
      await _opositorService.removeMarca(marca);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Marca eliminada correctamente'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Refrescar datos del ejercicio
        widget.onRefreshEjercicio?.call();
      }
    } catch (e) {
      // Revertir cambio optimista en caso de error
      widget.onRefreshEjercicio?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error al eliminar marca: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () => _mostrarDialogoEliminar(context, marca),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _mostrarDialogoEliminar(BuildContext context, Marca marca) {
    final esTiempo = _esEjercicioDeTiempo(widget.ejercicioNombre);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Eliminar marca',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que deseas eliminar esta marca?',
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ejercicio: ${widget.ejercicioNombre}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Marca: ${_formatearValor(marca.valor, esTiempo)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(marca.fecha)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Esta acción no se puede deshacer.',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFF666666),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isDeleting
                ? null
                : () async {
              Navigator.of(context).pop();
              await _eliminarMarca(context, marca);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isDeleting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text(
              'Eliminar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _onSpotTapped(int spotIndex) {
    if (spotIndex < _marcas.length && !_isDeleting) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });

      final marcaSeleccionada = _marcas[spotIndex];
      _mostrarDialogoEliminar(context, marcaSeleccionada);
    }
  }

  @override
  Widget build(BuildContext context) {
    final marcas = _marcas;
    final esTiempo = _esEjercicioDeTiempo(widget.ejercicioNombre);

    if (marcas.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timeline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No hay datos disponibles',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Añade tu primera marca',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calcular valores extremos
    final valores = marcas.map((m) => m.valor).toList();
    double minValor = valores.reduce((a, b) => a < b ? a : b);
    double maxValor = valores.reduce((a, b) => a > b ? a : b);
    final rango = maxValor - minValor;

    // Ajustar los límites del eje Y con padding adicional
    double minY = (minValor * 0.9).clamp(0, double.infinity);
    double maxY = maxValor * 1.1;

    // Añadir padding mínimo si el rango es muy pequeño
    if (rango < 1) {
      minY = minValor - 0.5;
      maxY = maxValor + 0.5;
    }

    final intervaloY = _calcularIntervalo(maxY - minY);

    // Para ejercicios de tiempo, invertimos la visualización
    if (esTiempo) {
      final temp = minY;
      minY = maxValor * 1.1 - rango * 1.2;
      maxY = temp * 0.9 + rango * 1.2;
    }

    // Agrupar marcas por fecha para tooltip sin duplicados
    Map<String, List<Marca>> marcasPorFecha = {};
    for (var m in marcas) {
      final key = DateFormat('yyyy-MM-dd').format(m.fecha);
      marcasPorFecha.putIfAbsent(key, () => []).add(m);
    }

    final extraPaddingRight = 100.0;
    final graficaWidth = (marcas.length * 60 + extraPaddingRight).clamp(300, double.infinity).toDouble();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.black,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            height: 380,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Toca un punto para eliminar la marca',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: InteractiveViewer(
                    constrained: false,
                    scaleEnabled: true,
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: SizedBox(
                      width: graficaWidth,
                      height: 300,
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: (marcas.length - 1 + 1.5).toDouble(),
                          minY: minY,
                          maxY: maxY,
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 35,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < marcas.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        DateFormat('dd/MM').format(marcas[value.toInt()].fecha),
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                interval: intervaloY,
                                getTitlesWidget: (value, meta) {
                                  double displayValue = value;
                                  if (esTiempo) {
                                    displayValue = maxValor - value + minValor;
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Text(
                                      _formatearValor(displayValue, esTiempo),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: intervaloY,
                            verticalInterval: 1,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.2),
                                strokeWidth: 1,
                              );
                            },
                            getDrawingVerticalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.1),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: marcas.asMap().entries.map((entry) {
                                final index = entry.key.toDouble();
                                final marca = entry.value;
                                if (esTiempo) {
                                  return FlSpot(index, maxValor - marca.valor + minValor);
                                }
                                return FlSpot(index, marca.valor);
                              }).toList(),
                              isCurved: true,
                              curveSmoothness: 0.35,
                              color: const Color(0xFFFFC107),
                              barWidth: 4,
                              shadow: Shadow(
                                color: const Color(0xFFFFC107).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFFC107).withOpacity(0.4),
                                    const Color(0xFFFFC107).withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 8,
                                    color: Colors.black,
                                    strokeWidth: 3,
                                    strokeColor: const Color(0xFFFFC107),
                                  );
                                },
                              ),
                              showingIndicators: List<int>.generate(marcas.length, (i) => i),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBgColor: Colors.white.withOpacity(0.95),
                              tooltipRoundedRadius: 12,
                              tooltipPadding: const EdgeInsets.all(12),
                              tooltipBorder: BorderSide(
                                color: const Color(0xFFFFC107),
                                width: 2,
                              ),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((touchedSpot) {
                                  final idx = touchedSpot.spotIndex;
                                  if (idx >= marcas.length) return null;

                                  final fechaClave = DateFormat('yyyy-MM-dd').format(marcas[idx].fecha);
                                  final marcasEnFecha = marcasPorFecha[fechaClave]!;

                                  if (marcasEnFecha.length > 1) {
                                    return LineTooltipItem(
                                      '📅 ${DateFormat('dd/MM/yyyy').format(marcas[idx].fecha)}\n👆 Toca para eliminar\n${marcasEnFecha.map((m) => '📊 ${_formatearValor(m.valor, esTiempo)}').join('\n')}',
                                      const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  } else {
                                    return LineTooltipItem(
                                      '📅 ${DateFormat('dd/MM/yyyy').format(marcas[idx].fecha)}\n📊 ${_formatearValor(marcas[idx].valor, esTiempo)}\n👆 Toca para eliminar',
                                      const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  }
                                }).where((item) => item != null).cast<LineTooltipItem>().toList();
                              },
                            ),
                            touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                              if (event is FlTapUpEvent && touchResponse != null && touchResponse.lineBarSpots != null) {
                                final spotIndex = touchResponse.lineBarSpots!.first.spotIndex;
                                _onSpotTapped(spotIndex);
                              }
                            },
                            handleBuiltInTouches: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}