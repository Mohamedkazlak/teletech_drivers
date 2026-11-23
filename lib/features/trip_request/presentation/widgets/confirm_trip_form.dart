import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/trip_request/presentation/controllers/confirm_trip_controller.dart';

/// "Did the driver show up?" plus an optional note.
class ConfirmTripForm extends ConsumerStatefulWidget {
  const ConfirmTripForm({required this.requestId, super.key});

  final String requestId;

  @override
  ConsumerState<ConfirmTripForm> createState() => _ConfirmTripFormState();
}

class _ConfirmTripFormState extends ConsumerState<ConfirmTripForm> {
  static const _noteLimit = 500;

  final _note = TextEditingController();
  bool? _showedUp;
  String? _errorText;
  var _scrolledToReport = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scrolledToReport) return;
    final report = GoRouter.maybeOf(context)?.state.uri.queryParameters['report'];
    if (report != '1') return;
    _scrolledToReport = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || Scrollable.maybeOf(context) == null) return;
      Scrollable.ensureVisible(context, alignment: 0.1);
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final submitting = ref.watch(confirmTripControllerProvider).isSubmitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.confirmTripQuestion, style: textTheme.titleMedium),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: true, label: Text(l10n.confirmTripYes)),
            ButtonSegment(value: false, label: Text(l10n.confirmTripNo)),
          ],
          selected: _showedUp == null ? const <bool>{} : {_showedUp!},
          onSelectionChanged: submitting
              ? null
              : (selection) {
                  setState(() {
                    _showedUp = selection.isEmpty ? null : selection.first;
                    _errorText = null;
                  });
                },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _note,
          enabled: !submitting,
          maxLength: _noteLimit,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.notesLabel,
            hintText: l10n.confirmTripNoteHint,
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorText!,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: submitting ? null : _submit,
          style: FilledButton.styleFrom(
            minimumSize: AppTheme.controlMinimumSize,
          ),
          child: Text(submitting ? l10n.loading : l10n.confirmTripSubmit),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final showedUp = _showedUp;
    if (showedUp == null) {
      setState(() => _errorText = l10n.confirmTripChooseAnswer);
      return;
    }
    final note = _note.text.trim();
    if (note.length > _noteLimit) {
      setState(() => _errorText = l10n.confirmTripNoteTooLong);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final result = await ref
        .read(confirmTripControllerProvider.notifier)
        .submit(
          requestId: widget.requestId,
          driverShowedUp: showedUp,
          note: note.isEmpty ? null : note,
        );
    if (!mounted) {
      _showResult(messenger, l10n, result);
      return;
    }
    _showResult(messenger, l10n, result);
  }

  void _showResult(
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
    ConfirmTripResult result,
  ) {
    final message = switch (result) {
      ConfirmTripResult.success => l10n.confirmTripSuccess,
      ConfirmTripResult.alreadyClosed => l10n.confirmTripAlreadyClosed,
      ConfirmTripResult.failed =>
        mounted
            ? (ref.read(confirmTripControllerProvider).failure?.message(l10n) ??
                  l10n.errorUnknown)
            : l10n.errorUnknown,
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
