import 'dart:async';
import 'package:edubridge_app/features/communication/presentation/communication_list_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('late request cannot replace newer conversation results', () async {
    final first = Completer<List<dynamic>>();
    final second = Completer<List<dynamic>>();
    var calls = 0;
    final controller = CommunicationListController(
      load: () => ++calls == 1 ? first.future : second.future, errorMessage: 'error');
    addTearDown(controller.dispose);
    final old = controller.reload();
    final current = controller.reload();
    second.complete([2]);
    expect(await current, true);
    first.complete([1]);
    expect(await old, false);
    expect(controller.items, [2]);
  });
  test('obsolete failure cannot overwrite a newer success', () async {
    final first = Completer<List<dynamic>>();
    var calls = 0;
    final controller = CommunicationListController(
      load: () => ++calls == 1 ? first.future : Future.value([2]), errorMessage: 'error');
    addTearDown(controller.dispose);
    final old = controller.reload();
    await controller.reload();
    first.completeError(Exception('offline'));
    await old;
    expect(controller.error, isNull);
    expect(controller.items, [2]);
  });
  test('refresh failure keeps existing rows and supports retry', () async {
    var fail = false;
    final controller = CommunicationListController(
      load: () async { if (fail) throw Exception(); return [1]; }, errorMessage: 'تعذّر التحميل');
    addTearDown(controller.dispose);
    await controller.reload();
    fail = true;
    final pending = controller.reload(showLoader: false);
    expect(controller.loading, false);
    expect(await pending, false);
    expect(controller.items, [1]);
    expect(controller.error, 'تعذّر التحميل');
    fail = false;
    expect(await controller.reload(), true);
    expect(controller.error, isNull);
  });
  test('disposed request publishes nothing and cannot start another load', () async {
    final response = Completer<List<dynamic>>();
    var calls = 0;
    var updates = 0;
    final controller = CommunicationListController(
      load: () { calls++; return response.future; }, errorMessage: 'error');
    controller.addListener(() => updates++);
    final pending = controller.reload();
    controller.dispose();
    response.complete([1]);
    expect(await pending, false);
    expect(updates, 1);
    expect(controller.items, isEmpty);
    expect(await controller.reload(), false);
    expect(calls, 1);
  });


  test('a disposed controller ignores a failed in-flight request', () async {
    final request = Completer<List<dynamic>>();
    final controller = CommunicationListController(
      load: () => request.future,
      errorMessage: 'offline',
    );
    var notifications = 0;
    controller.addListener(() => notifications++);

    final pending = controller.reload();
    controller.dispose();
    request.completeError(Exception('offline'));

    expect(await pending, false);
    expect(notifications, 1);
    expect(controller.error, isNull);
    expect(controller.loading, true);
    expect(controller.items, isEmpty);
  });

  test('older success does not replace the newer error state', () async {
    final oldRequest = Completer<List<dynamic>>();
    final newRequest = Completer<List<dynamic>>();
    var callCount = 0;
    final controller = CommunicationListController(
      load: () => ++callCount == 1 ? oldRequest.future : newRequest.future,
      errorMessage: 'offline',
    );
    addTearDown(controller.dispose);

    final older = controller.reload();
    final newer = controller.reload(showLoader: false);
    newRequest.completeError(Exception('offline'));
    expect(await newer, false);
    oldRequest.complete([1]);
    expect(await older, false);
    expect(controller.items, isEmpty);
    expect(controller.error, 'offline');
    expect(controller.loading, false);
  });
}
