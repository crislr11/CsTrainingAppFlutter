import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/marca.dart';

class Grafica extends StatelessWidget {
  final List<Marca> marcas;
  final String ejercicioNombre;

  const Grafica({
    Key? key,
    required this.marcas,
    required this.ejercicioNombre,
  }) : super(key: key);

  bool _esEjercicioDeTiempo(String nombreEjercicio) {
    final nombresTiempo = [
      '1000 resistencia',
      'barra(suspension)',
      'circuito de agilidad',
      '50 metros velocidad',
      '2000 resistencia',
    ];
    return nombresTiempo.any(
            (e) => nombreEjercicio.toLowerCase().contains(e.toLowerCase()));
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
      return '${minutos}m ${segundos}s';
    }
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final esTiempo = _esEjercicioDeTiempo(ejercicioNombre);

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

    // Ajustar los límites del eje Y
    double minY = (minValor * 1).clamp(0, double.infinity);
    double maxY = maxValor * 1.5;
    final intervaloY = _calcularIntervalo(maxY - minY);

    // Para ejercicios de tiempo, invertimos la visualización
    if (esTiempo) {
      final temp = minY;
      minY = maxValor * 1.1 - rango * 1.2;
      maxY = temp * 0.9 + rango * 1.2;
    }

    // Agrupar marcas por fecha (formato yyyy-MM-dd) para tooltip sin duplicados
    Map<String, List<Marca>> marcasPorFecha = {};
    for (var m in marcas) {
      final key = DateFormat('yyyy-MM-dd').format(m.fecha);
      marcasPorFecha.putIfAbsent(key, () => []).add(m);
    }

    final extraPaddingRight = 100.0;
    final graficaWidth = (marcas.length * 60 + extraPaddingRight).clamp(300, double.infinity).toDouble();

    return Container(
      color: Colors.black,
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
                          reservedSize: 40,
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
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((touchedSpot) {
                            final idx = touchedSpot.spotIndex;
                            final fechaClave = DateFormat('yyyy-MM-dd').format(marcas[idx].fecha);
                            final marcasEnFecha = marcasPorFecha[fechaClave]!;

                            if (marcasEnFecha.length > 1) {
                              // Mostrar todas las marcas en el tooltip separadas por salto de línea
                              return LineTooltipItem(
                                marcasEnFecha
                                    .map((m) => _formatearValor(m.valor, esTiempo))
                                    .join('\n'),
                                const TextStyle(color: Colors.black),
                              );
                            } else {
                              return LineTooltipItem(
                                _formatearValor(marcas[idx].valor, esTiempo),
                                const TextStyle(color: Colors.black),
                              );
                            }
                          }).toList();
                        },
                      ),
                      // Elimina la función touchCallback para no abrir diálogo al tocar
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
