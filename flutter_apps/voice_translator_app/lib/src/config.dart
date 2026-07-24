class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://myapis.amarthikanaa.com',
  );

  static Uri api(String path) => Uri.parse('$apiBaseUrl$path');

  static String hub(String path) => '$apiBaseUrl$path';
}
