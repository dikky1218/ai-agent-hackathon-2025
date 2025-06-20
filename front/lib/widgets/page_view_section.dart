import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final aiMessages = chatProvider.aiMessages;
        
        // AIメッセージが増えた場合、最新のメッセージに自動遷移
        if (aiMessages.length > _previousAiMessageCount && aiMessages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.animateToPage(
                aiMessages.length - 1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }
        _previousAiMessageCount = aiMessages.length;
        
        return SizedBox(
          height: widget.height,
          child: aiMessages.isEmpty
              ? const Center(
                  child: Text(
                    'AIからの回答がここに表示されます',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  itemCount: aiMessages.length,
                  itemBuilder: (context, index) {
                    final message = aiMessages[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      color: _getPageColor(index),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI回答 ${index + 1}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              message.text ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Color _getPageColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.red,
      Colors.brown,
    ];
    return colors[index % colors.length];
  }
}