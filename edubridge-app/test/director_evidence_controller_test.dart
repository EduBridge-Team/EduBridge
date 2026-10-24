import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/schools/director_evidence.dart';
import 'package:edubridge_app/screens/school_directors/evidence/director_evidence_controller.dart';
import 'package:edubridge_app/services/schools/director_api_client.dart';

import 'director_evidence_fakes.dart';

void main() {
  test('cancelled picker never uploads or claims success', () async {
    final gateway = FakeDirectorEvidence();
    final controller = DirectorEvidenceController(gateway);
    addTearDown(controller.dispose);
    await controller.reload();
    await controller.pickAndUpload(
      DirectorDocumentKind.identity,
      (_) async => null,
    );
    expect(gateway.writes, 0);
    expect(controller.saved, isFalse);
    expect(controller.busy, isFalse);
  });
  test(
    'pending upload prevents repeated writes and review submission',
    () async {
      final gateway = FakeDirectorEvidence()..pendingWrite = Completer<void>();
      final controller = DirectorEvidenceController(gateway);
      addTearDown(controller.dispose);
      await controller.reload();
      final write = controller.pickAndUpload(
        DirectorDocumentKind.identity,
        (_) async => evidenceDraft(),
      );
      await Future<void>.delayed(Duration.zero);
      await controller.submit(70);
      await controller.pickAndUpload(
        DirectorDocumentKind.identity,
        (_) async => evidenceDraft(),
      );
      expect(gateway.writes, 1);
      gateway.pendingWrite!.complete();
      await write;
      expect(controller.saved, isTrue);
    },
  );
  test('confirmed upload and failed refresh do not replay upload', () async {
    final gateway = FakeDirectorEvidence()..failRefresh = true;
    final controller = DirectorEvidenceController(gateway);
    addTearDown(controller.dispose);
    await controller.reload();
    await controller.pickAndUpload(
      DirectorDocumentKind.identity,
      (_) async => evidenceDraft(),
    );
    expect(controller.saved, isTrue);
    expect(controller.evidence, isNull);
    gateway.failRefresh = false;
    await controller.reload();
    expect(gateway.writes, 1);
  });
  test('ambiguous upload requires reload before any other write', () async {
    final gateway = FakeDirectorEvidence()
      ..writeFailure = DirectorFailure.uncertain;
    final controller = DirectorEvidenceController(gateway);
    addTearDown(controller.dispose);
    await controller.reload();
    await controller.pickAndUpload(
      DirectorDocumentKind.identity,
      (_) async => evidenceDraft(),
    );
    expect(controller.evidence, isNull);
    expect(controller.saved, isFalse);
    await controller.submit(70);
    expect(gateway.writes, 1);
  });
  for (final status in [
    DirectorVerificationStatus.pending,
    DirectorVerificationStatus.approved,
  ]) {
    test(
      'identity referenced by $status cannot be removed or resubmitted',
      () async {
        final gateway = FakeDirectorEvidence()
          ..state = evidenceState(status: status);
        final controller = DirectorEvidenceController(gateway);
        addTearDown(controller.dispose);
        await controller.reload();
        await controller.remove(evidenceDocument);
        await controller.submit(70);
        expect(gateway.writes, 0);
      },
    );
  }
  test(
    'submission displays server pending state without local approval',
    () async {
      final gateway = FakeDirectorEvidence();
      final controller = DirectorEvidenceController(gateway);
      addTearDown(controller.dispose);
      await controller.reload();
      await controller.submit(70);
      expect(
        controller.evidence!.verification.status,
        DirectorVerificationStatus.pending,
      );
    },
  );
  test('opening obtains a fresh ticket on each user request', () async {
    final gateway = FakeDirectorEvidence();
    final controller = DirectorEvidenceController(gateway);
    addTearDown(controller.dispose);
    await controller.reload();
    var opens = 0;
    Future<bool> launch(Uri uri) async {
      opens++;
      return true;
    }

    await controller.open(evidenceDocument, launch);
    await controller.open(evidenceDocument, launch);
    expect(gateway.links, 2);
    expect(opens, 2);
    expect(gateway.writes, 0);
  });
  test('disposed screen ignores late read', () async {
    final gateway = FakeDirectorEvidence()
      ..pendingRead = Completer<DirectorEvidence>();
    final controller = DirectorEvidenceController(gateway);
    final read = controller.reload();
    controller.dispose();
    gateway.pendingRead!.complete(evidenceState());
    await read;
    expect(controller.evidence, isNull);
  });
}
