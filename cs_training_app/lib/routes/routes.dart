import 'package:cs_training_app/screens/admin/activar_usuarios.dart';
import 'package:cs_training_app/screens/auth/register_screen.dart';
import 'package:cs_training_app/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import '../screens/admin/admin_home.dart';

class AppRoutes {
  static const String register = '/register';
  static const String login = '/login';
  static const String home = '/home';
  static const String adminHome = '/admin_home';
  static const String activarUsuarios = '/activar_usuarios';

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
      default:
        return MaterialPageRoute(builder: (_) => LoginScreen());
    }
  }
}
