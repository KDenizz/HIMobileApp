import 'package:flutter/material.dart';
import 'ui/dashboard_screen.dart'; // Yeni yazdığımız ekranı içeri aktardık

void main() {
  runApp(const ZMonitorApp());
}

class ZMonitorApp extends StatelessWidget {
  const ZMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Z-Monitor',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const DashboardScreen(), // Uygulama direkt bu ekranla açılacak
    );
  }
}