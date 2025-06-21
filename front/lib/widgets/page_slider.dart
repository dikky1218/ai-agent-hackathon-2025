import 'package:flutter/material.dart';
import '../models/slide_page.dart';

class PageSlider extends StatelessWidget {
  final int currentPageIndex;
  final int totalPages;
  final Color currentPageColor;
  final ValueChanged<double> onSliderChanged;
  final SlidePage? currentSlidePage; // 現在のスライドページ情報

  const PageSlider({
    super.key,
    required this.currentPageIndex,
    required this.totalPages,
    required this.currentPageColor,
    required this.onSliderChanged,
    this.currentSlidePage,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              Text(
                '${currentPageIndex + 1} / $totalPages',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: currentPageColor,
              thumbColor: currentPageColor,
              overlayColor: currentPageColor.withValues(alpha: 0.2),
              inactiveTrackColor: Colors.grey[300],
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: currentPageIndex.toDouble(),
              min: 0,
              max: (totalPages - 1).toDouble(),
              divisions: totalPages - 1,
              onChanged: onSliderChanged,
            ),
          ),
        ],
      ),
    );
  }
} 