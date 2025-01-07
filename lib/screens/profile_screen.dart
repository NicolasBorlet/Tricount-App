import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Une erreur est survenue'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Photo de profil
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    userData?['photoUrl'] ?? 'https://via.placeholder.com/150',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Informations personnelles
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations personnelles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(userData?['name'] ?? 'Non renseigné'),
                        trailing: const Icon(Icons.edit),
                        onTap: () {
                          // TODO: Implémenter l'édition du nom
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: Text(user?.email ?? 'Non renseigné'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Liste d'amis
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mes amis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.person_add),
                            onPressed: () => _showAddFriendDialog(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user?.uid)
                            .collection('friends')
                            .snapshots(),
                        builder: (context, friendsSnapshot) {
                          if (!friendsSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final friends = friendsSnapshot.data!.docs;

                          if (friends.isEmpty) {
                            return const Center(
                              child: Text('Aucun ami pour le moment'),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: friends.length,
                            itemBuilder: (context, index) {
                              final friend = friends[index].data()
                                  as Map<String, dynamic>;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    friend['photoUrl'] ??
                                        'https://via.placeholder.com/150',
                                  ),
                                ),
                                title: Text(friend['name'] ?? ''),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    // TODO: Implémenter la suppression d'ami
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddFriendDialog(BuildContext context) async {
    final TextEditingController emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un ami'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            hintText: 'Email de votre ami',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await _sendFriendRequest(context, emailController.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFriendRequest(BuildContext context, String friendEmail) async {
    try {
      // Chercher l'utilisateur par email
      final QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: friendEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utilisateur non trouvé')),
          );
        }
        return;
      }

      final friendDoc = userQuery.docs.first;
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Vérifier si la demande existe déjà
      final existingRequest = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendDoc.id)
          .collection('friendRequests')
          .doc(currentUser.uid)
          .get();

      if (existingRequest.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demande déjà envoyée')),
          );
        }
        return;
      }

      // Récupérer les données de l'utilisateur courant
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      // Envoyer la demande d'ami
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendDoc.id)
          .collection('friendRequests')
          .doc(currentUser.uid)
          .set({
        'senderId': currentUser.uid,
        'senderName': currentUserDoc.data()?['name'] ?? 'Utilisateur',
        'senderPhotoUrl': currentUserDoc.data()?['photoUrl'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande d\'ami envoyée')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi de la demande')),
        );
      }
    }
  }
}
