import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alexandria_ui/features/updates/data/github_release_source.dart';
import 'package:alexandria_ui/features/updates/domain/app_version.dart';
import 'package:alexandria_ui/features/updates/domain/update_ports.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reading the latest release over real HTTP, from a server on the loopback
/// (update-check design §2).
void main() {
  late HttpServer server;
  late void Function(HttpRequest request) handle;
  final requests = <HttpRequest>[];

  // The test binding answers every HttpClient with a 400; these tests are
  // about the real client against a real server on the loopback.
  HttpOverrides? overrides;
  setUpAll(() {
    overrides = HttpOverrides.current;
    HttpOverrides.global = null;
  });
  tearDownAll(() => HttpOverrides.global = overrides);

  setUp(() async {
    requests.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      requests.add(request);
      handle(request);
    });
  });

  tearDown(() => server.close(force: true));

  Uri url() => Uri.parse('http://127.0.0.1:${server.port}/releases/latest');

  GitHubReleaseSource source({Duration? timeout}) => GitHubReleaseSource(
    url: url(),
    appVersion: '1.1.0',
    timeout: timeout ?? const Duration(seconds: 10),
  );

  test(
    'GivenTheLatestRelease_WhenAsked_ThenItIsParsedAndHeadersSent',
    () async {
      handle = (request) {
        request.response
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'tag_name': 'v1.2.0',
              'body': 'notes',
              'html_url': 'https://example.test/r',
              'assets': <Object>[],
            }),
          );
        unawaited(request.response.close());
      };

      final release = await source().latest();

      expect(release.version, const AppVersion(1, 2, 0));
      expect(
        requests.single.headers.value(HttpHeaders.acceptHeader),
        'application/vnd.github+json',
      );
      expect(
        requests.single.headers.value(HttpHeaders.userAgentHeader),
        'Alexandria/1.1.0',
      );
    },
  );

  test('GivenA403RateLimit_WhenAsked_ThenUpdateCheckException', () async {
    handle = (request) {
      request.response.statusCode = HttpStatus.forbidden;
      unawaited(request.response.close());
    };

    await expectLater(source().latest(), throwsA(isA<UpdateCheckException>()));
  });

  test('GivenNonJson_WhenAsked_ThenUpdateCheckException', () async {
    handle = (request) {
      request.response.write('<html>not json</html>');
      unawaited(request.response.close());
    };

    await expectLater(source().latest(), throwsA(isA<UpdateCheckException>()));
  });

  test('GivenAnUnparseableTag_WhenAsked_ThenUpdateCheckException', () async {
    handle = (request) {
      request.response.write(jsonEncode({'tag_name': 'nightly'}));
      unawaited(request.response.close());
    };

    await expectLater(source().latest(), throwsA(isA<UpdateCheckException>()));
  });

  test('GivenNoAnswerInTime_WhenAsked_ThenUpdateCheckException', () async {
    // Never answered: the request is left open until the server closes.
    handle = (_) {};

    await expectLater(
      source(timeout: const Duration(milliseconds: 200)).latest(),
      throwsA(isA<UpdateCheckException>()),
    );
  });
}
