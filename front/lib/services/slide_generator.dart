import '../models/slide_page.dart';

class SlideGenerator {
  // aiMessagesからslidePagesを生成するメソッド
  static List<SlidePage> generateSlidePages(List messages) {
    List<SlidePage> slidePages = [];
    
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
              ));
            } else {
              slides.last = SlidePage(
                text: slides.last.text + '\n' + line,
                originalMessageIndex: messageIndex,
                slideIndex: slides.last.slideIndex,
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
      ));
    }
    
    return slides;
  }

  // h1セクションからスライドを生成するヘルパーメソッド
  static void _addH1SectionSlides(List<SlidePage> slides, String h1Title, String h1Content, 
                          List<String> h2Sections, int messageIndex, int partIndex) {
    if (h2Sections.isEmpty) {
      // h2セクションがない場合はh1セクション全体を1つのスライドとする
      slides.add(SlidePage(
        text: h1Content.trim(),
        originalMessageIndex: messageIndex,
        slideIndex: slides.length,
      ));
    } else {
      // h2セクションがある場合は、h1タイトル + 各h2セクションを別々のスライドとする
      for (int i = 0; i < h2Sections.length; i++) {
        final slideContent = '# $h1Title\n\n${h2Sections[i]}';
        slides.add(SlidePage(
          text: slideContent.trim(),
          originalMessageIndex: messageIndex,
          slideIndex: slides.length,
        ));
      }
    }
  }
} 