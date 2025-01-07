import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tricount_detail_screen.dart';  // Assurez-vous que ce fichier existe

class TricountsScreen extends StatelessWidget {
  const TricountsScreen({super.key});

  Future<void> _showAddTricountDialog(BuildContext context) async {
    String? tricountName;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau Tricount'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nom du tricount',
          ),
          onChanged: (value) => tricountName = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              if (tricountName?.isNotEmpty ?? false) {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser != null) {
                  await FirebaseFirestore.instance.collection('tricounts').add({
                    'name': tricountName,
                    'createdAt': FieldValue.serverTimestamp(),
                    'participants': [
                      {'id': currentUser.uid, 'name': 'Votre Nom'}, // Remplacez par le nom réel
                      // Ajoutez d'autres participants si nécessaire
                    ],
                    'participantIds': [currentUser.uid],
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tricounts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tricounts')
            .where('participantIds', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return const Center(child: Text('Une erreur est survenue'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tricounts = snapshot.data!.docs;
          print('Found ${tricounts.length} tricounts');
          // Optionnel : Afficher les tricounts dans la console
          for (var tricount in tricounts) {
            print('Tricount: ${tricount.data()}');
          }

          return ListView.builder(
            itemCount: tricounts.length,
            itemBuilder: (context, index) {
              final tricount = tricounts[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    tricount['name'] ?? 'Sans nom',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TricountDetailScreen(
                        tricountId: tricounts[index].id,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTricountDialog(context),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
