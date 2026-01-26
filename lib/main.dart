import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
