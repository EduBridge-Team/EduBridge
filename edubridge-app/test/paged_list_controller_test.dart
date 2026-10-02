import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/services/list_page.dart';
import 'package:edubridge_app/services/paged_list_controller.dart';

ListPage page(int number, List<int> ids) => ListPage(items: ids.map((id) => {'id': id}).toList(), page: number, total: 60, lastPage: 2);

void main() {
  test('page navigation replaces the current page without loading the whole directory', () async {
    final calls = <int>[];
    final controller = PagedListController((number, query) async {
      calls.add(number);
      return page(number, [number]);
    });
    await controller.load();
    await controller.load(2);
    expect(calls, [1, 2]);
    expect(controller.items.single['id'], 2);
    expect(controller.total, 60);
    controller.dispose();
  });

  test('obsolete query results cannot overwrite a newer search', () async {
    final old = Completer<ListPage>();
    final controller = PagedListController((number, query) async {
      if (query == 'new') return page(number, [2]);
      return await old.future;
    });
    final first = controller.load();
    controller.search('new');
    await controller.load();
    old.complete(page(1, [1]));
    await first;
    expect(controller.items.single['id'], 2);
    expect(controller.query, 'new');
    controller.dispose();
  });

  test('failed next page keeps current page and permits a retry', () async {
    var fail = true;
    final controller = PagedListController((number, query) async {
      if (number == 2 && fail) throw Exception('offline');
      return page(number, [number]);
    });
    await controller.load();
    await controller.load(2);
    expect(controller.page, 1);
    expect(controller.items.single['id'], 1);
    expect(controller.error, isNotNull);
    fail = false;
    await controller.load(2);
    expect(controller.page, 2);
    expect(controller.error, isNull);
    controller.dispose();
  });

  test('disposing during a request invalidates its response', () async {
    final pending = Completer<ListPage>();
    final controller = PagedListController((number, query) => pending.future);
    final load = controller.load();
    controller.dispose();
    pending.complete(page(1, [1]));
    await load;
    expect(controller.items, isEmpty);
  });

  test('search resets a later page and debounce submits the final text only', () async {
    final calls = <String>[];
    final controller = PagedListController((number, query) async {
      calls.add('$number:$query');
      return page(number, [number]);
    });
    await controller.load(2);
    controller.search('old');
    controller.search('final');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(calls, ['2:', '1:final']);
    expect(controller.page, 1);
    controller.dispose();
  });

  test('malformed metadata is rejected before replacing the current page', () {
    expect(() => ListPage.fromJson({'children': []}, 'children'), throwsFormatException);
    final parsed = ListPage.fromJson({'children': [], 'pagination': {'page': 5, 'total': 120, 'last_page': 4}}, 'children');
    expect(parsed.page, 5);
    expect(parsed.total, 120);
  });
}
