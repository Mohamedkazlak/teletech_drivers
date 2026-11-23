/// Drivers list filter: open check-in today, or no open check-in.
enum DriverAttendanceFilter {
  checkedIn,
  notCheckedIn;

  String get apiValue => switch (this) {
    DriverAttendanceFilter.checkedIn => 'checked_in',
    DriverAttendanceFilter.notCheckedIn => 'not_checked_in',
  };
}
