import '../service/update_service.dart';
import '../service/version_checker.dart';
import '../enum/update_status.dart';
import '../model/update_result.dart';

class UpdateManager {
  UpdateManager({
    required UpdateService service,
    required VersionChecker checker,
  })  : _service = service,
        _checker = checker;

  final UpdateService _service;
  final VersionChecker _checker;

  Future<UpdateResult> checkForUpdates() async {
    final config = await _service.getConfig();

    final currentVersion =
        await _checker.currentVersion();
    
    if (config.maintenanceMode) {
      return UpdateResult(
        status: UpdateStatus.maintenance,
        config: config,
        currentVersion: currentVersion,
      );
    }

    if (_checker.isForceUpdate(
      currentVersion: currentVersion,
      minimumVersion: config.minimumVersion,
    )) {
      return UpdateResult(
        status: UpdateStatus.forceUpdate,
        config: config,
        currentVersion: currentVersion,
      );
    }

    if (_checker.isUpdateAvailable(
      currentVersion: currentVersion,
      latestVersion: config.latestVersion,
    )) {
      return UpdateResult(
        status: UpdateStatus.optionalUpdate,
        config: config,
        currentVersion: currentVersion,
      );
    }

    return UpdateResult(
      status: UpdateStatus.upToDate,
      config: config,
      currentVersion: currentVersion,
    );
  }
}