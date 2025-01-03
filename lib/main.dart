import 'package:flutter/material.dart';
import 'login.dart'; // Import the LoginPage file
import 'dashboard.dart'; // Import the DashboardPage
import  'appbar.dart';
import 'attendance.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login Page',
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      home: const LoginPage(), // Set LoginPage as the home widget
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardPage());
          case '/attendance':
            return MaterialPageRoute(builder: (_) => const Attendance());

          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(child: Text('No route defined for ${settings.name}')),
              ),
            );
        }
      },
    );
  }
}
