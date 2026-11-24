import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_gradients.dart';
import 'package:teletech_drivers/core/widgets/brand_mark.dart';

/// Curved brand gradient used on Login / Signup.
class AuthGradientHeader extends StatelessWidget {
  const AuthGradientHeader({this.heightFactor = 0.46, super.key});

  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * heightFactor;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipPath(
        clipper: const _EllipseBottomClipper(),
        child: const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.primary),
          child: RingField(opacity: 0.08, rings: 6),
        ),
      ),
    );
  }
}

class _EllipseBottomClipper extends CustomClipper<Path> {
  const _EllipseBottomClipper();

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.08,
        size.width,
        size.height * 0.78,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
