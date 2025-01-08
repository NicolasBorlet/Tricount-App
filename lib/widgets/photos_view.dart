import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhotosView extends StatefulWidget {
  final String tricountId;

  const PhotosView({
    super.key,
    required this.tricountId,
  });

  @override
  State<PhotosView> createState() => _PhotosViewState();
}

class _PhotosViewState extends State<PhotosView> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload en cours...')),
      );

      final storageRef = FirebaseStorage.instance
          .ref()
          .child(widget.tricountId);

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final imageRef = storageRef.child(fileName);

      await imageRef.putFile(File(image.path));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo ajoutée avec succès')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'upload')),
      );
    }
  }

  Future<List<String>> _listPhotos() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('Utilisateur non connecté'); // Debug
        return [];
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child(widget.tricountId);

      final ListResult result = await storageRef.listAll();
      final urls = await Future.wait(
        result.items.map((ref) => ref.getDownloadURL()),
      );

      print('URLs récupérées: $urls'); // Debug
      return urls;
    } catch (e) {
      print('Erreur lors de la récupération des photos: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _pickAndUploadImage,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Ajouter une preuve d\'achat'),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _listPhotos(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Erreur FutureBuilder: ${snapshot.error}'); // Pour le debug
                  return const Center(child: Text('Une erreur est survenue'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final photos = snapshot.data!;

                if (photos.isEmpty) {
                  return const Center(
                    child: Text('Aucune photo'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _showFullScreenImage(context, photos[index]),
                      child: Hero(
                        tag: photos[index],
                        child: Image.network(
                          photos[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Hero(
              tag: imageUrl,
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }
}
