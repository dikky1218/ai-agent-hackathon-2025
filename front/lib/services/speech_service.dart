import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  bool get speechEnabled => _speechEnabled;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;

  Future<void> initialize() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: _onStatusChanged,
      onError: _onError,
    );
    notifyListeners();
  }

  Future<void> startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'ja_JP',
      listenFor: Duration(seconds: 300),
      pauseFor: Duration(seconds: 60),
    );
    _isListening = true;
    notifyListeners();
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    notifyListeners();
  }

  void clearLastWords() {
    _lastWords = '';
    notifyListeners();
  }

  void _onSpeechResult(result) {
    _lastWords = result.recognizedWords;
    notifyListeners();
  }

  // 音声認識の状態変化を監視
  void _onStatusChanged(String status) {
    print('Speech status: $status'); // デバッグ用
    if (status == 'notListening' || status == 'done') {
      _isListening = false;
      notifyListeners();
    } else if (status == 'listening') {
      _isListening = true;
      notifyListeners();
    }
  }

  // エラーハンドリング
  void _onError(errorNotification) {
    print('Speech error: $errorNotification'); // デバッグ用
    _isListening = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}