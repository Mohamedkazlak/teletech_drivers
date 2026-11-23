import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';

/// Opens the shared create-request form on the root navigator, or
/// complete-profile when branch/phone are missing.
void openNewTripRequest(BuildContext context, {required AppUser user}) {
  if (user.needsProfileCompletion) {
    context.push(AppRoutes.completeProfile);
    return;
  }
  context.push(AppRoutes.newTripRequestPath(user.role));
}
