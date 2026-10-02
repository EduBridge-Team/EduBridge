import 'dart:convert';
import 'package:edubridge_app/services/reward_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('more than 20 offline stars flush in bounded batches without losing pending rewards', () async {
    var online = false;
    var stars = 0;
    final batches = <int>[];
    final service = RewardService(
      get: (_) async => http.Response(jsonEncode({'stars': stars}), 200),
      post: (_, body) async {
        if (!online) return http.Response('{}', 503);
        final count = body['count'] as int;
        expect(count, inInclusiveRange(1, 20));
        batches.add(count);
        stars += count;
        return http.Response(jsonEncode({'stars': stars}), 200);
      },
    );
    await Future.wait(List.generate(25, (_) => service.addStar(10)));
    expect(await service.getStars(10), 25);
    online = true;
    expect(await service.getStars(10), 25);
    expect(batches, [20, 5]);
    expect(stars, 25);
    expect((await SharedPreferences.getInstance()).containsKey('child_stars_pending_10'), isFalse);
  });

  test('partial sync preserves only the unsent batch for the next retry', () async {
    SharedPreferences.setMockInitialValues({'child_stars_pending_10': 45, 'child_stars_10': 45});
    var stars = 0;
    var calls = 0;
    final service = RewardService(
      get: (_) async => http.Response(jsonEncode({'stars': stars}), 200),
      post: (_, body) async {
        if (++calls == 2) return http.Response('{}', 503);
        stars += body['count'] as int;
        return http.Response(jsonEncode({'stars': stars}), 200);
      },
    );
    expect(await service.getStars(10), 45);
    expect((await SharedPreferences.getInstance()).getInt('child_stars_pending_10'), 25);
    expect(await service.getStars(10), 45);
    expect(stars, 45);
  });
}
