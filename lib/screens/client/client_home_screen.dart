import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'new_booking_tab.dart';
import 'my_bookings_tab.dart';
import 'profile_cars_tab.dart';
import 'info_contact_tab.dart';

class ClientHomeScreen extends StatefulWidget {
  final UserModel user;
  const ClientHomeScreen({super.key, required this.user});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      NewBookingTab(user: widget.user),
      MyBookingsTab(user: widget.user),
      const InfoContactTab(),
      ProfileCarsTab(user: widget.user),
    ];

    final titles = [
      'Új időpontfoglalás',
      'Foglalásaim',
      'Információ & Útvonaltervezés',
      'Profil & Autóim',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        elevation: 2,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Új foglalás',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Foglalásaim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Információ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil / Autóim',
          ),
        ],
      ),
    );
  }
}
