import 'package:flutter/material.dart';
import 'package:cs_training_app/models/entrenamiento.dart';
import 'package:cs_training_app/services/entrenamiento_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cs_training_app/models/user.dart';
import '../../routes/routes.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../services/file_service.dart';

class ProfesorHomeScreen extends StatefulWidget {
  const ProfesorHomeScreen({super.key});

  @override
  State<ProfesorHomeScreen> createState() => _ProfesorHomeScreenState();
}

class _ProfesorHomeScreenState extends State<ProfesorHomeScreen> with SingleTickerProviderStateMixin {
  late Future<List<Entrenamiento>> _futureEntrenamientos;
  final EntrenamientoService _entrenamientoService = EntrenamientoService();
  final FileService _fileService = FileService();
  final ImagePicker _picker = ImagePicker();

  String _nombreProfesor = '';
  String _nombreUsuario = '';
  String _oposicion = '';
  int? _profesorId;
  Uint8List? _profileImage;
  bool _isLoadingImage = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Color amarillo = const Color(0xFFFFC107);
  final Color negro = Colors.black;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _cargarDatosProfesor();
    _cargarEntrenamientos();
    _cargarFotoProfesor();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosProfesor() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombreProfesor = prefs.getString('nombre') ?? 'Profesor';
      _nombreUsuario = prefs.getString('nombreUsuario') ?? '';
      _profesorId = prefs.getInt('id');
    });
  }

  Future<void> _cargarFotoProfesor() async {
    if (_profesorId == null) return;

    setState(() => _isLoadingImage = true);

    try {
      final imageBytes = await _fileService.downloadUserPhoto(_profesorId!);
      setState(() {
        _profileImage = imageBytes;
        _isLoadingImage = false;
      });
    } catch (e) {
      setState(() => _isLoadingImage = false);
      // No mostrar error si no hay foto, es normal
    }
  }

  Future<void> _cambiarFotoPerfil() async {
    if (_profesorId == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _isLoadingImage = true);

        final File imageFile = File(image.path);
        await _fileService.uploadFile(_profesorId!, imageFile);

        // Recargar la imagen
        await _cargarFotoProfesor();

        _showSnackBar('Foto actualizada correctamente', isError: false);
      }
    } catch (e) {
      setState(() => _isLoadingImage = false);
      _showSnackBar('Error al actualizar la foto: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _mostrarAlumnosDialog(BuildContext context, List<User> alumnos) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.2,
            maxChildSize: 0.6,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Barra de arrastre
                    Container(
                      width: 40,
                      height: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: amarillo,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.group, color: negro, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alumnos Apuntados',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: negro,
                                ),
                              ),
                              Text(
                                '${alumnos.length} ${alumnos.length == 1 ? 'alumno' : 'alumnos'}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (alumnos.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No hay alumnos apuntados',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: alumnos.length,
                          itemBuilder: (context, index) {
                            final alumno = alumnos[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: amarillo,
                                  child: Text(
                                    alumno.nombreUsuario[0].toUpperCase(),
                                    style: TextStyle(
                                      color: negro,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  alumno.nombreUsuario,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  'Estudiante activo',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade600,
                                  size: 16,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _cargarEntrenamientos() async {
    final prefs = await SharedPreferences.getInstance();
    final profesorId = prefs.getInt('id');

    if (profesorId == null) {
      setState(() {
        _futureEntrenamientos = Future.error(
          'No se encontró el ID del profesor en SharedPreferences',
        );
      });
      return;
    }

    final entrenamientos = _entrenamientoService.getFutureTrainingsByProfessor(profesorId);

    setState(() {
      _futureEntrenamientos = entrenamientos;
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Mis Entrenamientos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: amarillo,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black),
            onPressed: _cargarEntrenamientos,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header del perfil mejorado
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [negro, negro.withOpacity(0.8)],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    children: [
                      // Avatar con funcionalidad de cambio de foto
                      GestureDetector(
                        onTap: _cambiarFotoPerfil,
                        child: Stack(
                          children: [
                            Hero(
                              tag: 'profile_avatar',
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: amarillo,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: amarillo.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _isLoadingImage
                                      ? Container(
                                    color: amarillo,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(negro),
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  )
                                      : _profileImage != null
                                      ? Image.memory(
                                    _profileImage!,
                                    fit: BoxFit.cover,
                                    width: 80,
                                    height: 80,
                                  )
                                      : Container(
                                    color: amarillo,
                                    child: Icon(
                                      Icons.person,
                                      size: 40,
                                      color: negro,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Indicador de edición
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: amarillo,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  color: negro,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Información del profesor
                      Text(
                        _nombreProfesor,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: amarillo.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: amarillo.withOpacity(0.5)),
                        ),
                        child: Text(
                          '@$_nombreUsuario',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: amarillo,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Toca tu foto para cambiarla',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botón crear simulacro mejorado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [amarillo, amarillo.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: amarillo.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.crearSimulacro);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: negro,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Crear Nuevo Simulacro',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: negro,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Lista de entrenamientos mejorada
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.fitness_center_rounded, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Mis Entrenamientos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              FutureBuilder<List<Entrenamiento>>(
                future: _futureEntrenamientos,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC107)),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    final error = snapshot.error.toString();
                    if (error.contains('NO_ENTRENAMIENTOS') || error.contains('404')) {
                      return _buildEmptyState();
                    }
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error al cargar entrenamientos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error,
                            style: TextStyle(color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _cargarEntrenamientos,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: amarillo,
                              foregroundColor: negro,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  } else {
                    final entrenamientos = snapshot.data!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: entrenamientos.map((entrenamiento) {
                          final fechaHoraFormateada = DateFormat('d MMM y · HH:mm', 'es_ES')
                              .format(entrenamiento.fecha);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // Acción al pulsar el entrenamiento
                                },
                                onLongPress: () {
                                  _mostrarAlumnosDialog(context, entrenamiento.alumnos);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: amarillo.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.school_rounded,
                                              color: amarillo,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  entrenamiento.oposicion.replaceAll('_', ' '),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(
                                                      color: Colors.green.shade200,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Activo',
                                                    style: TextStyle(
                                                      color: Colors.green.shade700,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.grey.shade400,
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // Información del entrenamiento
                                      _buildInfoRow(
                                        Icons.schedule_rounded,
                                        'Fecha y hora',
                                        fechaHoraFormateada,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        Icons.location_on_rounded,
                                        'Lugar',
                                        entrenamiento.lugar,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        Icons.group_rounded,
                                        'Alumnos apuntados',
                                        '${entrenamiento.alumnos.length} ${entrenamiento.alumnos.length == 1 ? 'alumno' : 'alumnos'}',
                                        isClickable: entrenamiento.alumnos.isNotEmpty,
                                      ),

                                      if (entrenamiento.alumnos.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          'Mantén pulsado para ver alumnos',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes entrenamientos asignados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primer simulacro para comenzar',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isClickable = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isClickable ? amarillo : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (isClickable)
          Icon(
            Icons.touch_app_rounded,
            size: 16,
            color: Colors.grey.shade400,
          ),
      ],
    );
  }
}