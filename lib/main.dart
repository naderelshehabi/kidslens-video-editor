import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/app.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media_kit for video playback
  MediaKit.ensureInitialized();

  _configureDesktopWindow();

  runApp(
    const ProviderScope(
      child: KidsLensApp(),
    ),
  );
}

void _configureDesktopWindow() {
  if (kIsWeb) return;

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    debugPrint('KidsLens Video Editor starting on ${Platform.operatingSystem}');
  }
}
