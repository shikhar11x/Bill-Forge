import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment { development, staging, production }

class Env {
  const Env({required this.environment, required this.apiBaseUrl});

  final AppEnvironment environment;
  final String apiBaseUrl;

  bool get isProduction => environment == AppEnvironment.production;

  static Future<Env> load() async {
    await dotenv.load();
    final name = dotenv.get('APP_ENV', fallback: 'development');
    return Env(
      environment: AppEnvironment.values.firstWhere(
        (e) => e.name == name,
        orElse: () => AppEnvironment.development,
      ),
      apiBaseUrl: dotenv.get('API_BASE_URL', fallback: 'http://localhost:3000'),
    );
  }
}

/// Overridden in `main()` once the environment has been loaded.
final envProvider = Provider<Env>(
  (ref) => throw UnimplementedError('envProvider must be overridden in main()'),
);