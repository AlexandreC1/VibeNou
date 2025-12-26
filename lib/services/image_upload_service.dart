import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
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

  // Upload profile picture to Firebase Storage
  Future<String?> uploadProfilePicture(File imageFile, String userId) async {
    try {
      final String fileName = 'profile_$userId.jpg';
      final Reference ref = _storage.ref().child('profile_pictures/$fileName');

      // Upload file
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': userId},
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      AppLogger.info('Error uploading profile picture: $e');
      rethrow;
    }
  }

  // Delete profile picture from Firebase Storage
  Future<void> deleteProfilePicture(String photoUrl) async {
    try {
      final Reference ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      AppLogger.info('Error deleting profile picture: $e');
      rethrow;
    }
  }
}
