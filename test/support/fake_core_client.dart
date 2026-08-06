import 'package:alexandria_desktop/core/bindings/core_client.dart';
import 'package:alexandria_desktop/core/bindings/core_isolate.dart';
import 'package:alexandria_desktop/core/failures/core_status.dart';

/// A [CoreClient] that never loads a native library (Testing Specification §2.3
/// and §6.2).
///
/// A hand-written fake rather than a `mocktail` stub because startup spans
/// several calls in a fixed order, and the Testing Specification prefers a fake
/// wherever the interaction spans more than one call: a fake that misbehaves
/// fails loudly, while a mis-stubbed mock passes quietly.
class FakeCoreClient implements CoreClient {
  /// Creates a fake reporting a healthy, supported core by default.
  FakeCoreClient({
    this.versionResult = '0.1.0',
    int? healthResult,
    int? initializeResult,
    this.failOnVersion = false,
    this.failOnHealth = false,
    this.failOnInitialize = false,
  }) : healthResult = healthResult ?? coreHealthyStatusCode,
       initializeResult = initializeResult ?? CoreStatusFamily.indexing.okCode;

  /// What [version] returns.
  final String? versionResult;

  /// What [healthStatus] returns.
  final int healthResult;

  /// What [initialize] returns.
  final int initializeResult;

  /// Whether [version] throws instead of returning.
  final bool failOnVersion;

  /// Whether [healthStatus] throws instead of returning.
  final bool failOnHealth;

  /// Whether [initialize] throws instead of returning.
  final bool failOnInitialize;

  /// The database paths [initialize] was called with, in order.
  final List<String> initializedWith = [];

  /// How many times [dispose] was called.
  int disposeCount = 0;

  @override
  Future<String?> version() async {
    if (failOnVersion) throw const CoreCallException('version call failed');
    return versionResult;
  }

  @override
  Future<int> healthStatus() async {
    if (failOnHealth) throw const CoreCallException('health call failed');
    return healthResult;
  }

  @override
  Future<int> initialize(String databasePath) async {
    if (failOnInitialize) throw const CoreCallException('init call failed');
    initializedWith.add(databasePath);
    return initializeResult;
  }

  @override
  Future<void> dispose() async => disposeCount++;
}
