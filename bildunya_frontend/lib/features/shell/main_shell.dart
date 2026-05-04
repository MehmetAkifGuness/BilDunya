import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../auth/providers/auth_provider.dart';
import '../chat/providers/chat_inbox_provider.dart';
import '../chat/screens/chat_inbox_view.dart';
import '../content/screens/create_content_view.dart';
import '../feed/feed_view.dart';
import '../home/home_view.dart';
import '../map/map_view.dart';
import '../profile/screens/profile_view.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const String routeName = '/main';

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _openCreateContent(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => const CreateContentView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeView(),
          MapView(),
          FeedView(),
          ChatInboxView(),
          ProfileView(),
        ],
      ),
      floatingActionButton: _index == 3
          ? null
          : FloatingActionButton(
              elevation: 4,
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimary,
              tooltip: 'Paylaşım oluştur',
              onPressed: () => _openCreateContent(context),
              child: const Icon(Symbols.add, size: 28),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surfaceContainer,
        indicatorColor: AppColors.primaryContainer.withValues(alpha: 0.25),
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 3) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              final auth = context.read<AuthProvider>();
              if (auth.isAuthenticated) {
                unawaited(context.read<ChatInboxProvider>().load());
              }
            });
          }
        },
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
          NavigationDestination(
            icon: Icon(Symbols.chat),
            selectedIcon: Icon(Symbols.chat),
            label: 'Mesajlar',
          ),
          NavigationDestination(
            icon: Icon(Symbols.person),
            selectedIcon: Icon(Symbols.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
