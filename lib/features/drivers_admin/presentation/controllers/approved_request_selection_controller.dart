import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which approved request ids are selected for trip creation.
final approvedRequestSelectionProvider =
    NotifierProvider.autoDispose<
      ApprovedRequestSelectionController,
      Set<String>
    >(ApprovedRequestSelectionController.new);

class ApprovedRequestSelectionController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String requestId) {
    final next = Set<String>.from(state);
    if (!next.add(requestId)) {
      next.remove(requestId);
    }
    state = next;
  }

  void selectAll(Iterable<String> requestIds) {
    state = {...state, ...requestIds};
  }

  void deselectAll(Iterable<String> requestIds) {
    final remove = requestIds.toSet();
    state = state.difference(remove);
  }

  void clear() => state = const {};

  /// Drops ids that are no longer in the approved-awaiting queue.
  void retainOnly(Iterable<String> validIds) {
    final valid = validIds.toSet();
    final next = state.intersection(valid);
    if (next.length != state.length) {
      state = next;
    }
  }
}
