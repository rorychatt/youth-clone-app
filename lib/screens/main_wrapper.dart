import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'data_screen.dart';
import 'home_screen.dart';
import 'services_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DataScreen(),
    const ServicesScreen(),
    const Center(child: Text("Plan Screen")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows background to flow under the navbar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      // Switching the body directly (instead of IndexedStack) forces the Services screen
      // to re-run initState and fetch the latest connected providers every time it's opened!
      body: _screens[_currentIndex],
    );
  }
}
