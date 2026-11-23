import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/features/attendance/presentation/providers/attendance_providers.dart';

/// The single headquarters QR. Printing is done from the website.
class AttendanceQrScreen extends ConsumerWidget {
  const AttendanceQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final qr = ref.watch(attendanceQrProvider);
    return AppScaffold(
      title: l10n.attendanceQrTitle,
      showBackButton: true,
      body: qr.when(
        loading: () => Center(child: AppLoadingIndicator(label: l10n.loading)),
        error: (error, _) => Center(child: Text(messageForError(error, l10n))),
        data: (value) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.hqName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                QrImageView(data: value.payload, size: 240),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
