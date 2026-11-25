import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// A track the user slides a thumb across to confirm an action.
///
/// Harder to trigger by accident than a button (useful in a moving car),
/// and the drag itself feels deliberate. Follows text direction, so in
/// Arabic the thumb slides right-to-left. Screen readers get a plain
/// button with the same [label].
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    required this.label,
    required this.onConfirmed,
    this.icon = Icons.arrow_forward_rounded,
    this.isLoading = false,
    this.enabled = true,
    this.doneLabel,
    this.doneIcon = Icons.task_alt_rounded,
    this.onDark = true,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onConfirmed;
  final bool isLoading;
  final bool enabled;

  /// Shown instead of the track when [enabled] is false.
  final String? doneLabel;
  final IconData doneIcon;

  /// Styled for a navy hero surface when true, for a white card when false.
  final bool onDark;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm>
    with TickerProviderStateMixin {
  static const double _height = 58;
  static const double _pad = 5;
  static const double _threshold = 0.82;

  late final AnimationController _position = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
  );
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  double _maxTravel = 1;
  bool _armed = false;
  bool _confirmed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncShimmer();
  }

  @override
  void didUpdateWidget(SlideToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Action finished: slide the thumb home.
    if (oldWidget.isLoading && !widget.isLoading) _reset();
    _syncShimmer();
  }

  void _syncShimmer() {
    final run =
        widget.enabled &&
        !widget.isLoading &&
        !AppAnimations.disabled(context);
    if (run && !_shimmer.isAnimating) {
      _shimmer.repeat();
    } else if (!run && _shimmer.isAnimating) {
      _shimmer.stop();
    }
  }

  void _reset() {
    _confirmed = false;
    _armed = false;
    _position.animateTo(
      0,
      duration: AppMotion.emphasized,
      curve: AppMotion.easeOut,
    );
  }

  void _onDragUpdate(DragUpdateDetails details, bool rtl) {
    if (!_canDrag) return;
    final delta = (rtl ? -details.delta.dx : details.delta.dx) / _maxTravel;
    _position.value = (_position.value + delta).clamp(0.0, 1.0);
    final armed = _position.value >= _threshold;
    if (armed != _armed) {
      _armed = armed;
      HapticFeedback.selectionClick();
    }
  }

  void _onDragEnd(DragEndDetails details, bool rtl) {
    if (!_canDrag) return;
    final velocity = (rtl ? -1 : 1) * details.velocity.pixelsPerSecond.dx;
    if (_position.value >= _threshold || velocity > 1400) {
      _confirm();
    } else {
      _reset();
    }
  }

  Future<void> _confirm() async {
    if (_confirmed) return;
    _confirmed = true;
    HapticFeedback.heavyImpact();
    await _position.animateTo(
      1,
      duration: AppMotion.quick,
      curve: AppMotion.easeOut,
    );
    widget.onConfirmed();
    // If the action didn't go into a loading state, return on our own.
    if (mounted && !widget.isLoading) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (mounted && !widget.isLoading) _reset();
    }
  }

  bool get _canDrag => widget.enabled && !widget.isLoading && !_confirmed;

  @override
  void dispose() {
    _position.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final onDark = widget.onDark;
    final trackColor = onDark
        ? AppColors.white.withValues(alpha: 0.12)
        : AppColors.paleBlue;
    final fillColor = onDark
        ? AppColors.white.withValues(alpha: 0.16)
        : AppColors.deepBlue.withValues(alpha: 0.12);
    final labelColor = onDark ? AppColors.white : AppColors.navy;
    final thumbColor = onDark ? AppColors.white : AppColors.deepBlue;
    final thumbIconColor = onDark ? AppColors.navy : AppColors.white;

    if (!widget.enabled && !widget.isLoading) {
      return Container(
        height: _height,
        decoration: ShapeDecoration(
          color: trackColor,
          shape: const StadiumBorder(),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.doneIcon,
              size: 20,
              color: labelColor.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.doneLabel ?? widget.label,
                textAlign: TextAlign.center,
                style: textTheme.titleSmall?.copyWith(
                  color: labelColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: _canDrag,
      label: widget.label,
      onTap: _canDrag ? _confirm : null,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const thumb = _height - _pad * 2;
          _maxTravel = (constraints.maxWidth - thumb - _pad * 2).clamp(
            1.0,
            double.infinity,
          );
          return GestureDetector(
            onHorizontalDragUpdate: (d) => _onDragUpdate(d, rtl),
            onHorizontalDragEnd: (d) => _onDragEnd(d, rtl),
            child: AnimatedBuilder(
              animation: Listenable.merge([_position, _shimmer]),
              builder: (context, _) {
                final p = _position.value;
                final offset = _maxTravel * p;
                return Container(
                  height: _height,
                  decoration: ShapeDecoration(
                    color: trackColor,
                    shape: const StadiumBorder(),
                  ),
                  child: Stack(
                    children: [
                      // Fill that trails the thumb.
                      PositionedDirectional(
                        start: _pad,
                        top: _pad,
                        bottom: _pad,
                        width: thumb + offset,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: fillColor,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                      // Label with a light sweep that hints "slide me".
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: thumb + 16,
                            end: 16,
                          ),
                          child: Center(
                            child: Opacity(
                              opacity: (1 - p * 1.6).clamp(0.0, 1.0),
                              child: ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (rect) {
                                  final s = _shimmer.value * 2 - 0.5;
                                  final a = labelColor.withValues(alpha: 0.6);
                                  return LinearGradient(
                                    begin: rtl
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    end: rtl
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    colors: [a, labelColor, a],
                                    stops: [
                                      (s - 0.25).clamp(0.0, 1.0),
                                      s.clamp(0.0, 1.0),
                                      (s + 0.25).clamp(0.0, 1.0),
                                    ],
                                  ).createShader(rect);
                                },
                                child: Text(
                                  widget.label,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleSmall?.copyWith(
                                    color: labelColor,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        start: _pad + offset,
                        top: _pad,
                        child: Container(
                          width: thumb,
                          height: thumb,
                          decoration: BoxDecoration(
                            color: thumbColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.navyDeep.withValues(
                                  alpha: 0.18,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: widget.isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    strokeCap: StrokeCap.round,
                                    color: thumbIconColor,
                                  ),
                                )
                              : Transform.flip(
                                  flipX: rtl,
                                  child: Icon(
                                    p >= _threshold
                                        ? Icons.check_rounded
                                        : widget.icon,
                                    color: thumbIconColor,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
