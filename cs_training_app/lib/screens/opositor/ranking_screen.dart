import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/usuario_ranking.dart';
import '../../services/ranking_service.dart';
import '../../services/simulacro/ejercicio_service.dart';

class RankingScreen extends StatefulWidget {
  final String oposicion;

  const RankingScreen({super.key, required this.oposicion});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final RankingService _rankingService = RankingService();
  final EjercicioService _ejercicioService = EjercicioService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int? _selectedEjercicioId;
  List<DateTime> _fechasConSimulacros = [];
  List<UsuarioRanking> _ranking = [];
  bool _loadingFechas = false;
  bool _loadingRanking = false;
  bool _loadingEjercicios = false;
  bool _mostrarCalendario = true;

  Map<int, String> _ejerciciosDisponibles = {};

  @override
  void initState() {
    super.initState();
    _cargarEjercicios();
    _cargarFechasConSimulacros();
  }

  Future<void> _cargarEjercicios() async {
    setState(() => _loadingEjercicios = true);
    try {
      final ejercicios = await _ejercicioService.getAllEjercicios();
      setState(() {
        _ejerciciosDisponibles = {
          for (var e in ejercicios) e.id: e.nombre,
        };
        if (_ejerciciosDisponibles.isNotEmpty && _selectedEjercicioId == null) {
          _selectedEjercicioId = _ejerciciosDisponibles.keys.first;
          _mostrarCalendario = true;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar ejercicios: $e')),
      );
    } finally {
      setState(() => _loadingEjercicios = false);
    }
  }

  Future<void> _cargarFechasConSimulacros() async {
    setState(() => _loadingFechas = true);
    try {
      final fechas = await _rankingService.obtenerFechasSimulacros(oposicion: widget.oposicion);
      setState(() {
        _fechasConSimulacros = fechas;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar fechas: $e')),
      );
    } finally {
      setState(() => _loadingFechas = false);
    }
  }

  Future<void> _cargarRanking() async {
    if (_selectedDay == null || _selectedEjercicioId == null) return;

    setState(() => _loadingRanking = true);
    try {
      final nombreEjercicio = _ejerciciosDisponibles[_selectedEjercicioId!] ?? '';
      final ranking = await _rankingService.obtenerRankingEjercicio(
        ejercicioId: _selectedEjercicioId!,
        fecha: _selectedDay!,
        oposicion: widget.oposicion,
        esTiempo: _esEjercicioDeTiempo(nombreEjercicio),
      );
      setState(() => _ranking = ranking);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar ranking: $e')),
      );
    } finally {
      setState(() => _loadingRanking = false);
    }
  }

  bool _esEjercicioDeTiempo(String nombreEjercicio) {
    final nombresTiempo = [
      '1000 resistencia',
      'circuito agilidad',
      '50 metros velocidad',
      '2000 resistencia',
    ];
    return nombresTiempo.any((e) => nombreEjercicio.toLowerCase().contains(e.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Ranking de Simulacros'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _loadingEjercicios
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Seleccionar ejercicio',
                labelStyle: const TextStyle(color: Colors.amber),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.amber),
                ),
              ),
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              value: _selectedEjercicioId,
              items: _ejerciciosDisponibles.entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(entry.value, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEjercicioId = value;
                  _mostrarCalendario = true;
                  _selectedDay = null;
                  _ranking.clear();
                });
              },
            ),
            const SizedBox(height: 20),
            if (_mostrarCalendario)
              Card(
                color: Colors.grey[900],
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: TableCalendar(
                  focusedDay: _focusedDay,
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!_fechasConSimulacros.any((fecha) => isSameDay(fecha, selectedDay))) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No hay simulacros en esta fecha')),
                      );
                      return;
                    }
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                      _mostrarCalendario = false;
                    });
                    _cargarRanking();
                  },
                  calendarStyle: CalendarStyle(
                    weekendTextStyle: const TextStyle(color: Colors.grey),
                    defaultTextStyle: const TextStyle(color: Colors.white),
                    selectedDecoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Colors.amber),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Colors.amber),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, _) {
                      final hasSimulacro = _fechasConSimulacros.any((fecha) => isSameDay(fecha, day));
                      return Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasSimulacro ? Colors.amber.withOpacity(0.3) : null,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: hasSimulacro ? Colors.white : Colors.grey,
                              fontWeight: hasSimulacro ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: _loadingRanking
                  ? const Center(child: CircularProgressIndicator())
                  : (_selectedEjercicioId == null || _selectedDay == null)
                  ? const Center(child: Text('Selecciona un ejercicio y una fecha', style: TextStyle(color: Colors.white)))
                  : _ranking.isEmpty
                  ? const Center(child: Text('No hay resultados para esta combinación', style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                itemCount: _ranking.length,
                itemBuilder: (context, index) {
                  final usuario = _ranking[index];
                  Color? backgroundColor;
                  Color textColor = Colors.black;

                  if (index == 0) {
                    backgroundColor = Colors.amber;
                  } else if (index == 1) {
                    backgroundColor = Colors.grey[400];
                  } else if (index == 2) {
                    backgroundColor = Colors.brown[300];
                  } else {
                    backgroundColor = Colors.grey[850];
                    textColor = Colors.white;
                  }

                  return Card(
                    color: backgroundColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        usuario.nombreUsuario,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        'Marca: ${usuario.marca}',
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
