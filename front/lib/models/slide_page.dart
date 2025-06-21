// スライドページのデータクラス
class SlidePage {
  final String text;
  final int originalMessageIndex;
  final int slideIndex;
  final int? colorIndex; // h1タイトルごとの色インデックス
  
  SlidePage({
    required this.text,
    required this.originalMessageIndex,
    required this.slideIndex,
    this.colorIndex,
  });
} 