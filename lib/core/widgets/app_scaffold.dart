import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/widgets/brand_mark.dart';
import 'package:teletech_drivers/features/notification/presentation/widgets/notification_bell_button.dart';

/// App-wide scaffold that always surfaces the TeleCars ring mark.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.title,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.bottom,
    this.showBackButton,
    this.showAppBar = true,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
    this.floatingActionButtonLocation,
    this.onLogoLongPress,
    this.showNotifications = true,
    super.key,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;
  final bool? showBackButton;
  final bool showAppBar;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Optional long-press on the app-bar logo (debug tools, etc.).
  final VoidCallback? onLogoLongPress;

  /// Bell with the unread count. Stays in the app bar, never the glass bar.
  final bool showNotifications;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final showLeading = showBackButton ?? canPop;
    final barLift = GlassBarInset.of(context);
    final fabLocation = barLift > 0
        ? GlassBarFabLocation(
            base:
                floatingActionButtonLocation ??
                FloatingActionButtonLocation.endFloat,
            lift: barLift,
          )
        : floatingActionButtonLocation;

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.scaffold,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: showAppBar
          ? AppBar(
              automaticallyImplyLeading: false,
              leading: showLeading
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  : null,
              titleSpacing: showLeading ? 0 : 16,
              title: _AppBarTitle(
                title: title,
                onLogoLongPress: onLogoLongPress,
              ),
              actions: [
                if (showNotifications) const NotificationBellButton(),
                ...?actions,
              ],
              bottom: bottom,
            )
          : null,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: fabLocation,
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({this.title, this.onLogoLongPress});

  final String? title;
  final VoidCallback? onLogoLongPress;

  @override
  Widget build(BuildContext context) {
    final text = title?.trim();
    final hasTitle = text != null && text.isNotEmpty;

    Widget logo = const BrandMark(size: 28);
    final longPress = onLogoLongPress;
    if (longPress != null) {
      logo = GestureDetector(
        onLongPress: longPress,
        child: logo,
      );
    }

    return Row(
      children: [
        logo,
        if (hasTitle) ...[
          const SizedBox(width: 12),
          Expanded(child: _FittedTitle(text: text)),
        ],
      ],
    );
  }
}

/// Screen title that never truncates a normal title: full size when it fits
/// on one line, otherwise a step smaller and allowed two lines.
class _FittedTitle extends StatelessWidget {
  const _FittedTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final large = textTheme.titleLarge;
        final painter = TextPainter(
          text: TextSpan(text: text, style: large),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final fits = !painter.didExceedMaxLines;
        painter.dispose();
        return Text(
          text,
          maxLines: fits ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: fits
              ? large
              : textTheme.titleMedium?.copyWith(height: 1.15),
        );
      },
    );
  }
}
