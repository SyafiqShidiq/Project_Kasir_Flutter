class AppConfig {
  const AppConfig({
    required this.latestVersion,
    required this.minimumVersion,
    required this.forceUpdate,
    required this.maintenanceMode,
    required this.playstoreUrl,
    required this.updateTitle,
    required this.updateMessage,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      latestVersion: json['latest_version'],
      minimumVersion: json['minimum_version'],
      forceUpdate: json['force_update'] ?? false,
      maintenanceMode: json['maintenance_mode'] ?? false,
      playstoreUrl: json['playstore_url'],
      updateTitle: json['update_title'] ?? '',
      updateMessage: json['update_message'] ?? '',
    );
  }

  final String latestVersion;
  final String minimumVersion;
  final bool forceUpdate;
  final bool maintenanceMode;
  final String playstoreUrl;
  final String updateTitle;
  final String updateMessage;
}