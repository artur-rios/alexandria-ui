/// Where the owner had reached in a document (FR-VW-02, UC-23 main flow
/// step 4).
///
/// A page or a chapter index rather than a duration: the playback store
/// answers the same question for media, and the two are kept apart because a
/// position measured in pages and one measured in milliseconds are not the
/// same number and never convert.
abstract interface class ReadingPositionStore {
  /// The remembered position for [fileUuid], or `null` when there is none.
  int? positionFor(String fileUuid);

  /// Records where the owner has read to.
  Future<void> record(String fileUuid, int position);

  /// Forgets [fileUuid]'s position.
  Future<void> forget(String fileUuid);
}
