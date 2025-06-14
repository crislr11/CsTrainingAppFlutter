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

class _RankingScreenState extends State<RankingScreen> with TickerProviderStateMixin {
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

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _cargarEjercicios();
    _cargarFechasConSimulacros();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
      _mostrarSnackBar('Error al cargar ejercicios: $e', Colors.red);
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
      _mostrarSnackBar('Error al cargar fechas: $e', Colors.red);
    } finally {
      setState(() => _loadingFechas = false);
    }
  }

  Future<void> _cargarRanking() async {
    if (_selectedDay == null || _selectedEjercicioId == null) return;

    setState(() => _loadingRanking = true);
    _slideController.reset();

    try {
      final nombreEjercicio = _ejerciciosDisponibles[_selectedEjercicioId!] ?? '';
      final ranking = await _rankingService.obtenerRankingEjercicio(
        ejercicioId: _selectedEjercicioId!,
        fecha: _selectedDay!,
        oposicion: widget.oposicion,
        esTiempo: _esEjercicioDeTiempo(nombreEjercicio),
      );
      setState(() => _ranking = ranking);
      _slideController.forward();
    } catch (e) {
      _mostrarSnackBar('Error al cargar ranking: $e', Colors.red);
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

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.red ? Icons.error : Icons.info,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }


  Widget _buildEjercicioSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFC107).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: const Color(0xFFFFC107),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Seleccionar Ejercicio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _loadingEjercicios
              ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFC107)),
          )
              : DropdownButtonFormField<int>(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            dropdownColor: Colors.grey[800],
            style: const TextStyle(color: Colors.white),
            value: _selectedEjercicioId,
            hint: const Text(
              'Elige un ejercicio',
              style: TextStyle(color: Colors.grey),
            ),
            items: _ejerciciosDisponibles.entries.map((entry) {
              return DropdownMenuItem<int>(
                value: entry.key,
                child: Text(
                  entry.value,
                  style: const TextStyle(color: Colors.white),
                ),
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
        ],
      ),
    );
  }

  Widget _buildCalendario() {
    if (!_mostrarCalendario) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: TableCalendar(
          focusedDay: _focusedDay,
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            if (!_fechasConSimulacros.any((fecha) => isSameDay(fecha, selectedDay))) {
              _mostrarSnackBar('No hay simulacros en esta fecha', Colors.orange);
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
            outsideDaysVisible: false,
            weekendTextStyle: const TextStyle(color: Colors.grey),
            defaultTextStyle: const TextStyle(color: Colors.white),
            selectedDecoration: const BoxDecoration(
              color: Color(0xFFFFC107),
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: const Color(0xFFFFC107).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              color: Color(0xFFFFC107),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFFFFC107)),
            rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFFFFC107)),
            headerPadding: EdgeInsets.symmetric(vertical: 16),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, _) {
              final hasSimulacro = _fechasConSimulacros.any((fecha) => isSameDay(fecha, day));
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasSimulacro
                      ? LinearGradient(
                    colors: [
                      const Color(0xFFFFC107).withOpacity(0.3),
                      const Color(0xFFFFC107).withOpacity(0.1),
                    ],
                  )
                      : null,
                  border: hasSimulacro
                      ? Border.all(color: const Color(0xFFFFC107), width: 1)
                      : null,
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
    );
  }

  Widget _buildDateInfo() {
    if (_selectedDay == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFC107).withOpacity(0.2),
            const Color(0xFFFFC107).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFC107).withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: const Color(0xFFFFC107),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Simulacro seleccionado',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDay!),
                  style: const TextStyle(
                    color: Color(0xFFFFC107),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _mostrarCalendario = true;
                _selectedDay = null;
                _ranking.clear();
              });
            },
            icon: const Icon(Icons.edit_calendar, size: 16),
            label: const Text('Cambiar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(UsuarioRanking usuario, int index) {
    Color? backgroundColor;
    Color textColor = Colors.black;
    IconData? medalIcon;
    Color? medalColor;

    if (index == 0) {
      backgroundColor = const Color(0xFFFFD700); // Oro
      medalIcon = Icons.emoji_events;
      medalColor = Colors.amber[800];
    } else if (index == 1) {
      backgroundColor = const Color(0xFFC0C0C0); // Plata
      medalIcon = Icons.workspace_premium;
      medalColor = Colors.grey[700];
    } else if (index == 2) {
      backgroundColor = const Color(0xFFCD7F32); // Bronce
      medalIcon = Icons.military_tech;
      medalColor = Colors.brown[700];
    } else {
      backgroundColor = Colors.grey[850];
      textColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: index < 3 ? 8 : 2,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: index < 3
                  ? LinearGradient(
                colors: [
                  Colors.white,
                  Colors.grey[200]!,
                ],
              )
                  : null,
              color: index >= 3 ? Colors.white : null,
              shape: BoxShape.circle,
              boxShadow: index < 3
                  ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
                  : null,
            ),
            child: Center(
              child: index < 3 && medalIcon != null
                  ? Icon(
                medalIcon,
                color: medalColor,
                size: 24,
              )
                  : Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          title: Text(
            usuario.nombreUsuario,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 16,
            ),
          ),
          subtitle: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Marca: ${usuario.marca}',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          trailing: index < 3
              ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              index == 0 ? '🥇' : index == 1 ? '🥈' : '🥉',
              style: const TextStyle(fontSize: 20),
            ),
          )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Detectar deslizamiento de izquierda a derecha
        if (details.primaryVelocity! > 0 && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            'Ranking',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFFFC107),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildEjercicioSelector(),
                const SizedBox(height: 20),
                _buildCalendario(),
                if (_selectedDay != null) ...[
                  const SizedBox(height: 20),
                  _buildDateInfo(),
                ],
                const SizedBox(height: 20),
                if (_loadingRanking)
                  const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFC107)),
                  )
                else if (_selectedEjercicioId == null || _selectedDay == null)
                  Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Selecciona un ejercicio y una fecha',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'para ver el ranking del simulacro',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else if (_ranking.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay resultados',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'para esta combinación de ejercicio y fecha',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFFC107).withOpacity(0.2),
                                  const Color(0xFFFFC107).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.leaderboard,
                                  color: const Color(0xFFFFC107),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ranking (${_ranking.length} participantes)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(
                            _ranking.length,
                                (index) => _buildRankingItem(_ranking[index], index),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}