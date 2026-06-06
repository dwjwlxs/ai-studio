import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../ui/layouts/scaffold_layout.dart';
import '../ui/pages/server_config/server_config_page.dart';
import '../ui/pages/chat/chat_page.dart';
import '../ui/pages/image/image_page.dart';
import '../ui/pages/video/video_page.dart';
import '../ui/pages/network/network_inspector_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _configNavigatorKey = GlobalKey<NavigatorState>();
final _chatNavigatorKey = GlobalKey<NavigatorState>();
final _imageNavigatorKey = GlobalKey<NavigatorState>();
final _videoNavigatorKey = GlobalKey<NavigatorState>();
final _networkNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/config',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ScaffoldLayout(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _configNavigatorKey,
          routes: [
            GoRoute(
              path: '/config',
              builder: (context, state) => const ServerConfigPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _chatNavigatorKey,
          routes: [
            GoRoute(
              path: '/chat',
              builder: (context, state) => const ChatPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _imageNavigatorKey,
          routes: [
            GoRoute(
              path: '/image',
              builder: (context, state) => const ImagePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _videoNavigatorKey,
          routes: [
            GoRoute(
              path: '/video',
              builder: (context, state) => const VideoPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _networkNavigatorKey,
          routes: [
            GoRoute(
              path: '/network',
              builder: (context, state) => const NetworkInspectorPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
