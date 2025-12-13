import 'dart:typed_data';
import 'package:image_picker_web/image_picker_web.dart';

Future<Uint8List?> pickImageWeb() async {
  return await ImagePickerWeb.getImageAsBytes();
}
