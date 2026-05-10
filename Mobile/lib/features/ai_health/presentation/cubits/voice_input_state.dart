/// Sealed states for the voice input flow.
sealed class VoiceInputState {
  const VoiceInputState();
}

/// Mic is idle — not listening.
class VoiceIdle extends VoiceInputState {
  const VoiceIdle();
}

/// STT is actively listening to the microphone.
class VoiceListening extends VoiceInputState {
  /// Current partial transcript from STT.
  final String transcript;

  /// Sound level (0.0–1.0) for animated visualization.
  final double soundLevel;

  const VoiceListening({this.transcript = '', this.soundLevel = 0.0});
}

/// STT recognized final text.
class VoiceResult extends VoiceInputState {
  final String text;
  const VoiceResult(this.text);
}

/// Something went wrong — e.g. permission denied, no speech recognized.
class VoiceError extends VoiceInputState {
  final String message;
  const VoiceError(this.message);
}
