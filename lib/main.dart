import 'package:flutter/material.dart';
import 'package:international_cunnibal/screens/home_screen.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request necessary permissions
  await Permission.camera.request();
  await Permission.storage.request();
  
  runApp(const InternationalCunnibalApp());
}

class InternationalCunnibalApp extends StatelessWidget {
  const InternationalCunnibalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'International Cunnibal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
