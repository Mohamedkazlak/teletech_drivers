import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/localization/language_toggle_button.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_gradients.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/core/widgets/brand_mark.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/app_logo.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/sign_out_button.dart';

/// Shown while auth state is resolving, and when that resolution fails.
class AuthSplashScreen extends ConsumerWidget {
  const AuthSplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(currentUserProvider);
    final reduceMotion = AppAnimations.disabled(context);

    return AppScaffold(
      showAppBar: false,
      backgroundColor: AppColors.deepBlue,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        child: SafeArea(
          child: Stack(
            children: [
              const Align(
                alignment: AlignmentDirectional.topEnd,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(top: 4, end: 8),
                  child: LanguageToggleButton(onBrandBackground: true),
                ),
              ),
              auth.when(
                loading: () => _SplashLogo(reduceMotion: reduceMotion),
                data: (_) => _SplashLogo(reduceMotion: reduceMotion),
                error: (error, _) =>
                    _AuthSplashError(message: messageForError(error, l10n)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated splash: a "signal" moment built from the TeleTech ring.
///
/// 0–600 ms   a soft signal-blue glow rises behind the centre
/// 0–1500 ms  three rings ripple out from the logo, staggered
/// 100–520 ms the white logo card settles in (scale 0.9 → 1)
/// 250 ms →   the vector logo builds itself (ellipses, wordmark, rings)
/// 1250–1750  one light sweep crosses the card
/// 900 ms →   "TeleCars" fades up beneath it
///
/// Plays once per cold start; the router holds the splash until it ends
/// (see splash_gate.dart). Under "Remove animations" everything is static.
class _SplashLogo extends StatefulWidget {
  const _SplashLogo({required this.reduceMotion});

  final bool reduceMotion;

  @override
  State<_SplashLogo> createState() => _SplashLogoState();
}

class _SplashLogoState extends State<_SplashLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// [_controller] mapped into [begin, end] (milliseconds), eased.
  double _at(double begin, double end, {Curve curve = AppMotion.easeOut}) {
    const total = 1900.0;
    final t = ((_controller.value * total - begin) / (end - begin)).clamp(
      0.0,
      1.0,
    );
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final card = Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 28,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.floatingShadow(opacity: 0.35),
      ),
      child: AppLogo(
        height: 72,
        animated: !widget.reduceMotion,
        delay: const Duration(milliseconds: 250),
        heroTag: AppLogo.defaultHeroTag,
      ),
    );

    return Stack(
      children: [
        const Positioned.fill(child: RingField(opacity: 0.05, rings: 7)),
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _SignalPainter(
                  glow: _at(0, 600),
                  rings: [
                    for (final start in const [0.0, 180.0, 360.0])
                      _at(start, start + 1140),
                  ],
                ),
              ),
            ),
          ),
        ),
        Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final enter = _at(100, 520);
              final sheen = _at(1250, 1750, curve: AppMotion.easeInOut);
              final title = _at(900, 1300);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: enter,
                    child: Transform.scale(
                      scale: 0.9 + 0.1 * enter,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Stack(
                          children: [
                            child!,
                            if (sheen > 0 && sheen < 1)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: _Sheen(progress: sheen),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: title,
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - title)),
                      child: Text(
                        'TeleCars',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.78),
                          letterSpacing: 4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            child: card,
          ),
        ),
      ],
    );
  }
}

/// Glow and expanding rings behind the logo.
class _SignalPainter extends CustomPainter {
  const _SignalPainter({required this.glow, required this.rings});

  final double glow;
  final List<double> rings;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(const Offset(0, -18));
    final maxR = size.longestSide * 0.62;

    if (glow > 0) {
      canvas.drawCircle(
        center,
        maxR * 0.7,
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.signal.withValues(alpha: 0.32 * glow),
              AppColors.signal.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: maxR * 0.7)),
      );
    }

    final paint = Paint()..style = PaintingStyle.stroke;
    for (final t in rings) {
      if (t <= 0 || t >= 1) continue;
      paint
        ..strokeWidth = 1.6 * (1 - t) + 0.6
        ..color = AppColors.white.withValues(alpha: 0.35 * (1 - t));
      canvas.drawCircle(center, 70 + (maxR - 70) * t, paint);
    }
  }

  @override
  bool shouldRepaint(_SignalPainter oldDelegate) => true;
}

/// One diagonal band of light that crosses the logo card.
class _Sheen extends StatelessWidget {
  const _Sheen({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    // Band travels from fully left of the card to fully right.
    final x = -1.6 + 3.2 * progress;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(x - 0.5, -1),
          end: Alignment(x + 0.5, 1),
          colors: [
            AppColors.white.withValues(alpha: 0),
            AppColors.white.withValues(alpha: 0.55),
            AppColors.white.withValues(alpha: 0),
          ],
          stops: const [0.35, 0.5, 0.65],
        ),
      ),
    );
  }
}

class _AuthSplashError extends ConsumerWidget {
  const _AuthSplashError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.couldNotContinue,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: AppColors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: l10n.tryAgain,
            onPressed: () => ref.invalidate(currentUserProvider),
          ),
          const SizedBox(height: 8),
          const SignOutButton(),
        ],
      ),
    );
  }
}
