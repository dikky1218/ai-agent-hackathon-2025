import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatInputWidget extends StatefulWidget {
  const ChatInputWidget({
    super.key,
    required this.onSendMessage,
    this.onAttachmentPressed,
    this.hintText = 'メッセージを入力...',
    this.selectedImage,
    this.onClearAttachment,
    this.onStartRecording,
    this.onStopRecording,
    this.isRecording = false,
    this.text,
    this.isSending = false,
  });

  final Function(String) onSendMessage;
  final VoidCallback? onAttachmentPressed;
  final String hintText;
  final XFile? selectedImage;
  final VoidCallback? onClearAttachment;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final bool isRecording;
  final String? text;
  final bool isSending;

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  late TextEditingController _controller;
  bool _isComposing = false;
  Uint8List? _webImageBytes; // Web版用の画像データキャッシュ

  @override
  void initState() {
    print('ChatInputWidget initState called');
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _isComposing = _controller.text.isNotEmpty;
        });
      }
    });
    _loadWebImage(); // Web版の画像を初期化時に読み込み
  }

  @override
  void didUpdateWidget(covariant ChatInputWidget oldWidget) {
    print('ChatInputWidget didUpdateWidget called');
    print('Old selectedImage: ${oldWidget.selectedImage?.path}');
    print('New selectedImage: ${widget.selectedImage?.path}');
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text && widget.text != null) {
      _controller.text = widget.text!;
      // カーソルを末尾に移動
      _controller.selection =
          TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    }
    
    // 画像が変更された場合はWeb版の画像を再読み込み
    if (widget.selectedImage != oldWidget.selectedImage) {
      print('Selected image changed, reloading web image');
      _loadWebImage();
    }
  }

  Future<void> _loadWebImage() async {
    print('=== _loadWebImage called ===');
    print('kIsWeb: $kIsWeb');
    print('widget.selectedImage != null: ${widget.selectedImage != null}');
    print('mounted: $mounted');
    
    if (kIsWeb && widget.selectedImage != null) {
      try {
        print('Loading web image...');
        final bytes = await widget.selectedImage!.readAsBytes();
        print('Original image size: ${bytes.length} bytes');
        
        // 大きな画像（2MB以上）の場合はリサイズを試行
        if (bytes.length > 2 * 1024 * 1024) {
          print('Large image detected, attempting to resize...');
          try {
            final resizedBytes = await _resizeImageForWeb(bytes);
            print('Resized image size: ${resizedBytes.length} bytes');
            if (mounted) {
              print('Setting state with resized image bytes');
              setState(() {
                _webImageBytes = resizedBytes;
              });
              print('State set with resized image bytes');
            } else {
              print('Widget not mounted, skipping setState');
            }
            return;
          } catch (resizeError) {
            print('Resize failed: $resizeError, using original image');
          }
        }
        
        print('Web image loaded: ${bytes.length} bytes');
        if (mounted) {
          print('Setting state with original image bytes');
          setState(() {
            _webImageBytes = bytes;
          });
          print('State set with original image bytes');
        } else {
          print('Widget not mounted, skipping setState');
        }
      } catch (e) {
        print('Error loading web image: $e');
        if (mounted) {
          setState(() {
            _webImageBytes = null;
          });
        }
      }
    } else {
      print('Clearing _webImageBytes (not web or no selected image)');
      _webImageBytes = null;
    }
  }

  Future<Uint8List> _resizeImageForWeb(Uint8List originalBytes) async {
    // HTMLのCanvasを使用して画像をリサイズ
    if (kIsWeb) {
      try {
        // 画像をデコード
        final codec = await ui.instantiateImageCodec(
          originalBytes,
          targetWidth: 800, // 最大幅を800pxに制限
          targetHeight: 600, // 最大高さを600pxに制限
        );
        final frame = await codec.getNextFrame();
        final image = frame.image;
        
        // ByteDataに変換
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          return byteData.buffer.asUint8List();
        }
      } catch (e) {
        print('Image resize error: $e');
      }
    }
    // リサイズに失敗した場合は元の画像を返す
    return originalBytes;
  }

  @override
  void dispose() {
    print('ChatInputWidget dispose called');
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty || widget.selectedImage != null) {
      // テキストが空で画像がある場合は、プレースホルダーテキストを送信
      final messageToSend =
          text.isEmpty && widget.selectedImage != null ? '[画像]' : text;
      widget.onSendMessage(messageToSend);
      _controller.clear();
      setState(() {
        _isComposing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8.0,
        8.0,
        8.0,
        8.0 + MediaQuery.of(context).viewPadding.bottom,
      ), // セーフエリアを考慮したパディング
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.selectedImage != null) _buildThumbnail(),
            Row(
              children: [
                // 添付ボタン
                IconButton(
                  onPressed: widget.onAttachmentPressed ??
                      () {},
                  icon: const Icon(Icons.add, color: Colors.grey),
                ),
                // テキスト入力フィールド
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // マイク or 送信ボタン
                if ((_isComposing || widget.selectedImage != null || widget.isSending) && !widget.isRecording)
                  // 送信ボタン
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: widget.isSending 
                        ? Container(
                            width: 48,
                            height: 48,
                            padding: const EdgeInsets.all(12),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : IconButton(
                            onPressed: widget.isSending ? null : _sendMessage,
                            icon: const Icon(Icons.send, color: Colors.white),
                          ),
                  )
                else
                  // マイクボタン
                  IconButton(
                    onPressed: widget.isRecording
                        ? widget.onStopRecording
                        : widget.onStartRecording,
                    icon: Icon(
                      widget.isRecording ? Icons.stop : Icons.mic,
                      color: widget.isRecording ? Colors.red : Colors.grey,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    print('=== _buildThumbnail called ===');
    print('kIsWeb: $kIsWeb');
    print('selectedImage != null: ${widget.selectedImage != null}');
    print('selectedImage path: ${widget.selectedImage?.path}');
    print('_webImageBytes != null: ${_webImageBytes != null}');
    print('_webImageBytes length: ${_webImageBytes?.length}');
    print('Widget mounted: $mounted');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.blue, width: 2), // デバッグ用のボーダー
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: kIsWeb
                  ? (_webImageBytes != null
                      ? Builder(
                          builder: (context) {
                            print('Building Image.memory widget');
                            return Image.memory(
                              _webImageBytes!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                print('Image.memory frameBuilder called, frame: $frame');
                                return child;
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('Image.memory error: $error');
                                print('StackTrace: $stackTrace');
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.orange[200],
                                  child: const Center(
                                    child: Icon(Icons.broken_image, color: Colors.orange),
                                  ),
                                );
                              },
                            );
                          },
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ))
                  : Image.file(
                      File(widget.selectedImage!.path),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.black54),
              onPressed: () {
                print('Cancel button pressed');
                widget.onClearAttachment?.call();
              },
            ),
          ),
        ],
      ),
    );
  }
} 