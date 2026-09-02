import 'dart:math' as math;
import 'dart:typed_data';

/// A real WAV file with real audio in it, small enough to write from a test.
///
/// The FLAC fixture beside this one carries tags and no audio frames at all,
/// which is everything a tag reader needs and nothing a decoder can measure.
/// The energy envelope (FR-MP-07) is measured from samples, so proving it
/// end to end needs a file that actually contains some — and a sine at a
/// known frequency is the one signal whose envelope can be asserted rather
/// than merely looked at.
///
/// Uncompressed 16-bit mono PCM: forty-four bytes of header and then the
/// samples, which is the whole format. ffmpeg reads it without a codec.
Uint8List sineWav({
  required double hertz,
  required double seconds,
  int sampleRate = 44100,
}) {
  final samples = (sampleRate * seconds).round();
  final data = ByteData(samples * 2);
  for (var index = 0; index < samples; index++) {
    final phase = index / sampleRate;
    // Two thirds of full scale: loud enough to measure, short of the ceiling
    // where a decoder's own limiting could shape what comes back.
    final value = math.sin(2 * math.pi * hertz * phase) * 0.66 * 32767;
    data.setInt16(index * 2, value.round(), Endian.little);
  }

  final bytes = BytesBuilder()
    ..add('RIFF'.codeUnits)
    ..add(_uint32(36 + data.lengthInBytes))
    ..add('WAVE'.codeUnits)
    ..add('fmt '.codeUnits)
    ..add(_uint32(16))
    ..add(_uint16(1))
    ..add(_uint16(1))
    ..add(_uint32(sampleRate))
    ..add(_uint32(sampleRate * 2))
    ..add(_uint16(2))
    ..add(_uint16(16))
    ..add('data'.codeUnits)
    ..add(_uint32(data.lengthInBytes))
    ..add(data.buffer.asUint8List());

  return bytes.toBytes();
}

Uint8List _uint32(int value) =>
    (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List();

Uint8List _uint16(int value) =>
    (ByteData(2)..setUint16(0, value, Endian.little)).buffer.asUint8List();
