import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseImageService {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (e) {
      print('⚠️ Supabase not initialized');
      return null;
    }
  }

  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery (returns XFile for web compatibility)
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      return image;
    } catch (e) {
      print('Error picking image: $e');
      rethrow;
    }
  }

  // Pick image from camera (returns XFile for web compatibility)
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      return image;
    } catch (e) {
      print('Error taking photo: $e');
      rethrow;
    }
  }

  // Upload profile picture to Supabase Storage (works on both mobile and web)
  Future<String?> uploadProfilePicture(dynamic imageFile, String userId) async {
    final supabaseClient = _supabase;
    if (supabaseClient == null) {
      throw Exception('Supabase is not initialized. Please configure Supabase in supabase_config.dart');
    }

    try {
      final String fileName = 'profile_$userId.jpg';
      final String filePath = 'profile_pictures/$fileName';

      // Handle both File (mobile) and XFile (web)
      Uint8List fileBytes;
      if (imageFile is File) {
        fileBytes = await imageFile.readAsBytes();
      } else if (imageFile is XFile) {
        fileBytes = await imageFile.readAsBytes();
      } else {
        throw Exception('Invalid image file type');
      }

      // ===== IMAGE VALIDATION (NEW) =====
      // 1. Check file size (max 5MB)
      const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
      if (fileBytes.length > maxSizeInBytes) {
        final sizeInMB = (fileBytes.length / 1024 / 1024).toStringAsFixed(1);
        throw Exception(
          'Image is too large ($sizeInMB MB). Please choose an image smaller than 5MB.'
        );
      }

      // 2. Check MIME type (only allow images)
      String? mimeType;
      if (imageFile is XFile) {
        mimeType = imageFile.mimeType;
      }

      // Validate MIME type if available
      if (mimeType != null) {
        final allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
        if (!allowedTypes.contains(mimeType.toLowerCase())) {
          throw Exception(
            'Invalid file type. Only JPG, PNG, and WebP images are allowed.'
          );
        }
      }

      print('✅ Image validation passed: ${(fileBytes.length / 1024).toStringAsFixed(0)} KB');
      // ===== END VALIDATION =====

      // Upload file to Supabase Storage
      await supabaseClient.storage
          .from('vibenou-profiles') // Your bucket name
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true, // Overwrites existing file
            ),
          );

      // Get public URL
      final String publicUrl = supabaseClient.storage
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
    final supabaseClient = _supabase;
    if (supabaseClient == null) {
      throw Exception('Supabase is not initialized. Please configure Supabase in supabase_config.dart');
    }

    try {
      final String fileName = 'profile_$userId.jpg';
      final String filePath = 'profile_pictures/$fileName';

      await supabaseClient.storage
          .from('vibenou-profiles')
          .remove([filePath]);
    } catch (e) {
      print('Error deleting profile picture: $e');
      rethrow;
    }
  }

  // Get profile picture URL
  String? getProfilePictureUrl(String userId) {
    final supabaseClient = _supabase;
    if (supabaseClient == null) {
      print('⚠️ Supabase is not initialized');
      return null;
    }

    final String fileName = 'profile_$userId.jpg';
    final String filePath = 'profile_pictures/$fileName';

    return supabaseClient.storage
        .from('vibenou-profiles')
        .getPublicUrl(filePath);
  }
}
