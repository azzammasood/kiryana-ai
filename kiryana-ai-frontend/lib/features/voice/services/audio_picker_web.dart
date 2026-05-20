// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

class PickedAudio {
  final Uint8List bytes;
  final String fileName;

  const PickedAudio({required this.bytes, required this.fileName});
}

html.MediaRecorder? _recorder;
html.MediaStream? _stream;
final List<html.Blob> _chunks = [];

Future<void> startMicRecording() async {
  if (_recorder?.state == 'recording') return;

  _chunks.clear();
  _stream = await html.window.navigator.mediaDevices?.getUserMedia({
    'audio': true,
    'video': false,
  });
  final stream = _stream;
  if (stream == null) {
    throw Exception('Microphone permission nahi mili');
  }

  final options = html.MediaRecorder.isTypeSupported('audio/webm')
      ? {'mimeType': 'audio/webm'}
      : null;
  _recorder = options == null
      ? html.MediaRecorder(stream)
      : html.MediaRecorder(stream, options);
  _recorder!.addEventListener('dataavailable', (event) {
    final blobEvent = event as html.BlobEvent;
    final data = blobEvent.data;
    if (data != null && data.size > 0) {
      _chunks.add(data);
    }
  });
  _recorder!.start();
}

Future<PickedAudio?> stopMicRecording() async {
  final recorder = _recorder;
  if (recorder == null) return null;

  final stopped = Completer<void>();
  void handleStop(html.Event _) {
    if (!stopped.isCompleted) {
      stopped.complete();
    }
  }

  recorder.addEventListener('stop', handleStop);
  if (recorder.state == 'recording') {
    recorder.stop();
  } else if (!stopped.isCompleted) {
    stopped.complete();
  }
  await stopped.future;
  recorder.removeEventListener('stop', handleStop);

  final blob = html.Blob(_chunks, recorder.mimeType);
  final bytes = await _readBlob(blob);
  cancelMicRecording();
  if (bytes.isEmpty) return null;

  return PickedAudio(
    bytes: bytes,
    fileName: 'kiryana-voice-${DateTime.now().millisecondsSinceEpoch}.webm',
  );
}

void cancelMicRecording() {
  _recorder = null;
  for (final track in _stream?.getTracks() ?? const <html.MediaStreamTrack>[]) {
    track.stop();
  }
  _stream = null;
  _chunks.clear();
}

Future<Uint8List> _readBlob(html.Blob blob) async {
  final reader = html.FileReader();
  final completer = Completer<Uint8List>();
  reader.onError.listen((_) => completer.completeError('Audio read failed'));
  reader.onLoadEnd.listen((_) {
    final result = reader.result;
    if (result is String && result.contains(',')) {
      completer.complete(base64Decode(result.split(',').last));
    } else {
      completer.completeError('Audio recording could not be read');
    }
  });
  reader.readAsDataUrl(blob);
  return completer.future;
}
