import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../domain/update_ports.dart';

/// [Downloader] over `dart:io`'s client (update-check design §3).
///
/// Streams straight to disk — a package is a few hundred megabytes — and
/// deletes what it wrote on any failure, so a half-written file can never be
/// mistaken for a package.
class HttpDownloader implements Downloader {
  /// Creates the downloader.
  HttpDownloader({HttpClient Function()? client})
    : _client = client ?? HttpClient.new;

  final HttpClient Function() _client;

  @override
  Future<File> download(
    Uri url,
    File to, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancel,
  }) async {
    final client = _client();
    IOSink? sink;
    try {
      final request = await client.getUrl(url);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('status ${response.statusCode}', uri: url);
      }

      final total = response.contentLength;
      var received = 0;
      final output = sink = to.openWrite();
      final done = Completer<void>();
      final subscription = response.listen(
        (chunk) {
          output.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
        },
        onError: (Object error, StackTrace stack) {
          if (!done.isCompleted) done.completeError(error, stack);
        },
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
        cancelOnError: true,
      );
      // Cancelling stops the download where it is, even on a connection that
      // has stalled and would never deliver the chunk a check would wait for.
      unawaited(
        cancel?.whenCancelled.then((_) async {
          if (done.isCompleted) return;
          await subscription.cancel();
          done.completeError(const HttpException('cancelled'));
        }),
      );
      await done.future;
      await output.close();
      sink = null;

      // A body that ends short of what it promised is a cut connection.
      if (total >= 0 && received != total) {
        throw HttpException('received $received of $total bytes', uri: url);
      }
      return to;
    } on Object {
      await sink?.close().catchError((_) {});
      if (to.existsSync()) to.deleteSync();
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<String> sha256Of(File file) async =>
      (await sha256.bind(file.openRead()).first).toString();
}
