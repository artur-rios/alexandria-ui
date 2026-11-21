import 'dart:async';
import 'dart:io';

import 'package:alexandria_ui/features/updates/data/http_downloader.dart';
import 'package:alexandria_ui/features/updates/domain/update_ports.dart';
import 'package:flutter_test/flutter_test.dart';

/// Downloading a package over real HTTP (update-check design §3).
void main() {
  late HttpServer server;
  late Future<void> Function(HttpRequest request) handle;
  late Directory folder;

  // The test binding answers every HttpClient with a 400; these tests are
  // about the real client against a real server on the loopback.
  HttpOverrides? overrides;
  setUpAll(() {
    overrides = HttpOverrides.current;
    HttpOverrides.global = null;
  });
  tearDownAll(() => HttpOverrides.global = overrides);

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('alexandria_dl');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) => unawaited(handle(request)));
  });

  tearDown(() async {
    await server.close(force: true);
    if (folder.existsSync()) folder.deleteSync(recursive: true);
  });

  Uri url() => Uri.parse('http://127.0.0.1:${server.port}/package');

  test(
    'GivenABody_WhenDownloaded_ThenTheFileHoldsItAndProgressReachesTotal',
    () async {
      final body = List<int>.generate(300000, (i) => i % 251);
      handle = (request) async {
        request.response.contentLength = body.length;
        request.response.add(body);
        await request.response.close();
      };
      final progress = <(int, int)>[];

      final file = await HttpDownloader().download(
        url(),
        File('${folder.path}/package'),
        onProgress: (received, total) => progress.add((received, total)),
      );

      expect(file.readAsBytesSync(), body);
      expect(progress.last, (body.length, body.length));
    },
  );

  test(
    'GivenACutOffBody_WhenDownloaded_ThenThePartialFileIsDeletedAndItThrows',
    () async {
      handle = (request) async {
        // Promises more than it sends, then hangs up: a connection reset
        // halfway through.
        request.response.contentLength = 1000;
        final socket = await request.response.detachSocket();
        socket.add(List<int>.filled(10, 1));
        await socket.flush();
        socket.destroy();
      };
      final target = File('${folder.path}/package');

      await expectLater(
        HttpDownloader().download(url(), target),
        throwsA(anything),
      );
      expect(target.existsSync(), isFalse);
    },
  );

  test('GivenACancel_WhenMidDownload_ThenThePartialFileIsDeleted', () async {
    final cancel = CancelToken();
    handle = (request) async {
      request.response.contentLength = 2000000;
      request.response.add(List<int>.filled(1000, 1));
      await request.response.flush();
      cancel.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      request.response.add(List<int>.filled(1000, 1));
      await request.response.flush();
    };
    final target = File('${folder.path}/package');

    await expectLater(
      HttpDownloader().download(url(), target, cancel: cancel),
      throwsA(anything),
    );
    expect(target.existsSync(), isFalse);
  });

  test(
    'GivenAnHttpError_WhenDownloaded_ThenItThrowsAndWritesNothing',
    () async {
      handle = (request) async {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      };
      final target = File('${folder.path}/package');

      await expectLater(
        HttpDownloader().download(url(), target),
        throwsA(anything),
      );
      expect(target.existsSync(), isFalse);
    },
  );

  test('GivenAFile_WhenHashed_ThenItsSha256', () async {
    final file = File('${folder.path}/abc')..writeAsStringSync('abc');

    expect(
      await HttpDownloader().sha256Of(file),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });
}
