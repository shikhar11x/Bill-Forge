import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:billforge/app/app.dart';
import 'package:billforge/app/config/env.dart';
import 'package:billforge/core/utils/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Uncaught error', error: error, stackTrace: stack);
    return true;
  };

  final env = await Env.load();

  runApp(
    ProviderScope(
      overrides: [envProvider.overrideWithValue(env)],
      child: const BillForgeApp(),
    ),
  );
}