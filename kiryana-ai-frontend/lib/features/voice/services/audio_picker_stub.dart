import 'dart:typed_data';

class PickedAudio {
  final Uint8List bytes;
  final String fileName;

  const PickedAudio({required this.bytes, required this.fileName});
}

Future<void> startMicRecording() async {
  throw UnsupportedError(
      'Microphone recording is only enabled in the browser.');
}

Future<PickedAudio?> stopMicRecording() async {
  throw UnsupportedError(
      'Microphone recording is only enabled in the browser.');
}

void cancelMicRecording() {}
