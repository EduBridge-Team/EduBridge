import 'dart:async';

import 'package:edubridge_app/screens/iep/iep_draft_save_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'iep_draft_save_fixture.dart';

void main() {
  test('save serializes, confirms once and remains non-repeatable after refresh', () async {
    final f = IepDraftSaveFixture()..pendingPost = Completer<void>();
    final controller = IepDraftSaveController(saveDraft(), f.repository);
    addTearDown(controller.dispose);
    await controller.reload();
    final first = controller.create(controller.snapshot!);
    await Future<void>.delayed(Duration.zero);
    expect(controller.busy, isTrue);
    await controller.create(controller.snapshot!);
    expect(f.posts, hasLength(1));
    expect(f.posts.single['request_key'], matches(RegExp(r'^[a-f0-9]{32}$')));
    f.pendingPost!.complete();
    await first;
    expect(controller.receipt?.version.id, 103);
    await controller.reload();
    await controller.create(controller.snapshot!);
    expect(f.posts, hasLength(1));
  });
  test('uncertain result remains blocked after read-only refresh', () async {
    final f = IepDraftSaveFixture()..failConfirmation = true;
    final controller = IepDraftSaveController(saveDraft(), f.repository);
    addTearDown(controller.dispose);
    await controller.reload();
    await controller.create(controller.snapshot!);
    expect(controller.needsReview, isTrue);
    expect(controller.receipt, isNull);
    await controller.reload();
    expect(controller.canCreate, isFalse);
    await controller.create(controller.snapshot!);
    expect(f.posts, hasLength(1));
  });
  test('refreshed authorization invalidates an old confirmation snapshot', () async {
    final f = IepDraftSaveFixture();
    final controller = IepDraftSaveController(saveDraft(), f.repository);
    addTearDown(controller.dispose);
    await controller.reload();
    final old = controller.snapshot!;
    await controller.reload();
    await controller.create(old);
    expect(f.posts, isEmpty);
  });
}
