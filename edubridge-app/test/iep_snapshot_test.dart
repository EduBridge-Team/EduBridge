import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/iep/iep_snapshot.dart';

void main() {
  test(
      'nested numeric measurements compare by value, while authored order stays exact',
      () {
    expect(
        iepSnapshotFingerprint({
          'goals': [2, -0.0, 2.5]
        }),
        iepSnapshotFingerprint({
          'goals': [2.0, 0, 2.5]
        }));
    expect(
        iepSnapshotFingerprint({
          'goals': [2, 3]
        }),
        isNot(iepSnapshotFingerprint({
          'goals': [3, 2]
        })));
  });
  test('large integers never lose precision or clamp during snapshot encoding',
      () {
    expect(iepSnapshotFingerprint(9007199254740993),
        isNot(iepSnapshotFingerprint(9007199254740992.0)));
    expect(iepSnapshotFingerprint(9223372036854775807),
        isNot(iepSnapshotFingerprint(9223372036854775808.0)));
    expect(iepSnapshotFingerprint(-9223372036854775808),
        iepSnapshotFingerprint(-9223372036854775808.0));
  });
}
