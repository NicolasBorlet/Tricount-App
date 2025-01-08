import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PhotoService {
  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> pickImage() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
  }

  static Future<File?> compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

    var result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 70,
      format: CompressFormat.jpeg,
    );

    return result != null ? File(result.path) : null;
  }

  static Future<String?> uploadExpenseImage(String tricountId, String expenseId, XFile image) async {
    try {
      final File originalFile = File(image.path);
      final File? compressedFile = await compressImage(originalFile);

      if (compressedFile == null) {
        throw Exception('Erreur lors de la compression');
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('tricounts/$tricountId/expenses');

      final imageRef = storageRef.child('$expenseId.jpg');

      await imageRef.putFile(
        compressedFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'originalName': image.name,
            'expenseId': expenseId,
            'compressed': 'true',
          },
        ),
      );

      await compressedFile.delete();
      return await imageRef.getDownloadURL();
    } catch (e) {
      print('Erreur lors de l\'upload: $e');
      return null;
    }
  }

  static Future<List<String>> getPhotos(String tricountId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('tricounts/$tricountId/expenses');

      final ListResult result = await storageRef.listAll();
      return await Future.wait(
        result.items.map((ref) => ref.getDownloadURL()),
      );
    } catch (e) {
      print('Erreur lors de la récupération des photos: $e');
      return [];
    }
  }
}
