import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes d\'amis'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .collection('friendRequests')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Une erreur est survenue'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(
              child: Text('Aucune demande d\'ami en attente'),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      request['senderPhotoUrl'] ?? 'https://via.placeholder.com/150',
                    ),
                  ),
                  title: Text(request['senderName'] ?? 'Utilisateur inconnu'),
                  subtitle: Text('Souhaite vous ajouter comme ami'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _acceptRequest(
                          context,
                          requests[index].id,
                          request['senderId'],
                          request['senderName'],
                          request['senderPhotoUrl'],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _rejectRequest(
                          context,
                          requests[index].id,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _acceptRequest(
    BuildContext context,
    String requestId,
    String senderId,
    String senderName,
    String? senderPhotoUrl,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Ajouter l'ami à la liste d'amis de l'utilisateur courant
      final currentUserFriendRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(senderId);

      batch.set(currentUserFriendRef, {
        'userId': senderId,
        'name': senderName,
        'photoUrl': senderPhotoUrl,
      });

      // Ajouter l'utilisateur courant à la liste d'amis de l'expéditeur
      final senderFriendRef = FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('friends')
          .doc(currentUser.uid);

      final currentUserData = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      batch.set(senderFriendRef, {
        'userId': currentUser.uid,
        'name': currentUserData.data()?['name'] ?? 'Utilisateur',
        'photoUrl': currentUserData.data()?['photoUrl'],
      });

      // Supprimer la demande d'ami
      final requestRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('friendRequests')
          .doc(requestId);

      batch.delete(requestRef);

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande d\'ami acceptée')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'acceptation')),
        );
      }
    }
  }

  Future<void> _rejectRequest(BuildContext context, String requestId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('friendRequests')
          .doc(requestId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande d\'ami rejetée')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du rejet')),
        );
      }
    }
  }
}
