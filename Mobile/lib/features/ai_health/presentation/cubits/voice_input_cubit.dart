import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: depend_on_referenced_packages
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'voice_input_state.dart';

/// Cubit managing speech-to-text voice input flow.
///
/// Lifecycle: VoiceIdle → VoiceListening → VoiceResult / VoiceError → VoiceIdle
class VoiceInputCubit extends Cubit<VoiceInputState> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  VoiceInputCubit() : super(const VoiceIdle());

  /// Start listening for speech input.
  Future<void> startListening() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          if (error.errorMsg == 'error_no_match') {
            emit(const VoiceError('No speech detected. Please try again.'));
          } else {
            emit(VoiceError('Speech error: ${error.errorMsg}'));
          }
          emit(const VoiceIdle());
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            // If we're still in listening state with no result, emit idle.
            if (state is VoiceListening) {
              final transcript = (state as VoiceListening).transcript;
              if (transcript.isNotEmpty) {
                emit(VoiceResult(transcript));
              }
              emit(const VoiceIdle());
            }
          }
        },
      );

      if (!_isInitialized) {
        emit(const VoiceError(
          'Microphone permission denied. Please enable it in Settings.',
        ));
        emit(const VoiceIdle());
        return;
      }
    }

    emit(const VoiceListening());

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          emit(VoiceResult(result.recognizedWords));
          emit(const VoiceIdle());
        } else {
          emit(VoiceListening(
            transcript: result.recognizedWords,
            soundLevel: 0.5,
          ));
        }
      },
      onSoundLevelChange: (level) {
        // Normalize sound level from dB to 0.0-1.0 range.
        final normalized = ((level + 2) / 12).clamp(0.0, 1.0);
        if (state is VoiceListening) {
          emit(VoiceListening(
            transcript: (state as VoiceListening).transcript,
            soundLevel: normalized,
          ));
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
      // ignore: deprecated_member_use
      cancelOnError: true,
      // ignore: deprecated_member_use
      partialResults: true,
    );
  }

  /// Stop listening.
  Future<void> stopListening() async {
    await _speech.stop();
    if (state is VoiceListening) {
      final transcript = (state as VoiceListening).transcript;
      if (transcript.isNotEmpty) {
        emit(VoiceResult(transcript));
      }
    }
    emit(const VoiceIdle());
  }

  /// Cancel and discard any result.
  Future<void> cancelListening() async {
    await _speech.cancel();
    emit(const VoiceIdle());
  }

  @override
  Future<void> close() {
    _speech.cancel();
    return super.close();
  }
}
