import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/polling/polling_stream.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('emits immediately then on interval', () {
    fakeAsync((async) {
      var calls = 0;
      final polling = PollingStream<int>(
        interval: const Duration(seconds: 5),
        fetch: () async => ++calls,
      );
      final values = <int>[];
      final sub = polling.stream.listen(values.add);

      async.flushMicrotasks();
      expect(values, [1]);

      async.elapse(const Duration(seconds: 5));
      async.flushMicrotasks();
      expect(values, [1, 2]);

      sub.cancel();
      polling.dispose();
    });
  });

  test('skips overlapping fetches', () {
    fakeAsync((async) {
      final started = Completer<void>();
      final release = Completer<void>();
      var calls = 0;
      final polling = PollingStream<int>(
        interval: const Duration(seconds: 1),
        fetch: () async {
          calls += 1;
          if (calls == 1) {
            started.complete();
            await release.future;
          }
          return calls;
        },
      );
      final values = <int>[];
      polling.stream.listen(values.add);

      async.flushMicrotasks();
      expect(started.isCompleted, isTrue);

      async.elapse(const Duration(seconds: 3));
      expect(calls, 1);

      release.complete();
      async.flushMicrotasks();
      expect(values, [1]);

      polling.dispose();
    });
  });

  test('pauses in background and resumes', () {
    fakeAsync((async) {
      var calls = 0;
      final polling = PollingStream<int>(
        interval: const Duration(seconds: 2),
        fetch: () async => ++calls,
      );
      final values = <int>[];
      polling.stream.listen(values.add);
      async.flushMicrotasks();
      expect(values, [1]);

      polling.didChangeAppLifecycleState(AppLifecycleState.paused);
      async.elapse(const Duration(seconds: 6));
      async.flushMicrotasks();
      expect(values, [1]);

      polling.didChangeAppLifecycleState(AppLifecycleState.resumed);
      async.flushMicrotasks();
      expect(values, [1, 2]);

      polling.dispose();
    });
  });

  test('cancel/dispose stops further emits', () {
    fakeAsync((async) {
      var calls = 0;
      final polling = PollingStream<int>(
        interval: const Duration(seconds: 1),
        fetch: () async => ++calls,
      );
      final sub = polling.stream.listen((_) {});
      async.flushMicrotasks();
      expect(calls, 1);

      sub.cancel();
      polling.dispose();
      async.elapse(const Duration(seconds: 5));
      async.flushMicrotasks();
      expect(calls, 1);
    });
  });
}
