import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';

/// Camera plugin exists on Android, iOS, macOS, and web. Windows and Linux have none.
bool get attendanceScannerSupported {
  if (kIsWeb) return true;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.macOS => true,
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.windows => false,
  };
}

/// Full-screen camera. Pops the raw QR string, or null when the driver cancels.
class AttendanceScanScreen extends StatefulWidget {
  const AttendanceScanScreen({super.key});

  static Future<String?> open(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const AttendanceScanScreen()),
    );
  }

  @override
  State<AttendanceScanScreen> createState() => _AttendanceScanScreenState();
}

class _AttendanceScanScreenState extends State<AttendanceScanScreen> {
  var _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .map((value) => value.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;
    _handled = true;
    Navigator.of(context).pop(raw);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n.attendanceScanTitle,
      showBackButton: true,
      body: attendanceScannerSupported
          ? MobileScanner(onDetect: _onDetect)
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  l10n.attendanceScanUnsupported,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}
