import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';

/// The employee who filed a trip request (`trip_requests.employee_id`).
///
/// Phone is the only contact shared with the driver. Fellow passengers
/// named in request notes are not represented here.
class TripRequester extends Equatable {
  const TripRequester({
    required this.id,
    required this.nameEn,
    this.nameAr,
    this.phone,
    this.branch,
  });

  final String id;
  final String nameEn;
  final String? nameAr;
  final String? phone;
  final Branch? branch;

  /// Name for the current UI language, falling back to the other script.
  String localizedName(String languageCode) {
    if (languageCode == 'ar') {
      final arabic = nameAr?.trim();
      if (arabic != null && arabic.isNotEmpty) return arabic;
    }
    final english = nameEn.trim();
    if (english.isNotEmpty) return english;
    final arabic = nameAr?.trim();
    if (arabic != null && arabic.isNotEmpty) return arabic;
    return nameEn;
  }

  @override
  List<Object?> get props => [id, nameEn, nameAr, phone, branch];
}
