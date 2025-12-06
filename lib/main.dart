import 'package:flutter/material.dart';
import 'services/logger_service.dart';

void main() {
  LogService.i('Application starting up...');
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    LogService.d("Building MyApp widget");

    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Hello!')),
      ),
    );
  }
}
