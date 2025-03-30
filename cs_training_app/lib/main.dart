import 'package:cs_training_app/routes/routes.dart';
import 'package:flutter/material.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CS Training App',
      initialRoute: AppRoutes.register,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
