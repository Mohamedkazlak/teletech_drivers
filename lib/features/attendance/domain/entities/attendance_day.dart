import 'package:equatable/equatable.dart';

/// One working day in an attendance history, including computed absences.
class AttendanceDay extends Equatable {
  const AttendanceDay({
    required this.driverId,
    required this.workDate,
    required this.status,
    this.driverNameEn,
    this.driverNameAr,
    this.checkedInAt,
    this.checkedOutAt,
    this.onSiteHours,
    this.checkInDistanceM,
    this.source,
    this.adjustmentReason,
  });

  final String driverId;
  final String? driverNameEn;
  final String? driverNameAr;
  final String workDate;
  final String status;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final double? onSiteHours;
  final int? checkInDistanceM;
  final String? source;
  final String? adjustmentReason;

  bool get isAbsent => status == 'absent';

  String localizedName(String languageCode) {
    if (languageCode == 'ar') {
      final ar = driverNameAr?.trim();
      if (ar != null && ar.isNotEmpty) return ar;
    }
    final en = driverNameEn?.trim();
    if (en != null && en.isNotEmpty) return en;
    return driverNameAr?.trim() ?? driverId;
  }

  @override
  List<Object?> get props => [
    driverId,
    workDate,
    status,
    checkedInAt,
    checkedOutAt,
    onSiteHours,
  ];
}

class AttendanceTotals extends Equatable {
  const AttendanceTotals({
    required this.daysPresent,
    required this.daysAbsent,
    required this.totalOnSiteHours,
  });

  final int daysPresent;
  final int daysAbsent;
  final double totalOnSiteHours;

  @override
  List<Object?> get props => [daysPresent, daysAbsent, totalOnSiteHours];
}

class AttendanceHistory extends Equatable {
  const AttendanceHistory({required this.days, required this.totals});

  final List<AttendanceDay> days;
  final AttendanceTotals totals;

  @override
  List<Object?> get props => [days, totals];
}
