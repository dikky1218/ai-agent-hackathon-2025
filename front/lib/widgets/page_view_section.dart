import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/chat_provider.dart';
import '../models/slide_page.dart';
import '../services/slide_generator.dart';
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
        final slidePages = SlideGenerator.generateSlidePages(aiMessages);
        
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
                // 2回目以降は現在のページの次のページに遷移
                targetIndex = _currentPageIndex + 1;
                // 範囲チェック：次のページが存在しない場合は最後のページに遷移
                if (targetIndex >= slidePages.length) {
                  targetIndex = slidePages.length - 1;
                }
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
              currentPageColor: slidePages.isNotEmpty && _currentPageIndex < slidePages.length
                  ? SlideGenerator.getFlutterColorByIndex(slidePages[_currentPageIndex].colorIndex) ?? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColor,
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
                        final borderColor = SlideGenerator.getFlutterColorByIndex(slidePage.colorIndex);
                        return Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: borderColor != null 
                              ? Border.all(
                                  color: borderColor,
                                  width: 3.0,
                                )
                              : null,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'ページ: ${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
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
                                    h1: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: SlideGenerator.getFlutterColorByIndex(slidePage.colorIndex) ?? Colors.black,
                                    ),
                                    h2: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      decoration: TextDecoration.underline,
                                      decorationColor: SlideGenerator.getFlutterColorByIndex(slidePage.colorIndex) ?? Colors.black,
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