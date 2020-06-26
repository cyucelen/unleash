import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:unleash/unleash.dart';

import 'test_utils.dart';

void main() {
  test('Unleash.init throws assertion error', () {
    expect(Unleash.init(null), throwsAssertionError);
  });

  test('Unleash.init happy path', () async {
    final unleash = await Unleash.init(
      UnleashSettings(
        appName: 'test_app_name',
        instanceId: 'instance_id',
        unleashApi: Uri.parse('http://example.org/api'),
        pollingInterval: null,
      ),
      client: MockClient(happyMock),
    );

    expect(unleash.isEnabled('Demo'), true);
    expect(unleash.isEnabled('tasty-testy'), false);
    expect(unleash.isEnabled('foo'), true);
  });

  test('Unleash.isEnabled use default value', () async {
    final unleash = await Unleash.init(
      UnleashSettings(
          appName: 'test_app_name',
          instanceId: 'instance_id',
          unleashApi: Uri.parse('http://example.org/api')),
      client: MockClient(happyMock),
    );

    expect(unleash.isEnabled('foobar'), false);
    expect(unleash.isEnabled('foobar', defaultValue: true), true);
    expect(unleash.isEnabled('foobar', defaultValue: false), false);
  });
}

/// This mock handler only sends valid responses.
/// Used to test the happy path.
Future<Response> happyMock(Request request) {
  final registerUri = Uri.parse('http://example.org/api/client/register');
  final featuresUri = Uri.parse('http://example.org/api/client/features');

  if (request.url == registerUri) {
    // HTTP method
    expect(request.method, 'POST');

    // body
    final body = json.decode(request.body) as Map;
    expect(body.length, 6);
    expect(body['appName'], 'test_app_name');
    expect(body['instanceId'], 'instance_id');
    expect(body.containsKey('sdkVersion'), true);
    expect(body['strategies'], null);
    expect(body.containsKey('started'), true);
    expect(body['interval'], 10000);

    return Future.value(Response('', 200));
  }

  if (request.url == featuresUri) {
    expect(request.method, 'GET');

    // headers as per https://unleash.github.io/docs/api/client/features
    expect(
      request.headers,
      <String, String>{
        'UNLEASH-APPNAME': 'test_app_name',
        'UNLEASH-INSTANCEID': 'instance_id',
      },
    );

    return Future.value(Response(testFeatureToggleJson, 200));
  }
  return null;
}
