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
    // ブラウザで試行する日本語ロケールのリスト（優先順）
    final possibleJapaneseLocales = [
      'ja-JP',    // 標準的な形式
      'ja_JP',    // アンダースコア形式
      'ja',       // 言語コードのみ
      'japanese', // 言語名
      'jp',       // 国コード
    ];

    String? localeToUse;
    
    // 利用可能なロケールから日本語を探す
    final locales = await _speechToText.locales();
    print('Available locales count: ${locales.length}');
    
    if (locales.isNotEmpty) {
      // ロケールが利用可能な場合は日本語を探す
      final japaneseLocales = locales.where((l) => 
        l.localeId.startsWith('ja') || 
        l.localeId.contains('japan') || 
        l.name.toLowerCase().contains('japanese')
      ).toList();
      
      if (japaneseLocales.isNotEmpty) {
        localeToUse = japaneseLocales.first.localeId;
        print('Found Japanese locale: $localeToUse');
      }
    }
    
    // ロケールが見つからない場合は、可能性のある形式を順番に試行
    if (localeToUse == null) {
      print('No Japanese locale found in available list, trying possible formats...');
      // ブラウザの場合、一般的に ja-JP が標準
      localeToUse = possibleJapaneseLocales.first;
    }
    
    print('Using locale: $localeToUse');

    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: localeToUse,
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