import 'dart:async';

import 'package:dio/dio.dart';
import 'package:teletech_drivers/core/constants/polling_intervals.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/network/api_failure_mapper.dart';
import 'package:teletech_drivers/core/polling/polling_stream.dart';
import 'package:teletech_drivers/features/notification/data/datasources/notification_remote_data_source.dart';
import 'package:teletech_drivers/features/notification/domain/entities/app_notification.dart';
import 'package:teletech_drivers/features/notification/domain/entities/notification_page.dart';
import 'package:teletech_drivers/features/notification/domain/repositories/notification_repository.dart';

/// Repository: notification inbox with foreground polling.
class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository({
    required this.dataSource,
    this.failureMapper = const ApiFailureMapper(),
  });

  final NotificationRemoteDataSource dataSource;
  final ApiFailureMapper failureMapper;

  final _counts = <PollingStream<int>>[];
  final _inboxes = <PollingStream<NotificationPage>>[];
  var _perPage = 20;

  @override
  Stream<int> watchUnreadCount() {
    return _poll(
      into: _counts,
      fetch: (token) => dataSource.unreadCount(cancelToken: token),
    );
  }

  @override
  Stream<NotificationPage> watchInbox() {
    return _poll(
      into: _inboxes,
      fetch: (token) => dataSource.list(perPage: _perPage, cancelToken: token),
    );
  }

  /// The first fetch waits one turn so stopping the poll can cancel it before
  /// a network timer is armed. That keeps widget tests free of leftover timers
  /// and aborts the request when the bell leaves the tree.
  Stream<T> _poll<T>({
    required List<PollingStream<T>> into,
    required Future<T> Function(CancelToken token) fetch,
  }) {
    final token = CancelToken();
    Timer? deferred;
    Completer<T>? pending;
    final polling = PollingStream<T>(
      interval: PollingIntervals.notifications,
      onDispose: () {
        deferred?.cancel();
        deferred = null;
        if (!token.isCancelled) token.cancel();
        final waiting = pending;
        if (waiting != null && !waiting.isCompleted) {
          waiting.completeError(StateError('cancelled'));
        }
      },
      fetch: () {
        final result = Completer<T>();
        pending = result;
        deferred?.cancel();
        deferred = Timer(Duration.zero, () {
          if (token.isCancelled) {
            if (!result.isCompleted) {
              result.completeError(StateError('cancelled'));
            }
            return;
          }
          _guardValue(() => fetch(token)).then(
            (value) {
              if (!result.isCompleted) result.complete(value);
            },
            onError: (Object error, StackTrace stackTrace) {
              if (!result.isCompleted) {
                result.completeError(error, stackTrace);
              }
            },
          );
        });
        return result.future;
      },
    );
    into.add(polling);
    return polling.stream;
  }

  @override
  Future<AppNotification> markRead(String id) async {
    final updated = await _guardValue(() => dataSource.markRead(id));
    _refresh();
    return updated;
  }

  @override
  Future<int> markAllRead() async {
    final updated = await _guardValue(dataSource.markAllRead);
    _refresh();
    return updated;
  }

  @override
  void showMore() {
    if (_perPage >= 100) return;
    _perPage = _perPage + 20 > 100 ? 100 : _perPage + 20;
    _refresh();
  }

  @override
  void refresh() => _refresh();

  @override
  void dispose() {
    for (final stream in _counts) {
      stream.dispose();
    }
    for (final stream in _inboxes) {
      stream.dispose();
    }
    _counts.clear();
    _inboxes.clear();
  }

  void _refresh() {
    for (final stream in _counts) {
      stream.refresh();
    }
    for (final stream in _inboxes) {
      stream.refresh();
    }
  }

  Future<T> _guardValue<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(_toFailure(error), stackTrace);
    }
  }

  Failure _toFailure(Object error) => failureMapper.map(error);
}
