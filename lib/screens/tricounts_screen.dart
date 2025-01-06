import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tricount_detail_screen.dart';  // Ajoute cette ligne

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
                await FirebaseFirestore.instance.collection('tricounts').add({
                  'name': tricountName,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) Navigator.pop(context);
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
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tricounts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Une erreur est survenue'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tricounts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tricounts.length,
            itemBuilder: (context, index) {
              final tricount = tricounts[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(tricount['name'] ?? 'Sans nom'),
                leading: const Icon(Icons.account_balance_wallet),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TricountDetailScreen(
                      tricountId: tricounts[index].id,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
