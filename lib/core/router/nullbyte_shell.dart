import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell widget untuk ShellRoute — Home + Mission + Dictionary + Achievements + Profile.
class NullbyteShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const NullbyteShell({super.key, required this.navigationShell});

  static const _tabs = [
    _NavTab(label: 'Home', icon: Icons.home),
    _NavTab(label: 'Mission', icon: Icons.assignment),
    _NavTab(label: 'Dictionary', icon: Icons.menu_book),
    _NavTab(label: 'Achievements', icon: Icons.emoji_events),
    _NavTab(label: 'Profile', icon: Icons.person),
  ];

  void _onTabTapped(int index) {
    if (index == navigationShell.currentIndex) {
      navigationShell.goBranch(index, initialLocation: true);
    } else {
      navigationShell.goBranch(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: _tabs
            .map(
              (tab) =>
                  NavigationDestination(icon: Icon(tab.icon), label: tab.label),
            )
            .toList(),
      ),
    );
  }
}

class _NavTab {
  final String label;
  final IconData icon;

  const _NavTab({required this.label, required this.icon});
}
