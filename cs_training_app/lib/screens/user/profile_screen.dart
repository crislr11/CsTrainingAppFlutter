import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _nombre = "Cargando...";
  String _oposicion = "Cargando...";
  List<Map<String, dynamic>> _ejerciciosSeleccionados = [];
  String? _ejercicioSeleccionado;

  final List<String> _ejerciciosDisponibles = [
    "Dominadas",
    "Flexiones",
    "Abdominales",
    "Carrera 1000m",
    "Salto vertical"
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombre = prefs.getString('nombre') ?? "Usuario";
      _oposicion = prefs.getString('oposicion') ?? "Sin oposición";
    });
  }

  void _agregarEjercicio() {
    if (_ejercicioSeleccionado != null &&
        !_ejerciciosSeleccionados.any((e) => e['nombre'] == _ejercicioSeleccionado)) {
      setState(() {
        _ejerciciosSeleccionados.add({'nombre': _ejercicioSeleccionado, 'puntuacion': ''});
      });
    }
  }

  void _actualizarPuntuacion(int index, String valor) {
    setState(() {
      _ejerciciosSeleccionados[index]['puntuacion'] = valor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.grey[850],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.yellow.shade600,
                  child: Icon(Icons.person, size: 40, color: Colors.black),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nombre,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow.shade600,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: Text(
                        _oposicion,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Enlace de "Editar perfil"
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          // Aquí se implementará la navegación o funcionalidad de edición
                        },
                        child: Text(
                          "Editar perfil",
                          style: TextStyle(
                            color: Colors.yellow.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.yellow.shade600, thickness: 1.5),
            Text(
              "Mis marcas y ejercicios",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.yellow.shade600,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _ejercicioSeleccionado,
              hint: const Text("Selecciona un ejercicio", style: TextStyle(color: Colors.white)),
              isExpanded: true,
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.yellow),
              items: _ejerciciosDisponibles.map((String ejercicio) {
                return DropdownMenuItem<String>(
                  value: ejercicio,
                  child: Text(ejercicio, style: const TextStyle(color: Colors.yellow)),
                );
              }).toList(),
              onChanged: (String? nuevoEjercicio) {
                setState(() {
                  _ejercicioSeleccionado = nuevoEjercicio;
                });
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _agregarEjercicio,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow.shade600,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Center(child: Text("Añadir Ejercicio")),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _ejerciciosSeleccionados.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.yellow.shade700,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _ejerciciosSeleccionados[index]['nombre'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                hintText: "Punt.",
                                hintStyle: const TextStyle(color: Colors.black54),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.black),
                                ),
                                filled: true,
                                fillColor: Colors.yellow.shade200,
                              ),
                              onChanged: (valor) => _actualizarPuntuacion(index, valor),
                            ),
                          ),
                        ],
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
