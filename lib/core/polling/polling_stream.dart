import 'dart:async';

import 'package:flutter/widgets.dart';

/// Emits [fetch] immediately, then on [interval], pausing while backgrounded.
///
/// Overlapping fetches are skipped. Cancel the subscription (or call [dispose])
/// to stop timers and detach the lifecycle observer.
final class PollingStream<T> with WidgetsBindingObserver {
  PollingStream({
    required this._fetch,
    required this._interval,
    this.onDispose,
    WidgetsBinding? binding,
    bool startInForeground = true,
  }) : _binding = binding ?? WidgetsBinding.instance,
       _isInForeground = startInForeground {
    _binding.addObserver(this);
    _controller = StreamController<T>.broadcast(
      onListen: _onListen,
      onCancel: _onCancel,
    );
  }

  final Future<T> Function() _fetch;
  final Duration _interval;

  /// Runs once when the poll stops, before the controller closes.
  final void Function()? onDispose;

  final WidgetsBinding _binding;

  late final StreamController<T> _controller;
  Timer? _timer;
  var _isInForeground = true;
  var _fetchInFlight = false;
  var _refreshQueued = false;
  var _disposed = false;
  var _started = false;

  /// Fetches again now. A fetch already in flight runs one more time after it
  /// finishes, so a mark-read is not lost behind the in-flight poll.
  void refresh() {
    if (_disposed) return;
    if (_fetchInFlight) {
      _refreshQueued = true;
      return;
    }
    unawaited(_runFetch());
  }

  Stream<T> get stream => _controller.stream;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    if (foreground == _isInForeground) return;
    _isInForeground = foreground;
    if (_isInForeground) {
      unawaited(_runFetch());
      _armTimer();
    } else {
      _cancelTimer();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelTimer();
    onDispose?.call();
    _binding.removeObserver(this);
    unawaited(_controller.close());
  }

  void _onListen() {
    if (_disposed || _started) return;
    _started = true;
    unawaited(_runFetch());
    if (_isInForeground) {
      _armTimer();
    }
  }

  void _onCancel() {
    // autoDispose StreamProviders cancel when the last listener leaves.
    dispose();
  }

  void _armTimer() {
    _cancelTimer();
    if (_disposed || !_isInForeground) return;
    _timer = Timer.periodic(_interval, (_) {
      unawaited(_runFetch());
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _runFetch() async {
    if (_disposed || _fetchInFlight || !_isInForeground) return;
    _fetchInFlight = true;
    try {
      final value = await _fetch();
      if (_disposed || _controller.isClosed) return;
      _controller.add(value);
    } catch (error, stackTrace) {
      if (_disposed || _controller.isClosed) return;
      _controller.addError(error, stackTrace);
    } finally {
      _fetchInFlight = false;
      if (_refreshQueued && !_disposed && _isInForeground) {
        _refreshQueued = false;
        unawaited(_runFetch());
      }
    }
  }
}
