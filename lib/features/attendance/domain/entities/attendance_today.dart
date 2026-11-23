import 'package:equatable/equatable.dart';

/// The signed-in driver's attendance for the current Cairo working day.
class AttendanceToday extends Equatable {
  const AttendanceToday({
    required this.workDate,
    required this.status,
    this.checkedInAt,
    this.checkedOutAt,
  });

  final String workDate;

  /// `not_checked_in`, `checked_in`, or `checked_out`.
  final String status;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;

  bool get isCheckedIn => status == 'checked_in';
  bool get isCheckedOut => status == 'checked_out';

  @override
  List<Object?> get props => [workDate, status, checkedInAt, checkedOutAt];
}
