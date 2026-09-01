import 'dart:typed_data';

/// A real FLAC file, small enough to write from a test and complete enough
/// for the core's tag reader to open.
///
/// The integration suite's other fixtures are text files with media
/// extensions, which is all most of them need: they are about paths, uuids
/// and argument order, and a file the tag reader cannot open is a fine
/// stand-in for those. Nothing could be asserted about *tags* with one,
/// though, which left the one thing an owner sees most of — what the catalog
/// says a track is called and who it is by — provable only against fakes.
///
/// The header is the whole file: a `fLaC` marker, a STREAMINFO block (the
/// only mandatory one) and a VORBIS_COMMENT block carrying the tags. There
/// are no audio frames at all, which no reader minds — the duration comes
/// from STREAMINFO's sample count, not from the frames.
Uint8List taggedFlac({
  required Map<String, String> tags,
  int durationSeconds = 200,
  int sampleRate = 44100,
}) {
  final bytes = BytesBuilder()..add('fLaC'.codeUnits);
  bytes.add(_block(0, _streamInfo(sampleRate, durationSeconds)));
  bytes.add(_block(4, _vorbisComment(tags), last: true));

  return bytes.toBytes();
}

/// One metadata block: a type byte (with the last-block flag in its top bit)
/// and a 24-bit big-endian length.
Uint8List _block(int type, Uint8List payload, {bool last = false}) {
  final header = Uint8List(4);
  header[0] = (last ? 0x80 : 0) | type;
  header[1] = (payload.length >> 16) & 0xFF;
  header[2] = (payload.length >> 8) & 0xFF;
  header[3] = payload.length & 0xFF;

  return (BytesBuilder()
        ..add(header)
        ..add(payload))
      .toBytes();
}

/// STREAMINFO: block sizes, frame sizes, then a packed field carrying the
/// sample rate, the channel count, the bit depth and the total sample count —
/// which is what a reader divides to answer a duration.
Uint8List _streamInfo(int sampleRate, int durationSeconds) {
  final data = ByteData(34);
  data.setUint16(0, 4096);
  data.setUint16(2, 4096);
  // Minimum and maximum frame size, 24 bits each: unknown, which is what a
  // file with no frames should say.
  for (var offset = 4; offset < 10; offset++) {
    data.setUint8(offset, 0);
  }

  const channels = 2;
  const bitsPerSample = 16;
  final packed =
      (BigInt.from(sampleRate) << 44) |
      (BigInt.from(channels - 1) << 41) |
      (BigInt.from(bitsPerSample - 1) << 36) |
      BigInt.from(sampleRate * durationSeconds);
  for (var byte = 0; byte < 8; byte++) {
    data.setUint8(
      10 + byte,
      ((packed >> ((7 - byte) * 8)) & BigInt.from(0xFF)).toInt(),
    );
  }

  // The MD5 of the unencoded audio, left zeroed: the value means "unknown",
  // which is exactly true of a file with no audio in it.
  return data.buffer.asUint8List();
}

/// VORBIS_COMMENT: a vendor string, a count, then `NAME=value` entries — all
/// lengths little-endian, unlike every other length in the format.
Uint8List _vorbisComment(Map<String, String> tags) {
  final vendor = 'alexandria-integration-test'.codeUnits;
  final bytes = BytesBuilder()
    ..add(_uint32le(vendor.length))
    ..add(vendor)
    ..add(_uint32le(tags.length));

  for (final tag in tags.entries) {
    final entry = '${tag.key}=${tag.value}'.codeUnits;
    bytes
      ..add(_uint32le(entry.length))
      ..add(entry);
  }

  return bytes.toBytes();
}

Uint8List _uint32le(int value) =>
    (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List();
