import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Amis'),
            Tab(text: 'Tricounts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FriendRequestsTab(),
          _TricountInvitesTab(),
        ],
      ),
    );
  }
}

class _FriendRequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
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
                subtitle: const Text('Souhaite vous ajouter comme ami'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _acceptFriendRequest(
                        context,
                        requests[index].id,
                        request['senderId'],
                        request['senderName'],
                        request['senderPhotoUrl'],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectFriendRequest(
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
    );
  }

  Future<void> _acceptFriendRequest(
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

  Future<void> _rejectFriendRequest(BuildContext context, String requestId) async {
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

class _TricountInvitesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('tricountInvites')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final invites = snapshot.data!.docs;

        if (invites.isEmpty) {
          return const Center(
            child: Text('Aucune invitation en attente'),
          );
        }

        return ListView.builder(
          itemCount: invites.length,
          itemBuilder: (context, index) {
            final invite = invites[index].data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: ListTile(
                title: Text(invite['tricountName'] ?? 'Sans nom'),
                subtitle: Text('Invité par ${invite['invitedBy']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _acceptTricountInvite(
                        context,
                        invites[index].id,
                        invite['tricountId'],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectTricountInvite(
                        context,
                        invites[index].id,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _acceptTricountInvite(
    BuildContext context,
    String inviteId,
    String tricountId,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Ajouter l'utilisateur au tricount
      final tricountRef = FirebaseFirestore.instance
          .collection('tricounts')
          .doc(tricountId);

      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final tricountDoc = await tricountRef.get();
      final data = tricountDoc.data();

      final List<String> participantIds = List<String>.from(data?['participantIds'] ?? []);
      final List<Map<String, dynamic>> participants = List<Map<String, dynamic>>.from(data?['participants'] ?? []);

      participantIds.add(currentUser.uid);
      participants.add({
        'userId': currentUser.uid,
        'name': userData.data()?['name'] ?? 'Unknown',
        'photoUrl': userData.data()?['photoUrl'],
      });

      batch.update(tricountRef, {
        'participantIds': participantIds,
        'participants': participants,
      });

      // Supprimer l'invitation
      batch.delete(
        FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('tricountInvites')
            .doc(inviteId),
      );

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation acceptée')),
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

  Future<void> _rejectTricountInvite(BuildContext context, String inviteId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('tricountInvites')
          .doc(inviteId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation rejetée')),
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
