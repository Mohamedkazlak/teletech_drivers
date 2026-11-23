import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';

/// Draws a brand border around [child] and scrolls it into view once.
class HighlightedRequest extends StatefulWidget {
  const HighlightedRequest({
    required this.highlighted,
    required this.child,
    super.key,
  });

  final bool highlighted;
  final Widget child;

  @override
  State<HighlightedRequest> createState() => _HighlightedRequestState();
}

class _HighlightedRequestState extends State<HighlightedRequest> {
  @override
  void initState() {
    super.initState();
    if (!widget.highlighted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Scrollable.maybeOf(context) == null) return;
      Scrollable.ensureVisible(context, alignment: 0.2);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.highlighted) return widget.child;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.deepBlue, width: 2),
      ),
      child: widget.child,
    );
  }
}

/// `?request=` on the current route, when a router is present.
String? highlightedRequestId(BuildContext context) {
  final router = GoRouter.maybeOf(context);
  if (router == null) return null;
  final id = router.state.uri.queryParameters['request']?.trim();
  if (id == null || id.isEmpty) return null;
  return id;
}
