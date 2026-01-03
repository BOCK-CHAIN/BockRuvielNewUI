import 'package:flutter/foundation.dart';

class ShareHelper {
  static Future<bool> share({
    required String title,
    required String text,
    required String url,
  }) async {
    if (!kIsWeb) {
      return false;
    }
    return false;
  }
}
