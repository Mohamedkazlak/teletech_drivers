import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/onboarding/data/onboarding_store.dart';

/// Whether the signed-in user has already completed the first-run guide.
///
/// Loading, signed-out and error all read as "seen" so they never redirect.
final onboardingSeenProvider = FutureProvider<bool>((ref) async {
  final userId = ref.watch(currentUserProvider.select((u) => u.value?.id));
  if (userId == null) return true;
  return OnboardingStore.hasSeen(userId);
});

/// Marks the guide as seen for the signed-in user.
Future<void> completeOnboarding(WidgetRef ref) async {
  final userId = ref.read(currentUserProvider).value?.id;
  if (userId == null) return;
  await OnboardingStore.markSeen(userId);
  // Wait for the fresh value so the router never sees a stale "unseen".
  await ref.refresh(onboardingSeenProvider.future);
}
