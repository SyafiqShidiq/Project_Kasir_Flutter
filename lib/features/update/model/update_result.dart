import 'app_config.dart';
import '../enum/update_status.dart';

class UpdateResult {
  const UpdateResult({
    required this.status,
    required this.config,
    required this.currentVersion,
  });

  final UpdateStatus status;
  final AppConfig config;
  final String currentVersion;
}