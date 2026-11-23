import 'package:equatable/equatable.dart';

/// Sensitive driver documents stored under users/{id}/private/profile.
class DriverPrivateProfile extends Equatable {
  const DriverPrivateProfile({
    required this.nationalId,
    required this.carLicense,
    required this.personalLicense,
  });

  final String nationalId;
  final String carLicense;
  final String personalLicense;

  /// Egypt national ID is 14 digits; show first 3 and last 2 only.
  String get maskedNationalId {
    final digits = nationalId.trim();
    if (digits.length < 6) return '••••';
    final prefix = digits.substring(0, 3);
    final suffix = digits.substring(digits.length - 2);
    return '$prefix••••••$suffix';
  }

  @override
  List<Object?> get props => [nationalId, carLicense, personalLicense];
}
