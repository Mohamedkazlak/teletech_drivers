/// Company office used on profiles, employees, and trip requests.
///
/// [wireValue] is the Laravel `Branch` enum (`company_headquarters`,
/// `new_headquarters`).
enum Branch {
  companyHeadquarters('company_headquarters'),
  newHeadquarters('new_headquarters');

  const Branch(this.wireValue);

  final String wireValue;

  static Branch? fromWire(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final branch in Branch.values) {
      if (branch.wireValue == value) return branch;
    }
    return null;
  }
}
