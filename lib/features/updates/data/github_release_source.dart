import 'dart:convert';
import 'dart:io';

import '../domain/release_info.dart';
import '../domain/update_ports.dart';

/// [ReleaseSource] over GitHub's public `releases/latest`
/// (update-check design §2).
///
/// The one network call the application makes of its own. It sends nothing
/// but the request: an `Accept` header and a `User-Agent` naming the
/// application and its version. `releases/latest` already leaves out drafts
/// and pre-releases.
class GitHubReleaseSource implements ReleaseSource {
  /// Creates the source for [url], as [appVersion].
  GitHubReleaseSource({
    required this.url,
    required this.appVersion,
    this.timeout = const Duration(seconds: 10),
    HttpClient Function()? client,
  }) : _client = client ?? HttpClient.new;

  /// The `releases/latest` address.
  final Uri url;

  /// The running version, for the `User-Agent`.
  final String appVersion;

  /// How long the whole request may take.
  final Duration timeout;

  final HttpClient Function() _client;

  @override
  Future<ReleaseInfo> latest() async {
    final client = _client();
    try {
      return await _read(client).timeout(timeout);
    } on UpdateCheckException {
      rethrow;
    } on Object catch (error) {
      throw UpdateCheckException(
        'the latest release could not be read: $error',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<ReleaseInfo> _read(HttpClient client) async {
    final request = await client.getUrl(url);
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(HttpHeaders.userAgentHeader, 'Alexandria/$appVersion');
    final response = await request.close();

    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != HttpStatus.ok) {
      throw UpdateCheckException('status ${response.statusCode}');
    }

    final release = ReleaseInfo.fromGitHubJson(
      jsonDecode(body) as Map<String, dynamic>,
    );
    if (release == null) {
      throw const UpdateCheckException('the latest tag is not a release');
    }
    return release;
  }
}
