import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_config.dart';

class ImageUploadService {
  static final _picker = ImagePicker();

  /// Abre la galería, selecciona una imagen, la sube a Supabase Storage (bucket 'media')
  /// y retorna la URL pública. Retorna null si el usuario cancela o hay error.
  static Future<String?> pickAndUploadImage({required String folder}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (image == null) return null;

      final file = File(image.path);
      final fileExt = image.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$folder/$fileName';

      await supabase.storage.from('media').upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = supabase.storage.from('media').getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      print('Error subiendo imagen: $e');
      return null;
    }
  }
}
