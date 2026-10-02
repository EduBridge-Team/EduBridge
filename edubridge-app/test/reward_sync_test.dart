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
    // The first unacknowledged offline event keeps its original one-star payload.
    expect(batches, [1, 20, 4]);
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
    expect(jsonDecode((await SharedPreferences.getInstance()).getString('child_stars_queue_v2_0_10')!)['pending'], 25);
    expect(await service.getStars(10), 45);
    expect(stars, 45);
  });
  test('a lost successful response retries the same persisted event after restart', () async {
    var stars = 0;
    final receipts = <String, int>{};
    final ids = <String>[];
    Future<http.Response> post(String path, Map<String, dynamic> body) async {
      final id = body['event_id'] as String;
      ids.add(id);
      receipts.putIfAbsent(id, () { stars += body['count'] as int; return stars; });
      if (ids.length == 1) throw Exception('response lost after commit');
      return http.Response(jsonEncode({'stars': receipts[id]}), 200);
    }
    final service = RewardService(post: post);
    await service.addStar(10, count: 3);
    final restarted = RewardService(
      post: post, get: (_) async => http.Response(jsonEncode({'stars': stars}), 200),
    );
    expect(await restarted.getStars(10), 3);
    expect(ids.length, 2);
    expect(ids[0], ids[1]);
    expect(stars, 3);
    expect((await SharedPreferences.getInstance()).containsKey('child_stars_queue_v2_0_10'), isFalse);
  });

  test('pending rewards and offline cache belong to the signed-in account', () async {
    SharedPreferences.setMockInitialValues({'userId': 1});
    final service = RewardService(
      post: (_, body) async => http.Response('{}', 503),
      get: (_) async => http.Response('{}', 403),
    );
    await service.addStar(10, count: 3);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', 2);
    expect(await service.getStars(10), 0);
    expect(prefs.containsKey('child_stars_queue_v2_1_10'), isTrue);
  });

}
