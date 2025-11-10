import 'package:flutter/material.dart';

import '../../auth/services/auth_service.dart';
import '../../contests/screens/home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final int _currentIndex = 0;
  bool isAdmin = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isUserAdmin = await _authService.isUserAdmin();
    setState(() {
      isAdmin = isUserAdmin;
    });
  }

  @override
  Widget build(BuildContext context) {
    // For now, just show HomeScreen without bottom navigation
    // Users can access other screens via drawer/menu
    return const Scaffold(
      body: HomeScreen(),
    );
  }
}
