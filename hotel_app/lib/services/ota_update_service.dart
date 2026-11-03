import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class OtaUpdateService {
  static final OtaUpdateService _instance = OtaUpdateService._internal();
  factory OtaUpdateService() => _instance;
  OtaUpdateService._internal();

  final ShorebirdUpdater _updater = ShorebirdUpdater();
  bool _isChecking = false;

  bool get isShorebirdAvailable => _updater.isAvailable;

  /// Get currently installed patch number (or null if on base release)
  Future<int?> getCurrentPatchNumber() async {
    if (!isShorebirdAvailable) return null;
    try {
      final patch = await _updater.readCurrentPatch();
      return patch?.number;
    } catch (e) {
      debugPrint('Error getting current patch number: $e');
      return null;
    }
  }

  /// Automatically check and download patches in background
  Future<void> checkForUpdatesAndDownload({
    BuildContext? context,
    bool showFeedback = false,
  }) async {
    if (_isChecking) return;
    if (!isShorebirdAvailable) {
      if (showFeedback && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shorebird OTA updates are active in Release builds. (Debug mode running)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    _isChecking = true;
    try {
      final status = await _updater.checkForUpdate();

      if (status == UpdateStatus.outdated) {
        debugPrint('New Shorebird OTA patch available! Downloading in background...');
        await _updater.update();
        debugPrint('Shorebird OTA patch downloaded successfully.');

        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.system_update_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'App updated! The changes will take effect on next launch.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else if (status == UpdateStatus.restartRequired) {
        if (showFeedback && context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An update was already downloaded. Please restart the app to apply it.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (showFeedback && context != null && context.mounted) {
          final patchNumber = await getCurrentPatchNumber();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  patchNumber != null
                      ? 'App is up to date (Patch #$patchNumber)'
                      : 'App is up to date (Latest Release)',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error during Shorebird OTA update check: $e');
    } finally {
      _isChecking = false;
    }
  }
}
