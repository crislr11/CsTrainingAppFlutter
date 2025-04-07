import 'package:cs_training_app/screens/home_screen.dart';
import 'package:cs_training_app/screens/auth/register_screen.dart';
import 'package:cs_training_app/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import '../screens/admin/crear_clase_screen.dart';
import '../screens/admin/clases_screen.dart';

class AppRoutes {
  static const String register = '/register';
  static const String login = '/login';
  static const String home = '/home';
  static const String crearClase = '/crear_clase';
  static const String clases = '/clases';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case crearClase:
        return MaterialPageRoute(builder: (_) => CrearClaseScreen());
      case clases:
        return MaterialPageRoute(builder: (_) => ClasesScreen());
      default:
        return MaterialPageRoute(builder: (_) => LoginScreen());
    }
  }
}
