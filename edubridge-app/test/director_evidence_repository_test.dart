import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/config.dart';
import 'package:edubridge_app/model/schools/director_evidence.dart';
import 'package:edubridge_app/model/schools/school_director.dart';
import 'package:edubridge_app/services/schools/director_api_client.dart';
import 'package:edubridge_app/services/schools/director_evidence_repository.dart';
import 'package:edubridge_app/services/schools/director_multipart_transport.dart';

import 'director_evidence_fakes.dart';

const school = DirectorSchool(
  id: 10,
  name: 'School',
  organizationId: 4,
  organizationSlug: 'demo-institution',
);
String get path => '${school.path}/directors/30';
http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);
Matcher fails(DirectorFailure failure) => throwsA(
  isA<DirectorApiException>().having((e) => e.failure, 'failure', failure),
);
DirectorEvidenceRepository repository(
  DirectorApiClient client, {
  DateTime Function()? clock,
}) => DirectorEvidenceRepository(
  school: school,
  directorId: 30,
  client: client,
  clock: clock,
);

void main() {
  test(
    'upload posts bounded bytes and kind to director-scoped endpoint',
    () async {
      final repo = repository(
        DirectorApiClient(
          upload: (uri, fields, files) async {
            expect(uri, '$path/documents');
            expect(fields, {'kind': 'identity'});
            expect(files.single.field, 'file');
            expect(files.single.filename, 'identity.pdf');
            expect(
              await files.single.finalize().toBytes(),
              evidenceDraft().bytes,
            );
            return json({'document': documentJson()}, 201);
          },
        ),
      );
      await repo.upload(evidenceDraft());
    },
  );

  for (final name in [
    'identity.exe',
    '../identity.pdf',
    'identity.png',
    'bad\nname.pdf',
  ]) {
    test('unsafe or mismatched file is rejected without HTTP: $name', () async {
      var sent = false;
      final repo = repository(
        DirectorApiClient(
          upload: (uri, fields, files) async {
            sent = true;
            return json({}, 201);
          },
        ),
      );
      await expectLater(
        repo.upload(evidenceDraft(name: name)),
        fails(DirectorFailure.invalidFile),
      );
      expect(sent, isFalse);
    });
  }
  test('oversized and empty files are rejected', () {
    expect(
      DirectorDocumentDraft(
        kind: DirectorDocumentKind.identity,
        fileName: 'a.pdf',
        bytes: Uint8List(DirectorDocumentDraft.maxBytes + 1),
      ).isValid,
      isFalse,
    );
    expect(
      DirectorDocumentDraft(
        kind: DirectorDocumentKind.identity,
        fileName: 'a.pdf',
        bytes: Uint8List(0),
      ).isValid,
      isFalse,
    );
  });
  test('PNG and JPEG signatures match their extensions', () {
    expect(
      DirectorDocumentDraft(
        kind: DirectorDocumentKind.identity,
        fileName: 'a.PNG',
        bytes: Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
      ).isValid,
      isTrue,
    );
    expect(
      DirectorDocumentDraft(
        kind: DirectorDocumentKind.identity,
        fileName: 'a.jpeg',
        bytes: Uint8List.fromList([255, 216, 255, 0]),
      ).isValid,
      isTrue,
    );
  });

  test('upload success must match director, kind and byte count', () async {
    final repo = repository(
      DirectorApiClient(
        upload: (uri, fields, files) async => json({
          'document': {...documentJson(), 'director_id': 99},
        }, 201),
      ),
    );
    await expectLater(
      repo.upload(evidenceDraft()),
      fails(DirectorFailure.invalidResponse),
    );
  });

  test('load preserves honest not-submitted state', () async {
    final repo = repository(
      DirectorApiClient(
        get: (uri) async {
          expect(uri, '$path/evidence');
          return json(evidenceJson());
        },
      ),
    );
    expect(
      (await repo.load()).verification.status,
      DirectorVerificationStatus.notSubmitted,
    );
  });
  for (final data in [
    {...evidenceJson(), 'school_id': 20},
    {...evidenceJson(), 'director_id': 31},
    {
      ...evidenceJson(),
      'documents': [documentJson(), documentJson()],
    },
    {
      ...evidenceJson(),
      'documents': [
        {...documentJson(), 'director_id': 31},
      ],
    },
    {
      ...evidenceJson(),
      'verification': {'status': 'approved'},
    },
    {...evidenceJson(), 'verification': verificationJson('unsupported')},
    {
      ...evidenceJson(),
      'verification': {...verificationJson('rejected'), 'reason': ''},
    },
    {
      ...evidenceJson(),
      'documents': [],
      'verification': verificationJson('approved'),
    },
  ]) {
    test(
      'incomplete, foreign or inconsistent evidence is rejected: $data',
      () async {
        final repo = repository(
          DirectorApiClient(get: (uri) async => json(data)),
        );
        await expectLater(repo.load(), fails(DirectorFailure.invalidResponse));
      },
    );
  }

  test(
    'verification submission only confirms a scoped pending request',
    () async {
      final repo = repository(
        DirectorApiClient(
          post: (uri, body) async {
            expect(uri, '$path/verification');
            expect(body, {'identity_document_id': 70});
            return json({
              'school_id': 10,
              'director_id': 30,
              'verification': verificationJson('pending'),
            }, 201);
          },
        ),
      );
      await repo.submitVerification(70);
    },
  );
  test('submission cannot claim identity approved', () async {
    final repo = repository(
      DirectorApiClient(
        post: (uri, body) async => json({
          'school_id': 10,
          'director_id': 30,
          'verification': verificationJson('approved'),
        }, 201),
      ),
    );
    await expectLater(
      repo.submitVerification(70),
      fails(DirectorFailure.invalidResponse),
    );
  });
  test('delete validates explicit scoped confirmation', () async {
    final repo = repository(
      DirectorApiClient(
        delete: (uri) async {
          expect(uri, '$path/documents/70');
          return json({
            'school_id': 10,
            'director_id': 30,
            'document_id': 70,
            'deleted': true,
          });
        },
      ),
    );
    await repo.remove(evidenceDocument);
  });

  final now = DateTime.utc(2026, 10, 24, 20);
  Map<String, dynamic> link({String? url, DateTime? expiry}) {
    final end = expiry ?? now.add(const Duration(minutes: 1));
    return {
      'school_id': 10,
      'director_id': 30,
      'document_id': 70,
      'url':
          url ??
          '${Config.baseUrl}$path/documents/70/content?signature=abc&expires=${end.millisecondsSinceEpoch ~/ 1000}',
      'expires_at': end.toIso8601String(),
    };
  }

  test('download links must be freshly authorized and limited to scoped API content', () async {
    var calls = 0;
    final repo = repository(
      DirectorApiClient(
        get: (uri) async {
          calls++;
          expect(uri, '$path/documents/70/download-link');
          return json(link());
        },
      ),
      clock: () => now,
    );
    expect(
      (await repo.downloadLink(evidenceDocument)).host,
      'api.edubridge.win',
    );
    await repo.downloadLink(evidenceDocument);
    expect(calls, 2);
  });
  for (final data in [
    link(url: 'https://evil.example/content?signature=abc'),
    link(url: 'http://api.edubridge.win/api/content'),
    link(expiry: now.subtract(const Duration(seconds: 1))),
    link(expiry: now.add(const Duration(minutes: 6))),
    {...link(), 'document_id': 71},
    {...link(), 'school_id': 99},
    link(url: '${Config.baseUrl}$path/documents/71/content?signature=abc'),
    link(
      url:
          '${Config.baseUrl}$path/documents/70/content?signature=abc&expires=1',
    ),
    link(url: '${Config.baseUrl}$path/documents/70/content?token=secret'),
  ]) {
    test('unsafe download ticket is rejected: $data', () async {
      final repo = repository(
        DirectorApiClient(get: (uri) async => json(data)),
        clock: () => now,
      );
      await expectLater(
        repo.downloadLink(evidenceDocument),
        fails(DirectorFailure.invalidResponse),
      );
    });
  }

  test(
    'multipart uses current bearer without replacing the operator session',
    () async {
      var logouts = 0;
      final transport = DirectorMultipartTransport(
        token: () async => 'operator-token',
        logout: () async {
          logouts++;
        },
        send: (request) async {
          expect(request.headers['Authorization'], 'Bearer operator-token');
          expect(request.url.path, '/api$path/documents');
          expect((request as http.MultipartRequest).fields, {
            'kind': 'identity',
          });
          return http.StreamedResponse(Stream.value(utf8.encode('{}')), 201);
        },
      );
      await transport.upload('$path/documents', {'kind': 'identity'}, []);
      expect(logouts, 0);
    },
  );
  test('missing session never sends credentials or files', () async {
    var sends = 0;
    final transport = DirectorMultipartTransport(
      token: () async => null,
      send: (request) async {
        sends++;
        return http.StreamedResponse(const Stream.empty(), 201);
      },
    );
    expect((await transport.upload('$path/documents', {}, [])).statusCode, 401);
    expect(sends, 0);
  });
  test('late upload 401 cannot log out a newer session', () async {
    var token = 'old';
    var logouts = 0;
    final transport = DirectorMultipartTransport(
      token: () async => token,
      logout: () async {
        logouts++;
      },
      send: (request) async {
        token = 'new';
        return http.StreamedResponse(const Stream.empty(), 401);
      },
    );
    await transport.upload('$path/documents', {}, []);
    expect(logouts, 0);
  });
  test('upload 401 expires only the matching operator session', () async {
    var logouts = 0;
    final transport = DirectorMultipartTransport(
      token: () async => 'old',
      logout: () async {
        logouts++;
      },
      send: (request) async => http.StreamedResponse(const Stream.empty(), 401),
    );
    await transport.upload('$path/documents', {}, []);
    expect(logouts, 1);
  });
}
