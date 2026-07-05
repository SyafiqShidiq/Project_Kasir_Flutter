import 'package:package_info_plus/package_info_plus.dart';

class VersionChecker {
  Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  bool isUpdateAvailable({
    required String currentVersion,
    required String latestVersion,
  }) {
    return _compareVersions(currentVersion, latestVersion) < 0;
  }

  bool isForceUpdate({
    required String currentVersion,
    required String minimumVersion,
  }) {
    return _compareVersions(currentVersion, minimumVersion) < 0;
  }

  int _compareVersions(String current, String target) {
    final currentParts =
        current.split('.').map(int.parse).toList();

    final targetParts =
        target.split('.').map(int.parse).toList();

    final maxLength =
        currentParts.length > targetParts.length
            ? currentParts.length
            : targetParts.length;

    while (currentParts.length < maxLength) {
      currentParts.add(0);
    }

    while (targetParts.length < maxLength) {
      targetParts.add(0);
    }

    for (int i = 0; i < maxLength; i++) {
      if (currentParts[i] < targetParts[i]) return -1;
      if (currentParts[i] > targetParts[i]) return 1;
    }

    return 0;
  }
}