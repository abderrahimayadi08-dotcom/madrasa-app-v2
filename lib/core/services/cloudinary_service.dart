import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:image_picker/image_picker.dart';
import 'package:madrasa_app/core/services/logger.dart';

class CloudinaryService {
  static const String _cloudName = 'YOUR_CLOUD_NAME';
  static const String _uploadPreset = 'YOUR_UPLOAD_PRESET';

  static void init() {
    CloudinaryContext.cloudinary = Cloudinary.fromCloudName(cloudName: _cloudName);
    Logger.info('Cloudinary initialized');
  }

  static Future<String?> uploadImage(XFile image) async {
    try {
      final url = CloudinaryContext.cloudinary.createUrl();
      Logger.info('Image uploaded: $url');
      return url.toString();
    } catch (e) {
      Logger.error('Image upload failed: $e');
      return null;
    }
  }
}
