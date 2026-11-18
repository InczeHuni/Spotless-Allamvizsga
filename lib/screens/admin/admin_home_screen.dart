import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'admin_bookings_tab.dart';
import 'admin_services_tab.dart';
import 'admin_settings_tab.dart';

class AdminHomeScreen extends StatefulWidget {
  final UserModel user;
  const AdminHomeScreen({super.key, required this.user});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const AdminBookingsTab(),
      const AdminServicesTab(),
      AdminSettingsTab(user: widget.user),
    ];

    final titles = [
      'Napi Naptár & Foglalások',
      'Mosási Csomagok Kezelése',
      'Admin Beállítások',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        backgroundColor: Colors.amber.shade900,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.amber.shade900,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Foglalások',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cleaning_services_outlined),
            activeIcon: Icon(Icons.cleaning_services),
            label: 'Szolgáltatások',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings_outlined),
            activeIcon: Icon(Icons.admin_panel_settings),
            label: 'Beállítások',
          ),
        ],
      ),
    );
  }
}
