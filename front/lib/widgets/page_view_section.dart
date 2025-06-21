import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/chat_provider.dart';
import '../models/slide_page.dart';
import 'page_slider.dart';

class PageViewSection extends StatefulWidget {
  final double height;

  const PageViewSection({
    super.key,
    required this.height,
  });

  @override
  State<PageViewSection> createState() => _PageViewSectionState();
}

class _PageViewSectionState extends State<PageViewSection> {
  late PageController _pageController;
  int _previousAiMessageCount = 0;
  int _currentPageIndex = 0; // 現在のページインデックスを追跡
  bool _isInitialLoad = true; // 初回読み込みかどうかを追跡

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // aiMessagesからslidePagesを生成するメソッド
  List<SlidePage> _generateSlidePages(List messages) {
    List<SlidePage> slidePages = [];
    
    for (int messageIndex = 0; messageIndex < messages.length; messageIndex++) {
      final message = messages[messageIndex];
      final text = message.text ?? '';
      
      // \n---\nで分割
      final parts = text.split('\n---\n');
      
      for (int partIndex = 0; partIndex < parts.length; partIndex++) {
        final part = parts[partIndex].trim();
        if (part.isNotEmpty) {
          slidePages.add(SlidePage(
            text: part,
            originalMessageIndex: messageIndex,
            slideIndex: partIndex,
          ));
        }
      }
    }
    
    return slidePages;
  }

  // Sliderの値が変更されたときの処理
  void _onSliderChanged(double value) {
    final newIndex = value.round();
    if (newIndex != _currentPageIndex) {
      setState(() {
        _currentPageIndex = newIndex;
      });
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // PageViewがスワイプされたときの処理
  void _onPageChanged(int index) {
    setState(() {
      _currentPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final aiMessages = chatProvider.aiMessages;
        final slidePages = _generateSlidePages(aiMessages);
        
        // AIメッセージが増えた場合の処理
        if (aiMessages.length > _previousAiMessageCount && slidePages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              int targetIndex;
              if (_isInitialLoad) {
                // 初回読み込み時は1ページ目を表示
                targetIndex = 0;
                _isInitialLoad = false;
              } else {
                // 2回目以降は最新のメッセージの最初のスライドに自動遷移
                targetIndex = slidePages.length - 1;
              }
              
              setState(() {
                _currentPageIndex = targetIndex;
              });
              _pageController.animateToPage(
                targetIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }
        _previousAiMessageCount = aiMessages.length;
        
        return Column(
          children: [
            // Sliderセクション
            PageSlider(
              currentPageIndex: _currentPageIndex,
              totalPages: slidePages.length,
              currentPageColor: Colors.white,
              onSliderChanged: _onSliderChanged,
              currentSlidePage: slidePages.isNotEmpty && _currentPageIndex < slidePages.length 
                  ? slidePages[_currentPageIndex] 
                  : null,
            ),
            
            // PageViewセクション
            Expanded(
              child: slidePages.isEmpty
                  ? const Center(
                      child: Text(
                        'AIからの回答がここに表示されます',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged, // ページ変更時のコールバック
                      itemCount: slidePages.length,
                      itemBuilder: (context, index) {
                        final slidePage = slidePages[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.white,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI回答 ${slidePage.originalMessageIndex + 1}-${slidePage.slideIndex + 1}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                MarkdownBody(
                                  data: slidePage.text,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                    h1: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    h2: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    h3: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    code: TextStyle(
                                      backgroundColor: Colors.black.withValues(alpha: 0.2),
                                      color: Colors.black,
                                      fontFamily: 'monospace',
                                    ),
                                    codeblockDecoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    blockquote: const TextStyle(
                                      color: Colors.black,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    listBullet: const TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

}