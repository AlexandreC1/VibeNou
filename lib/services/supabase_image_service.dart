import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseImageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      rethrow;
    }
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error taking photo: $e');
      rethrow;
    }
  }

  // Upload profile picture to Supabase Storage
  Future<String?> uploadProfilePicture(File imageFile, String userId) async {
    try {
      final String fileName = 'profile_$userId.jpg';
      final String filePath = 'profile_pictures/$fileName';

      // Upload file to Supabase Storage
      await _supabase.storage
          .from('vibenou-profiles') // Your bucket name
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true, // Overwrites existing file
            ),
          );

      // Get public URL
      final String publicUrl = _supabase.storage
          .from('vibenou-profiles')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      rethrow;
    }
  }

  // Delete profile picture from Supabase Storage
  Future<void> deleteProfilePicture(String userId) async {
    try {
      final String fileName = 'profile_$userId.jpg';
      final String filePath = 'profile_pictures/$fileName';

      await _supabase.storage
          .from('vibenou-profiles')
          .remove([filePath]);
    } catch (e) {
      print('Error deleting profile picture: $e');
      rethrow;
    }
  }

  // Get profile picture URL
  String getProfilePictureUrl(String userId) {
    final String fileName = 'profile_$userId.jpg';
    final String filePath = 'profile_pictures/$fileName';

    return _supabase.storage
        .from('vibenou-profiles')
        .getPublicUrl(filePath);
  }
}
