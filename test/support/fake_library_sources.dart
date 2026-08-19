import 'package:alexandria_desktop/features/library_sources/domain/folder_picker.dart';
import 'package:alexandria_desktop/features/library_sources/domain/library_source.dart';
import 'package:alexandria_desktop/features/library_sources/domain/library_source_store.dart';

/// A [FolderPicker] that answers whatever a test told it to
/// (Testing Specification §6.2).
///
/// A widget test cannot open a native dialog, and cancelling one is an
/// alternative flow in its own right (UC-05 AF-01) — so the dialog is the
/// thing that gets substituted.
class FakeFolderPicker implements FolderPicker {
  /// Creates a picker answering [path], or `null` to model a cancellation.
  FakeFolderPicker({this.path});

  /// What [pickFolder] answers. `null` is the owner cancelling (AF-01).
  String? path;

  /// How many times the picker was opened.
  int openCount = 0;

  @override
  Future<String?> pickFolder() async {
    openCount++;
    return path;
  }
}

/// A [FolderProbe] over a map rather than a filesystem.
///
/// The two questions are answered independently so a test can produce the
/// folder that exists and will not open, which FR-LB-02 requires be told apart
/// from one that is not there.
class FakeFolderProbe implements FolderProbe {
  /// Creates a probe where every folder exists and is readable unless a test
  /// says otherwise.
  FakeFolderProbe({this.existing = true, this.readable = true});

  /// What [exists] answers.
  bool existing;

  /// What [isReadable] answers.
  bool readable;

  /// Every path [isReadable] was asked about.
  final List<String> readabilityChecks = [];

  @override
  Future<bool> exists(String path) async => existing;

  @override
  Future<bool> isReadable(String path) async {
    readabilityChecks.add(path);
    return readable;
  }
}

/// A [LibrarySourceStore] holding its folders in memory.
class InMemoryLibrarySourceStore implements LibrarySourceStore {
  /// Creates a store, optionally pre-populated.
  InMemoryLibrarySourceStore([List<LibrarySource>? sources])
    : _sources = [...?sources];

  List<LibrarySource> _sources;

  /// How many times the set was written.
  ///
  /// Zero is the assertion that matters for every refusal: a folder that was
  /// not registered must not have been persisted either.
  int writeCount = 0;

  @override
  List<LibrarySource> read() => List.unmodifiable(_sources);

  @override
  Future<void> write(List<LibrarySource> sources) async {
    writeCount++;
    _sources = [...sources];
  }
}
