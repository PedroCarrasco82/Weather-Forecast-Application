import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config{
  static String get apiKey => _get("API_KEY");

  static String _get(String name) => DotEnv().env[name] ?? "";
}