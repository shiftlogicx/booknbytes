import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  static bool _isChecking = false;

  /// Check version on startup or manually from Settings.
  /// [showFeedback] displays a confirmation snackbar if already on the latest version.
  static Future<void> checkVersion(
    BuildContext context, {
    bool showFeedback = false,
  }) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.0"

      // 1. Fetch remote versioning configuration from Supabase
      final response = await Supabase.instance.client
          .from('app_versions')
          .select()
          .eq('app_name', 'hotel_app')
          .maybeSingle();

      if (response == null) {
        if (showFeedback && context.mounted) {
          _showFeedbackSnackBar(context, 'Unable to check for updates at this moment.');
        }
        return;
      }

      final latestVersion = response['latest_version']?.toString() ?? currentVersion;
      final minRequiredVersion = response['min_required_version']?.toString() ?? currentVersion;
      final releaseNotes = response['release_notes']?.toString() ?? 'Performance improvements and bug fixes.';

      final playStoreUrl = response['play_store_url']?.toString() ??
          'https://play.google.com/store/apps/details?id=com.booknbite.hotel';
      final appStoreUrl = response['app_store_url']?.toString() ??
          'https://apps.apple.com/app/id67383606';

      final storeUrl = Platform.isIOS ? appStoreUrl : playStoreUrl;

      final isOutdated = _isVersionOlder(currentVersion, latestVersion);
      final isMandatory = _isVersionOlder(currentVersion, minRequiredVersion);

      if (!context.mounted) return;

      if (!isOutdated) {
        if (showFeedback) {
          _showFeedbackSnackBar(
            context,
            'Book & Bite Partner is up to date (v$currentVersion).',
            isSuccess: true,
          );
        }
        return;
      }

      // 2. Present Update Dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: !isMandatory,
        builder: (dialogCtx) => PopScope(
          canPop: !isMandatory,
          child: _buildUpdateDialog(
            context: dialogCtx,
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            releaseNotes: releaseNotes,
            storeUrl: storeUrl,
            isMandatory: isMandatory,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[AppUpdateService] Error checking version: $e');
      if (showFeedback && context.mounted) {
        _showFeedbackSnackBar(context, 'Check failed: $e');
      }
    } finally {
      _isChecking = false;
    }
  }

  static Widget _buildUpdateDialog({
    required BuildContext context,
    required String currentVersion,
    required String latestVersion,
    required String releaseNotes,
    required String storeUrl,
    required bool isMandatory,
  }) {
    final primaryColor = isMandatory ? const Color(0xFFDC2626) : const Color(0xFF00E599);
    final badgeColor = isMandatory ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5);
    final badgeTextColor = isMandatory ? const Color(0xFFB91C1C) : const Color(0xFF059669);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFF0F172A),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isMandatory ? Icons.warning_amber_rounded : Icons.system_update_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMandatory ? 'Update Required' : 'New Update Ready',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'v$currentVersion  ➔  v$latestVersion',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isMandatory ? 'MANDATORY' : 'RECOMMENDED',
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isMandatory
                  ? 'A critical update is required to continue receiving table reservations and real-time alerts.'
                  : 'A new version of Book & Bite Partner is available with enhancements.',
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'WHAT’S NEW',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    releaseNotes,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (!isMandatory) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF94A3B8),
                        side: const BorderSide(color: Color(0xFF334155)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Later', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: isMandatory ? 1 : 1,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: isMandatory ? Colors.white : const Color(0xFF0F172A),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final uri = Uri.parse(storeUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Text(
                      Platform.isIOS ? 'Update on App Store' : 'Update on Play Store',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _showFeedbackSnackBar(BuildContext context, String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: isSuccess ? const Color(0xFF059669) : const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Compares semantic version strings e.g. "1.0.0" < "1.1.0"
  static bool _isVersionOlder(String current, String target) {
    try {
      final cParts = current.split('+')[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final tParts = target.split('+')[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();

      while (cParts.length < 3) {
        cParts.add(0);
      }
      while (tParts.length < 3) {
        tParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (cParts[i] < tParts[i]) return true;
        if (cParts[i] > tParts[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
