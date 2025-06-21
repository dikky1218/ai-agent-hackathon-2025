import 'package:flutter/material.dart';
import '../models/slide_page.dart';

class SlideGenerator {
  // 目に優しく区別しやすい色パレット（HSLで定義）
  static final List<Map<String, double>> _colorPalette = [
    {'h': 210, 's': 0.7, 'l': 0.6}, // ソフトブルー
    {'h': 150, 's': 0.6, 'l': 0.6}, // ソフトグリーン
    {'h': 30, 's': 0.7, 'l': 0.7},  // ソフトオレンジ
    {'h': 270, 's': 0.6, 'l': 0.7}, // ソフトパープル
    {'h': 350, 's': 0.6, 'l': 0.7}, // ソフトピンク
    {'h': 180, 's': 0.6, 'l': 0.6}, // ソフトティール
    {'h': 60, 's': 0.6, 'l': 0.7},  // ソフトイエロー
    {'h': 300, 's': 0.5, 'l': 0.7}, // ソフトマゼンタ
    {'h': 120, 's': 0.5, 'l': 0.7}, // ライトグリーン
    {'h': 240, 's': 0.6, 'l': 0.7}, // ライトブルー
  ];

  // h1タイトルと色インデックスのマッピング
  static final Map<String, int> _titleColorMap = {};
  static int _nextColorIndex = 0;

  // aiMessagesからslidePagesを生成するメソッド
  static List<SlidePage> generateSlidePages(List messages) {
    List<SlidePage> slidePages = [];
    
    // 色のマッピングをリセット
    _titleColorMap.clear();
    _nextColorIndex = 0;
    
    for (int messageIndex = 0; messageIndex < messages.length; messageIndex++) {
      final message = messages[messageIndex];
      final text = message.text ?? '';
      
      // \n---\nで分割
      final parts = text.split('\n---\n');
      
      for (int partIndex = 0; partIndex < parts.length; partIndex++) {
        final part = parts[partIndex].trim();
        if (part.isNotEmpty) {
          // マークダウンの構造を解析してスライドを生成
          final structuredSlides = _parseMarkdownStructure(part, messageIndex, partIndex);
          slidePages.addAll(structuredSlides);
        }
      }
    }
    
    return slidePages;
  }

  // h1タイトルに対応する色インデックスを取得またはランダム生成
  static int _getColorIndexForTitle(String title) {
    if (_titleColorMap.containsKey(title)) {
      return _titleColorMap[title]!;
    }
    
    // ランダムな色を割り当て（重複を避けるために連続的に割り当て）
    final colorIndex = _nextColorIndex % _colorPalette.length;
    _titleColorMap[title] = colorIndex;
    _nextColorIndex++;
    
    return colorIndex;
  }

  // 色インデックスから色情報を取得するメソッド
  static Map<String, double>? getColorByIndex(int? colorIndex) {
    if (colorIndex == null || colorIndex >= _colorPalette.length) {
      return null;
    }
    return _colorPalette[colorIndex];
  }

  // 色インデックスからFlutter Colorオブジェクトを取得するメソッド
  static Color? getFlutterColorByIndex(int? colorIndex) {
    final colorData = getColorByIndex(colorIndex);
    if (colorData == null) {
      return null;
    }
    
    // HSLからRGBに変換
    final h = colorData['h']! / 360.0;
    final s = colorData['s']!;
    final l = colorData['l']!;
    
    return HSLColor.fromAHSL(1.0, h * 360, s, l).toColor();
  }

  // マークダウン構造を解析してスライドを生成するメソッド
  static List<SlidePage> _parseMarkdownStructure(String text, int messageIndex, int partIndex) {
    List<SlidePage> slides = [];
    final lines = text.split('\n');
    
    String? currentH1Title;
    String currentH1Content = '';
    List<String> currentH2Sections = [];
    String currentH2Content = '';
    bool inH1Section = false;
    bool inH2Section = false;
    
    for (String line in lines) {
      // h1ヘッダーを検出 (# で始まる行、##は除外)
      if (line.startsWith('# ') && !line.startsWith('## ')) {
        // 前のh1セクションを処理
        if (currentH1Title != null) {
          _addH1SectionSlides(slides, currentH1Title, currentH1Content, currentH2Sections, messageIndex, partIndex);
          currentH2Sections.clear();
        }
        
        // 新しいh1セクションを開始
        currentH1Title = line.substring(2).trim(); // "# "を除去
        currentH1Content = line + '\n';
        currentH2Content = '';
        inH1Section = true;
        inH2Section = false;
      }
      // h2ヘッダーを検出
      else if (line.startsWith('## ')) {
        // 前のh2セクションを保存
        if (inH2Section && currentH2Content.isNotEmpty) {
          currentH2Sections.add(currentH2Content.trim());
        }
        
        // 新しいh2セクションを開始
        currentH2Content = line + '\n';
        inH2Section = true;
      }
      // 通常のコンテンツ
      else {
        if (inH2Section) {
          currentH2Content += line + '\n';
        } else if (inH1Section) {
          currentH1Content += line + '\n';
        } else {
          // h1より前のコンテンツは単独のスライドとして追加
          if (line.trim().isNotEmpty || slides.isEmpty) {
            if (slides.isEmpty) {
              slides.add(SlidePage(
                text: line,
                originalMessageIndex: messageIndex,
                slideIndex: 0,
                colorIndex: null, // h1タイトルがない場合は色なし
              ));
            } else {
              slides.last = SlidePage(
                text: slides.last.text + '\n' + line,
                originalMessageIndex: messageIndex,
                slideIndex: slides.last.slideIndex,
                colorIndex: slides.last.colorIndex, // 既存の色インデックスを保持
              );
            }
          }
        }
      }
    }
    
    // 最後のh2セクションを保存
    if (inH2Section && currentH2Content.isNotEmpty) {
      currentH2Sections.add(currentH2Content.trim());
    }
    
    // 最後のh1セクションを処理
    if (currentH1Title != null) {
      _addH1SectionSlides(slides, currentH1Title, currentH1Content, currentH2Sections, messageIndex, partIndex);
    }
    
    // スライドが空の場合は元のテキストをそのまま使用
    if (slides.isEmpty) {
      slides.add(SlidePage(
        text: text,
        originalMessageIndex: messageIndex,
        slideIndex: partIndex,
        colorIndex: null, // h1タイトルがない場合は色なし
      ));
    }
    
    return slides;
  }

  // h1セクションからスライドを生成するヘルパーメソッド
  static void _addH1SectionSlides(List<SlidePage> slides, String h1Title, String h1Content, 
                          List<String> h2Sections, int messageIndex, int partIndex) {
    final colorIndex = _getColorIndexForTitle(h1Title);
    
    if (h2Sections.isEmpty) {
      // h2セクションがない場合はh1セクション全体を1つのスライドとする
      // h1タイトルの形式を# <タイトル>に変更
      final modifiedContent = h1Content.replaceFirst('# $h1Title', '# <$h1Title>');
      slides.add(SlidePage(
        text: modifiedContent.trim(),
        originalMessageIndex: messageIndex,
        slideIndex: slides.length,
        colorIndex: colorIndex,
      ));
    } else {
      // h2セクションがある場合は、h1タイトル + 各h2セクションを別々のスライドとする
      for (int i = 0; i < h2Sections.length; i++) {
        final slideContent = '# <$h1Title>\n\n${h2Sections[i]}';
        slides.add(SlidePage(
          text: slideContent.trim(),
          originalMessageIndex: messageIndex,
          slideIndex: slides.length,
          colorIndex: colorIndex,
        ));
      }
    }
  }
} 