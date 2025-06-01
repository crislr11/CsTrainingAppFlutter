import 'dart:io';
import 'package:cs_training_app/screens/opositor/ranking_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/Opositor_service.dart';
import '../../widget/built_entrenamiento_card.dart';
import 'entrenamientos_disponibles_screen.dart';
import 'mis_marcas_screen.dart';
import 'mis_pagos_screen.dart';
import 'mis_simulacros_screen.dart';

class OpositorPorfileScreen extends StatefulWidget {
  const OpositorPorfileScreen({super.key});

  @override
  State<OpositorPorfileScreen> createState() => _OpositorProfileScreenState();
}

class _OpositorProfileScreenState extends State<OpositorPorfileScreen> with WidgetsBindingObserver {
  String _nombreCompleto = '';
  String _nombreUsuario = '';
  String _email = '';
  String _oposicion = '';
  int _userId = 0;
  int _creditos = 0;
  File? _image;
  List<dynamic> _entrenamientos = [];
  bool _loadingEntrenamientos = false;

  final OpositorService _service = OpositorService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarDatosUsuario();
    _cargarEntrenamientos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _actualizarCreditos();
    }
  }

  Future<void> _actualizarCreditos() async {
    final prefs = await SharedPreferences.getInstance();
    final nuevosCreditos = prefs.getInt('creditos') ?? 0;
    if (nuevosCreditos != _creditos && mounted) {
      setState(() {
        _creditos = nuevosCreditos;
      });
    }
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreCompleto = prefs.getString('nombre') ?? 'Usuario';
      _nombreUsuario = prefs.getString('nombreUsuario') ?? '';
      _email = prefs.getString('email') ?? 'Sin email';
      _userId = prefs.getInt('id') ?? 0;
      _oposicion = prefs.getString('oposicion') ?? '';
      _creditos = prefs.getInt('creditos') ?? 0;
    });

    if (_userId != 0) {
      await _loadUserPhoto();
      await _cargarEntrenamientos();
    }
  }

  Future<void> _cargarEntrenamientos() async {
    if (_userId == 0) return;

    setState(() {
      _loadingEntrenamientos = true;
    });

    try {
      final entrenamientos = await _service.getEntrenamientosDelOpositor(_userId);
      setState(() {
        _entrenamientos = entrenamientos;
      });
    } catch (e) {
      if (!e.toString().contains('404')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar entrenamientos: ${e.toString()}')),
        );
      }
      setState(() {
        _entrenamientos = [];
      });
    } finally {
      setState(() {
        _loadingEntrenamientos = false;
      });
    }
  }

  Future<void> _desapuntarseDeEntrenamiento(int entrenamientoId) async {
    try {
      final result = await _service.desapuntarseDeEntrenamiento(entrenamientoId, _userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
      await _cargarEntrenamientos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al desapuntarse: ${e.toString()}')),
      );
    }
  }

  String _formatearOposicion(String oposicion) {
    return oposicion.replaceAll('_', ' ').toUpperCase();
  }

  Future<void> _loadUserPhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final photoPath = prefs.getString('user_photo_path');

      if (photoPath != null && File(photoPath).existsSync()) {
        setState(() {
          _image = File(photoPath);
        });
        return;
      }

      final response = await _service.getUserPhoto(_userId);

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/user_${_userId}_photo.jpg');
        await file.writeAsBytes(response.bodyBytes);
        await prefs.setString('user_photo_path', file.path);

        setState(() {
          _image = file;
        });
      }
    } catch (e) {
      print('Error al cargar la foto del usuario: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      setState(() {
        _image = imageFile;
      });

      if (_userId == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: ID de usuario inválido')),
        );
        return;
      }

      try {
        String result = await _service.uploadUserPhoto(_userId, _image!);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_photo_path', _image!.path);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir la foto: ${e.toString()}')),
        );
      }
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _buildMiniButton(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.black),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _refreshPage() {
    setState(() {
      _actualizarCreditos();
      _cargarDatosUsuario();
      _cargarEntrenamientos();
    });
  }


  @override
  Widget build(BuildContext context) {
      return GestureDetector(
          onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < 0) {
          // Deslizamiento de derecha a izquierda
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RankingScreen(oposicion: _oposicion),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Perfil de Usuario',
            style: GoogleFonts.rubik(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFFFFC107),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refrescar',
              onPressed: _refreshPage,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
        ),

        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(0, 5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFFFFC107),
                        backgroundImage: _image != null ? FileImage(_image!) : null,
                        child: _image == null ? const Icon(Icons.person, size: 80, color: Colors.white) : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _nombreCompleto,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_nombreUsuario',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2.0),
                                      child: Icon(Icons.email, color: Color(0xFFFFC107), size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _email,
                                        style: const TextStyle(color: Colors.white70, fontSize: 18),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2.0),
                                      child: Icon(Icons.school, color: Color(0xFFFFC107), size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _formatearOposicion(_oposicion),
                                        style: const TextStyle(color: Colors.white70, fontSize: 18),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2.0),
                                      child: Icon(Icons.monetization_on, color: Color(0xFFFFC107), size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Créditos: $_creditos',
                                        style: const TextStyle(color: Colors.white70, fontSize: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniButton(Icons.fitness_center, 'Clases', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EntrenamientosDisponiblesScreen(oposicion: _oposicion),
                        ),
                      ).then((_) => _actualizarCreditos());
                    }),
                    _buildMiniButton(Icons.assignment, 'Simulacros', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MisSimulacrosScreen(userId: _userId),
                        ),
                      );
                    }),
                    _buildMiniButton(Icons.attach_money, 'Pagos', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MisPagosScreen(userId: _userId,)),
                      );
                    }),
                    _buildMiniButton(Icons.playlist_add_check, 'Mis Marcas', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MisMarcasScreen(userId: _userId,)),
                      );
                    }),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _loadingEntrenamientos
                    ? const Center(child: CircularProgressIndicator())
                    : _entrenamientos.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No tienes entrenamientos asignados',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EntrenamientosDisponiblesScreen(oposicion: _oposicion),
                            ),
                          ).then((_) => _actualizarCreditos());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          'Ver entrenamientos disponibles',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                )
                :SizedBox(
                  height: 300,
                  child: ListView.separated(
                    itemCount: _entrenamientos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entrenamiento = _entrenamientos[index];
                      final inscrito = true;
                      return EntrenamientoCard(
                        entrenamiento: entrenamiento,
                        inscrito: true ,
                        onApuntarse: null,
                        onDesapuntarse: inscrito ? () => _desapuntarseDeEntrenamiento(entrenamiento.id!) : null,
                      );

                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      )
    );
  }
}