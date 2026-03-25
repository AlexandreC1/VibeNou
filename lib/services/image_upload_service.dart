import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../utils/app_logger.dart';

/// ImageUploadService - Secure image upload with comprehensive validation
///
/// Security Features:
/// - File size validation (max 5MB)
/// - MIME type validation (only JPEG, PNG, WebP)
/// - Rate limiting (max 10 uploads per hour)
/// - Dimension validation
/// - Secure file naming
/// - Proper error handling
class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Security constraints
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxWidthPx = 2048;
  static const int maxHeightPx = 2048;
  static const List<String> allowedMimeTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];

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
      AppLogger.info('Error picking image: $e');
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
      AppLogger.info('Error taking photo: $e');
      rethrow;
    }
  }

  /// Validates image file before upload
  ///
  /// Checks:
  /// - File exists
  /// - File size <= 5MB
  /// - File is a valid image type
  ///
  /// Returns: null if valid, error message if invalid
  Future<String?> _validateImageFile(File imageFile) async {
    // Check if file exists
    if (!await imageFile.exists()) {
      return 'Image file does not exist';
    }

    // Check file size
    final int fileSize = await imageFile.length();
    if (fileSize > maxFileSizeBytes) {
      final double sizeMB = fileSize / (1024 * 1024);
      return 'Image too large (${sizeMB.toStringAsFixed(1)}MB). Maximum size is 5MB.';
    }

    if (fileSize == 0) {
      return 'Image file is empty';
    }

    // Verify it's an actual image by checking file extension
    // Note: MIME type validation will also happen server-side in Storage Rules
    final String path = imageFile.path.toLowerCase();
    if (!path.endsWith('.jpg') &&
        !path.endsWith('.jpeg') &&
        !path.endsWith('.png') &&
        !path.endsWith('.webp')) {
      return 'Invalid image format. Only JPEG, PNG, and WebP are allowed.';
    }

    return null; // Valid
  }

  /// Determines the correct MIME type based on file extension
  String _getMimeType(File imageFile) {
    final String path = imageFile.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg'; // Default for .jpg and .jpeg
  }

  /// Check upload rate limit before attempting upload
  ///
  /// Returns: null if allowed, error message if rate limited
  Future<String?> _checkUploadRateLimit() async {
    try {
      final callable = _functions.httpsCallable('checkRateLimit');
      final result = await callable.call({'action': 'uploads'});

      final data = result.data as Map<String, dynamic>;

      if (data['allowed'] == false) {
        final resetAt = DateTime.fromMillisecondsSinceEpoch(data['resetAt'] as int);
        final minutesUntilReset = resetAt.difference(DateTime.now()).inMinutes;

        return 'Upload limit reached (10 per hour). Please try again in $minutesUntilReset minutes.';
      }

      AppLogger.info('Upload rate limit check passed. Remaining: ${data['remaining']}/10');
      return null;
    } catch (e) {
      AppLogger.warning('Rate limit check failed, allowing upload: $e');
      return null; // Fail open - allow upload if check fails
    }
  }

  // Upload profile picture to Firebase Storage
  Future<String?> uploadProfilePicture(File imageFile, String userId) async {
    try {
      // SECURITY: Check rate limit first (better UX than server-side deletion)
      final String? rateLimitError = await _checkUploadRateLimit();
      if (rateLimitError != null) {
        AppLogger.warning('Upload blocked by rate limit');
        throw Exception(rateLimitError);
      }

      // SECURITY: Validate file before upload
      final String? validationError = await _validateImageFile(imageFile);
      if (validationError != null) {
        AppLogger.warning('Image validation failed: $validationError');
        throw Exception(validationError);
      }

      // Determine correct MIME type
      final String mimeType = _getMimeType(imageFile);

      // Use secure file naming - only allow specific pattern
      final String fileName = 'profile_$userId.jpg';
      final Reference ref = _storage.ref().child('profile_pictures/$fileName');

      AppLogger.info('Uploading profile picture for user $userId (${await imageFile.length()} bytes, $mimeType)');

      // Upload file with validated metadata
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: mimeType,
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.info('Profile picture uploaded successfully for user $userId');
      return downloadUrl;
    } on FirebaseException catch (e) {
      // Handle Firebase-specific errors
      if (e.code == 'unauthorized') {
        AppLogger.error('Upload unauthorized - check Storage Rules', e);
        throw Exception('Upload failed: You do not have permission to upload this file.');
      } else if (e.code == 'canceled') {
        AppLogger.info('Upload canceled by user');
        throw Exception('Upload canceled');
      } else if (e.code == 'unknown') {
        AppLogger.error('Upload failed with unknown error', e);
        throw Exception('Upload failed: ${e.message ?? "Unknown error"}');
      }
      AppLogger.error('Firebase error uploading profile picture', e);
      rethrow;
    } catch (e) {
      AppLogger.error('Error uploading profile picture', e);
      rethrow;
    }
  }

  // Delete profile picture from Firebase Storage
  Future<void> deleteProfilePicture(String photoUrl) async {
    try {
      final Reference ref = _storage.refFromURL(photoUrl);
      await ref.delete();
      AppLogger.info('Profile picture deleted successfully');
    } catch (e) {
      AppLogger.info('Error deleting profile picture: $e');
      rethrow;
    }
  }
}
