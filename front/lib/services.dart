import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

Future<String> getOrCreateUserId() async {
  final prefs = await SharedPreferences.getInstance();
  // ユーザーIDを取得または作成
  // ユーザーIDはインストール時に一度だけ作成される
  final userId = prefs.getString('userId') ?? const Uuid().v4();
  await prefs.setString('userId', userId);
  return userId;
}
