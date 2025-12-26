import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

class SupabaseImageService {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (e) {
      AppLogger.info('⚠️ Supabase not initialized');
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
      AppLogger.info('Error picking image: $e');
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
      AppLogger.info('Error taking photo: $e');
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

      AppLogger.info('✅ Image validation passed: ${(fileBytes.length / 1024).toStringAsFixed(0)} KB');
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
      AppLogger.info('Error uploading profile picture: $e');
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
      AppLogger.info('Error deleting profile picture: $e');
      rethrow;
    }
  }

  // Get profile picture URL
  String? getProfilePictureUrl(String userId) {
    final supabaseClient = _supabase;
    if (supabaseClient == null) {
      AppLogger.info('⚠️ Supabase is not initialized');
      return null;
    }

    final String fileName = 'profile_$userId.jpg';
    final String filePath = 'profile_pictures/$fileName';

    return supabaseClient.storage
        .from('vibenou-profiles')
        .getPublicUrl(filePath);
  }

  /// Upload chat image to Supabase Storage
  ///
  /// Uploads images sent in chat conversations to a separate bucket/folder
  /// from profile pictures for better organization.
  ///
  /// [imageFile] - The image file to upload (File or XFile)
  /// [userId] - The ID of the user sending the image
  /// Returns the public URL of the uploaded image
  Future<String?> uploadChatImage(dynamic imageFile, String userId) async {
    final supabaseClient = _supabase;
    if (supabaseClient == null) {
      throw Exception('Supabase is not initialized. Please configure Supabase in supabase_config.dart');
    }

    try {
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final String fileName = 'chat_${userId}_$timestamp.jpg';
      final String filePath = 'chat_images/$fileName';

      // Handle both File (mobile) and XFile (web)
      Uint8List fileBytes;
      if (imageFile is File) {
        fileBytes = await imageFile.readAsBytes();
      } else if (imageFile is XFile) {
        fileBytes = await imageFile.readAsBytes();
      } else {
        throw Exception('Invalid image file type');
      }

      // ===== IMAGE VALIDATION =====
      // 1. Check file size (max 10MB for chat images)
      const maxSizeInBytes = 10 * 1024 * 1024; // 10MB
      if (fileBytes.length > maxSizeInBytes) {
        final sizeInMB = (fileBytes.length / 1024 / 1024).toStringAsFixed(1);
        throw Exception(
          'Image is too large ($sizeInMB MB). Please choose an image smaller than 10MB.'
        );
      }

      // 2. Check MIME type (only allow images)
      String? mimeType;
      if (imageFile is XFile) {
        mimeType = imageFile.mimeType;
      }

      // Validate MIME type if available
      if (mimeType != null) {
        final allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'];
        if (!allowedTypes.contains(mimeType.toLowerCase())) {
          throw Exception(
            'Invalid file type. Only JPG, PNG, WebP, and GIF images are allowed.'
          );
        }
      }

      AppLogger.info('✅ Chat image validation passed: ${(fileBytes.length / 1024).toStringAsFixed(0)} KB');
      // ===== END VALIDATION =====

      // Upload file to Supabase Storage
      await supabaseClient.storage
          .from('vibenou-profiles') // Using same bucket, different folder
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false, // Don't overwrite - each image is unique
            ),
          );

      // Get public URL
      final String publicUrl = supabaseClient.storage
          .from('vibenou-profiles')
          .getPublicUrl(filePath);

      AppLogger.info('✅ Chat image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      AppLogger.error('Error uploading chat image: $e');
      rethrow;
    }
  }

  /// Delete chat image from Supabase Storage
  ///
  /// [imageUrl] - The public URL of the image to delete
  Future<void> deleteChatImage(String imageUrl) async {
    final supabaseClient = _supabase;
    if (supabaseClient == null) {
      throw Exception('Supabase is not initialized');
    }

    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      // Find the path after 'vibenou-profiles'
      final bucketIndex = pathSegments.indexOf('vibenou-profiles');
      if (bucketIndex == -1) {
        throw Exception('Invalid image URL format');
      }

      final filePath = pathSegments.skip(bucketIndex + 1).join('/');

      await supabaseClient.storage
          .from('vibenou-profiles')
          .remove([filePath]);

      AppLogger.info('✅ Chat image deleted: $filePath');
    } catch (e) {
      AppLogger.error('Error deleting chat image: $e');
      rethrow;
    }
  }
}
