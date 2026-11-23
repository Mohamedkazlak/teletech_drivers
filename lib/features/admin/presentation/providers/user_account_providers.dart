import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/features/admin/data/providers/user_account_repository_provider.dart';
import 'package:teletech_drivers/features/admin/domain/use_cases/reset_user_password.dart';
import 'package:teletech_drivers/features/admin/domain/use_cases/watch_user_accounts.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_bound_stream.dart';

final watchUserAccountsUseCaseProvider = Provider<WatchUserAccountsUseCase>((
  ref,
) {
  return WatchUserAccountsUseCase(ref.watch(userAccountRepositoryProvider));
});

final resetUserPasswordUseCaseProvider = Provider<ResetUserPasswordUseCase>((
  ref,
) {
  return ResetUserPasswordUseCase(ref.watch(userAccountRepositoryProvider));
});

/// Observer: every account for the system admin password-reset screen.
final allUserAccountsProvider = StreamProvider.autoDispose<List<AppUser>>((
  ref,
) {
  return authBoundStream(
    ref,
    whenSignedOut: const <AppUser>[],
    create: (_) => ref.watch(watchUserAccountsUseCaseProvider)(),
  );
}, retry: (_, _) => null);
