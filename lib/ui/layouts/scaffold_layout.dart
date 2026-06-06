import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';

class ScaffoldLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;
    final isConnected = ref.watch(connectionStatusProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Side navigation
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == currentIndex,
              );
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(Icons.rocket_launch,
                      size: 32, color: theme.colorScheme.primary),
                  const SizedBox(height: 4),
                  Text('AI Studio',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
            trailing: Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      isConnected ? Icons.cloud_done : Icons.cloud_off,
                      color: isConnected ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    tooltip: isConnected ? 'Connected' : 'Disconnected',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: Icon(
                      theme.brightness == Brightness.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      size: 20,
                    ),
                    tooltip: 'Toggle theme',
                    onPressed: () {
                      final current = ref.read(themeModeProvider);
                      ref.read(themeModeProvider.notifier).setThemeMode(
                            current == ThemeMode.dark
                                ? ThemeMode.light
                                : ThemeMode.dark,
                          );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Config'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat_outlined),
                selectedIcon: Icon(Icons.chat),
                label: Text('Chat'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.image_outlined),
                selectedIcon: Icon(Icons.image),
                label: Text('Image'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.videocam_outlined),
                selectedIcon: Icon(Icons.videocam),
                label: Text('Video'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.monitor_heart_outlined),
                selectedIcon: Icon(Icons.monitor_heart),
                label: Text('Network'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
