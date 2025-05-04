import 'package:cs_training_app/screens/admin/activar_usuarios.dart';
import 'package:cs_training_app/screens/admin/clases_screen.dart';
import 'package:cs_training_app/screens/admin/pagos_screen.dart';
import 'package:cs_training_app/screens/auth/register_screen.dart';
import 'package:cs_training_app/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import '../screens/admin/admin_home.dart';
import '../screens/admin/crear_clases_screen.dart';
import '../screens/profesor/profesor_home_screen.dart';

class AppRoutes {
  static const String register = '/register';
  static const String login = '/login';
  static const String home = '/home';
  static const String adminHome = '/admin_home';
  static const String activarUsuarios = '/activar_usuarios';
  static const String clasesAdmin = "/clases";
  static const String crearClase = '/crear_clase';
  static const String pagoScreen = '/pago_screen';
  static const String profesorHome = '/profesor_home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case adminHome:
        return MaterialPageRoute(builder: (_) => AdminHome());
      case activarUsuarios:
        return MaterialPageRoute(builder: (_) => ActivarUsuarios());
      case clasesAdmin:
        return MaterialPageRoute(builder: (_) => ClasesScreen());
      case crearClase:
        return MaterialPageRoute(builder: (_) => const CrearClaseScreen());
      case pagoScreen:
        return MaterialPageRoute(builder: (_) => PagosScreen());
      case profesorHome:
        return MaterialPageRoute(builder: (_) => const ProfesorHomeScreen());
      default:
        return MaterialPageRoute(builder: (_) => LoginScreen());
    }
  }
}
