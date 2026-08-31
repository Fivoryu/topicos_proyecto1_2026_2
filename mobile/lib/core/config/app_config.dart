/// Compile-time routing configuration for the single protected demo group.
class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.groupId});

  static const fromEnvironment = AppConfig(
    apiBaseUrl: String.fromEnvironment('API_BASE_URL', defaultValue: ''),
    groupId: String.fromEnvironment('GROUP_ID', defaultValue: ''),
  );

  final String apiBaseUrl;
  final String groupId;

  bool get hasRoutingConfiguration =>
      apiBaseUrl.trim().isNotEmpty && groupId.trim().isNotEmpty;

  Uri? get apiBaseUri {
    final value = apiBaseUrl.trim();
    return value.isEmpty ? null : Uri.tryParse(value);
  }
}
