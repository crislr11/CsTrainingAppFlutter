import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user.dart';
import '../../services/admin_services.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  bool isLoading = true;
  List<User> allUsers = [];
  List<User> opositores = [];
  List<User> profesores = [];
  String filtroOposicion = 'todos';

  final List<String> oposiciones = [
    'todos',
    'BOMBERO',
    'POLICIA_NACIONAL',
    'POLICIA_LOCAL',
    'SUBOFICIAL',
    'GUARDIA_CIVIL',
    'SERVICIO_VIGILANCIA_ADUANERA'
  ];

  final amarillo = const Color(0xFFFFC107);
  final negro = Colors.black;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await AdminService().getAllUsers();
      setState(() {
        allUsers = users ?? [];
        opositores = _filtrarOpositores(filtroOposicion);
        profesores = allUsers.where((u) => u.role == 'PROFESOR').toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los usuarios: $e')),
      );
    }
  }

  List<User> _filtrarOpositores(String filtro) {
    return allUsers.where((user) {
      return user.role == 'OPOSITOR' &&
          (filtro == 'todos' || user.oposicion == filtro);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final totalOpositores = allUsers.where((u) => u.role == 'OPOSITOR').length;
    final totalProfesores = profesores.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Panel de Administración',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: amarillo,
        foregroundColor: negro,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),

            /// Tarjeta de Opositores
            GestureDetector(
              onDoubleTap: () {
                _mostrarLeyendaOpositores(totalOpositores);
              },
              child: Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.30,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Opositores',
                      style: GoogleFonts.rubik(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 140,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isDense: true,
                          isExpanded: true,
                          value: filtroOposicion,
                          dropdownColor: Colors.grey[900],
                          iconEnabledColor: amarillo,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          onChanged: (newValue) {
                            setState(() {
                              filtroOposicion = newValue!;
                              opositores = _filtrarOpositores(filtroOposicion);
                            });
                          },
                          items: oposiciones
                              .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value.replaceAll('_', ' '),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ))
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 20,
                              startDegreeOffset: -90,
                              sections: [
                                PieChartSectionData(
                                  color: amarillo,
                                  value: totalOpositores == 0
                                      ? 0
                                      : (opositores.length / totalOpositores * 100),
                                  title: '',
                                  radius: 16,
                                ),
                                PieChartSectionData(
                                  color: amarillo.withOpacity(0.1),
                                  value: totalOpositores == 0
                                      ? 100
                                      : 100 - (opositores.length / totalOpositores * 100),
                                  title: '',
                                  radius: 16,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${opositores.length}',
                            style: GoogleFonts.rubik(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// Tarjeta de Profesores
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.25,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Profesores',
                    style: GoogleFonts.rubik(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 20,
                            startDegreeOffset: -90,
                            sections: [
                              PieChartSectionData(
                                color: amarillo,
                                value: 100,
                                title: '',
                                radius: 16,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$totalProfesores',
                          style: GoogleFonts.rubik(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// Tarjeta con botones
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.20,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _crearBoton('Activar', Icons.power_settings_new),
                  _crearBoton('Pagos', Icons.payment),
                  _crearBoton('Clases', Icons.school),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _crearBoton(String texto, IconData icono) {
    return ElevatedButton(
      onPressed: () {
        if (texto == 'Activar') {
          Navigator.pushNamed(context, '/activar_usuarios');
        }
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(10),
        backgroundColor: amarillo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black,
        elevation: 5,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: negro, size: 26),
          const SizedBox(height: 8),
          Text(
            texto,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: negro,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarLeyendaOpositores(int totalOpositores) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.black,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Porcentaje de opositores por oposición',
                  style: GoogleFonts.rubik(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...oposiciones.sublist(1).map((oposicion) {
                  final count = opositores
                      .where((user) => user.oposicion == oposicion)
                      .length;
                  final porcentaje = totalOpositores == 0
                      ? 0
                      : (count / totalOpositores) * 100;
                  return Text(
                    '${oposicion.replaceAll('_', ' ')}: ${porcentaje.toStringAsFixed(2)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
