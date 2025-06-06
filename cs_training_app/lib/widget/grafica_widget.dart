import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/marca.dart';
import '../services/Opositor_service.dart';

class Grafica extends StatefulWidget {
  final List<Marca> marcas;
  final String ejercicioNombre;
  final Function(Marca) onDeleteMarca;

  const Grafica({
    Key? key,
    required this.marcas,
    required this.ejercicioNombre,
    required this.onDeleteMarca,
  }) : super(key: key);

  @override
  State<Grafica> createState() => _GraficaState();
}

class _GraficaState extends State<Grafica> {
  final OpositorService _opositorService = OpositorService();
  late List<Marca> _marcas;

  @override
  void initState() {
    super.initState();
    _marcas = List.from(widget.marcas);
  }

  @override
  void didUpdateWidget(Grafica oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar las marcas cuando el widget padre cambie
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
      return '${minutos}min';
    }
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }

  Future<void> _eliminarMarca(BuildContext context, Marca marca) async {
    try {
      await _opositorService.removeMarca(marca);

      // Notificar al widget padre PRIMERO
      widget.onDeleteMarca(marca);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marca eliminada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar marca: ${e.toString()}')),
        );
      }
    }
  }

  void _mostrarDialogoEliminar(BuildContext context, Marca marca) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E1),
        title: const Text(
          'Eliminar marca',
          style: TextStyle(color: Color(0xFF1A1A1A)),
        ),
        content: Text(
          '¿Deseas eliminar la marca del ${DateFormat('dd/MM/yyyy').format(marca.fecha)}?',
          style: const TextStyle(color: Color(0xFF1A1A1A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFFFFC107))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await _eliminarMarca(context, marca);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marcas = _marcas;
    final esTiempo = _esEjercicioDeTiempo(widget.ejercicioNombre);

    if (marcas.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'No hay datos disponibles',
            style: TextStyle(color: Colors.grey[400]),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      height: 350,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: graficaWidth,
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
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < marcas.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('dd/MM').format(marcas[value.toInt()].fecha),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
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
                          reservedSize: 45,
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
                                  fontSize: 10,
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
                        color: Colors.grey.withOpacity(0.5),
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
                        curveSmoothness: 0.3,
                        color: const Color(0xFFFFC107),
                        barWidth: 3,
                        shadow: Shadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(2, 4),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFC107).withOpacity(0.4),
                              const Color(0xFFFFC107).withOpacity(0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: Colors.black,
                              strokeWidth: 2,
                              strokeColor: const Color(0xFFFFC107),
                            );
                          },
                        ),
                        showingIndicators: List<int>.generate(marcas.length, (i) => i),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.white.withOpacity(0.9),
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.all(8),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((touchedSpot) {
                            final idx = touchedSpot.spotIndex;
                            if (idx >= marcas.length) return null;

                            final fechaClave = DateFormat('yyyy-MM-dd').format(marcas[idx].fecha);
                            final marcasEnFecha = marcasPorFecha[fechaClave]!;

                            if (marcasEnFecha.length > 1) {
                              return LineTooltipItem(
                                'Fecha: ${DateFormat('dd/MM/yyyy').format(marcas[idx].fecha)}\n${marcasEnFecha.map((m) => _formatearValor(m.valor, esTiempo)).join('\n')}',
                                const TextStyle(color: Colors.black, fontSize: 12),
                              );
                            } else {
                              return LineTooltipItem(
                                'Fecha: ${DateFormat('dd/MM/yyyy').format(marcas[idx].fecha)}\nMarca: ${_formatearValor(marcas[idx].valor, esTiempo)}',
                                const TextStyle(color: Colors.black, fontSize: 12),
                              );
                            }
                          }).where((item) => item != null).cast<LineTooltipItem>().toList();
                        },
                      ),
                      touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                        if (event is FlTapUpEvent && touchResponse != null && touchResponse.lineBarSpots != null) {
                          final spotIndex = touchResponse.lineBarSpots!.first.spotIndex;
                          if (spotIndex < marcas.length) {
                            final marcaSeleccionada = marcas[spotIndex];
                            _mostrarDialogoEliminar(context, marcaSeleccionada);
                          }
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
    );
  }
}