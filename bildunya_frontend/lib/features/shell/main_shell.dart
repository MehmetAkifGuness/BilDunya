import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/app_colors.dart';
import '../home/home_view.dart';
import '../map/map_view.dart';
import '../feed/feed_view.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const String routeName = '/main';

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeView(),
          MapView(),
          FeedView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: AppColors.surfaceContainer,
        indicatorColor: AppColors.primaryContainer.withValues(alpha: 0.25),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Symbols.home),
            selectedIcon: Icon(Symbols.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Symbols.map),
            selectedIcon: Icon(Symbols.map),
            label: 'Harita',
          ),
          NavigationDestination(
            icon: Icon(Symbols.dynamic_feed),
            selectedIcon: Icon(Symbols.dynamic_feed),
            label: 'Akış',
          ),
        ],
      ),
    );
  }
}
