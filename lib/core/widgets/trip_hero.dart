import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_gradients.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/core/theme/app_typography.dart';
import 'package:teletech_drivers/core/widgets/brand_mark.dart';
import 'package:teletech_drivers/core/widgets/route_line.dart';

/// Shared-element link between a trip card in a list and the header of that
/// trip's details screen. The white card grows and darkens into the navy
/// header; each side's content cross-fades at its own size, so nothing
/// reflows mid-flight.
class TripHero extends StatelessWidget {
  const TripHero({required this.tripId, required this.child, super.key});

  final String tripId;
  final Widget child;

  static Object tagFor(String tripId) => 'trip-hero-$tripId';

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tagFor(tripId),
      flightShuttleBuilder: _shuttle,
      child: child,
    );
  }

  static Widget _shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    final push = direction == HeroFlightDirection.push;
    final cardContext = push ? fromContext : toContext;
    final headerContext = push ? toContext : fromContext;
    final cardHero = cardContext.widget as Hero;
    final headerHero = headerContext.widget as Hero;
    final cardSize = (cardContext.findRenderObject() as RenderBox?)?.size;
    final headerSize = (headerContext.findRenderObject() as RenderBox?)?.size;

    Widget atSize(Size? size, Widget child) {
      if (size == null) return const SizedBox.shrink();
      return ClipRect(
        child: OverflowBox(
          alignment: AlignmentDirectional.topStart,
          minWidth: size.width,
          maxWidth: size.width,
          minHeight: size.height,
          maxHeight: size.height,
          child: child,
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = AppMotion.easeInOut.transform(animation.value);
          final radius = BorderRadius.circular(
            AppTheme.cardRadius + (24 - AppTheme.cardRadius) * t,
          );
          return ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(AppColors.white, AppColors.navy, t),
                  ),
                ),
                Opacity(
                  opacity: (1 - t / 0.45).clamp(0.0, 1.0),
                  child: atSize(cardSize, cardHero.child),
                ),
                Opacity(
                  opacity: ((t - 0.55) / 0.45).clamp(0.0, 1.0),
                  child: atSize(headerSize, headerHero.child),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Navy header at the top of a trip's details screen: status, route,
/// schedule and an optional live line. Pair it with a [TripHero].
class TripHeroHeader extends StatelessWidget {
  const TripHeroHeader({
    required this.from,
    required this.to,
    required this.statusLabel,
    required this.statusColor,
    this.meta,
    this.live = false,
    this.footer,
    super.key,
  });

  final String from;
  final String to;
  final String statusLabel;
  final Color statusColor;

  /// Usually the scheduled time.
  final String? meta;
  final bool live;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.floatingShadow(opacity: 0.18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: RingField(opacity: 0.06)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _DarkStatusPill(
                          label: statusLabel,
                          color: statusColor,
                          live: live,
                        ),
                      ),
                    ),
                    if (meta != null) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          meta!,
                          textAlign: TextAlign.end,
                          style: AppTypography.tabular(
                            textTheme.labelLarge?.copyWith(
                              color: AppColors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 18),
                RouteLine(
                  from: from,
                  to: to,
                  live: live,
                  onDark: true,
                  large: true,
                ),
                if (footer != null) ...[const SizedBox(height: 16), footer!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkStatusPill extends StatelessWidget {
  const _DarkStatusPill({
    required this.label,
    required this.color,
    required this.live,
  });

  final String label;
  final Color color;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 5, 12, 5),
      decoration: ShapeDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RingPulse(
            size: 16,
            color: color,
            active: live,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What a details screen shows while the trip loads: the navy header shape
/// (so the card still has somewhere to fly) and two skeleton rows.
class TripHeroPlaceholder extends StatelessWidget {
  const TripHeroPlaceholder({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, {double alpha = 0.16}) => Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
      children: [
        TripHero(
          tripId: tripId,
          child: Container(
            height: 176,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(96, alpha: 0.22),
                const SizedBox(height: 28),
                bar(180),
                const SizedBox(height: 18),
                bar(140, alpha: 0.24),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const _SkeletonCard(),
        const SizedBox(height: 12),
        const _SkeletonCard(),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.line),
      ),
    );
  }
}

/// One icon + text line inside [TripHeroHeader.footer] (driver, passengers).
class TripHeroInfoRow extends StatelessWidget {
  const TripHeroInfoRow({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.white.withValues(alpha: 0.72)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.88),
            ),
          ),
        ),
      ],
    );
  }
}
