// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ShareHelper {
  static Future<bool> share({
    required String title,
    required String text,
    required String url,
  }) async {
    final navigator = html.window.navigator;

    // The "share" API is not yet modelled in dart:html types, so we must
    // access it dynamically and handle the case where it's not available.
    final dynamic navDynamic = navigator;
    final dynamic shareFn = navDynamic.share;

    if (shareFn == null) {
      return false;
    }

    try {
      await shareFn(<String, Object?>{
        'title': title,
        'text': text,
        'url': url,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
