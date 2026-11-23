import 'package:flutter/material.dart';

/// Progress indicator with a localized semantics label.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: const SizedBox.square(
        dimension: 36,
        child: CircularProgressIndicator(),
      ),
    );
  }
}
