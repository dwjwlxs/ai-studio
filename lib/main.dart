import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:media_kit/media_kit.dart';
import 'config/constants.dart';
import 'app/app.dart';
import 'data/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite for desktop
  await DatabaseHelper.instance.initialize();

  // Initialize MediaKit for video playback
  MediaKit.ensureInitialized();

  // Configure window
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    title: 'AI Studio',
    size: Size(1200, 800),
    minimumSize: Size(AppConstants.minWindowWidth, AppConstants.minWindowHeight),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: BifrostStudioApp()));
}
