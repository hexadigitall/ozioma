import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'territories_screen.dart';
import 'rv_screen.dart';
import 'timer_screen.dart';
import 'resources_screen.dart';

class Shell extends StatefulWidget { const Shell({super.key}); @override State<Shell> createState() => _ShellState(); }
class _ShellState extends State<Shell> {
  int idx = 0;
  final pages = [DashboardScreen(), TerritoriesScreen(), RVScreen(), TimerScreen(), ResourcesScreen()];
  @override Widget build(BuildContext context) {
    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i)=>setState(()=>idx=i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Territories'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Return Visits'),
          NavigationDestination(icon: Icon(Icons.timer), label: 'Timer'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Resources'),
        ],
      ),
    );
  }
}
