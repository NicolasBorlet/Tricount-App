import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/expenses_view.dart';
import '../widgets/balance_view.dart';
import '../widgets/photos_view.dart';
import '../services/photo_service.dart';

class TricountDetailScreen extends StatefulWidget {
  final String tricountId;

  const TricountDetailScreen({
    super.key,
    required this.tricountId,
  });

  @override
  State<TricountDetailScreen> createState() => _TricountDetailScreenState();
}

class _TricountDetailScreenState extends State<TricountDetailScreen> {
  int _selectedSegment = 0;

  Future<void> _showAddExpenseDialog(BuildContext context) async {
    String? expenseName;
    String? paidBy;
    String? value;
    DateTime selectedDate = DateTime.now();
    XFile? selectedImage;
    StateSetter? dialogState;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          dialogState = setDialogState;
          return AlertDialog(
            title: const Text('Nouvelle dépense'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Nom de la dépense',
                  ),
                  onChanged: (val) => expenseName = val,
                ),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Payé par',
                  ),
                  onChanged: (val) => paidBy = val,
                ),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Montant',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => value = val,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Date: '),
                    TextButton(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2025),
                        );
                        if (picked != null) {
                          dialogState?.call(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      child: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final image = await PhotoService.pickImage();
                    if (image != null) {
                      dialogState?.call(() {
                        selectedImage = image;
                      });
                    }
                  },
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(selectedImage != null ? 'Photo sélectionnée' : 'Ajouter une photo'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  if (expenseName?.isNotEmpty ?? false) {
                    final currentUser = FirebaseAuth.instance.currentUser;

                    // Créer d'abord la dépense
                    final expenseRef = await FirebaseFirestore.instance
                        .collection('tricounts')
                        .doc(widget.tricountId)
                        .collection('expenses')
                        .add({
                          'name': expenseName,
                          'paidBy': paidBy,
                          'userId': currentUser?.uid,
                          'value': value,
                          'createdAt': Timestamp.fromDate(selectedDate),
                        });

                    // Upload la photo si elle existe
                    if (selectedImage != null) {
                      final photoUrl = await PhotoService.uploadExpenseImage(
                        widget.tricountId,
                        expenseRef.id,
                        selectedImage!,
                      );

                      if (photoUrl != null) {
                        await expenseRef.update({'photoUrl': photoUrl});
                      }
                    }

                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('Ajouter'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showInviteParticipantDialog(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await showDialog(
      context: context,
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('friends')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AlertDialog(
              content: Center(child: CircularProgressIndicator()),
            );
          }

          final friends = snapshot.data!.docs;

          return AlertDialog(
            title: const Text('Inviter des participants'),
            content: SizedBox(
              width: double.maxFinite,
              child: friends.isEmpty
                  ? const Text('Vous n\'avez pas encore d\'amis')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index].data() as Map<String, dynamic>;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                              friend['photoUrl'] ?? 'https://via.placeholder.com/150',
                            ),
                          ),
                          title: Text(friend['name'] ?? ''),
                          onTap: () => _inviteParticipant(
                            context,
                            friend['userId'],
                            friend['name'],
                            friend['photoUrl'],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _inviteParticipant(
    BuildContext context,
    String userId,
    String name,
    String? photoUrl,
  ) async {
    try {
      final tricountDoc = await FirebaseFirestore.instance
          .collection('tricounts')
          .doc(widget.tricountId)
          .get();

      final data = tricountDoc.data();
      final List<String> participantIds = List<String>.from(data?['participantIds'] ?? []);

      if (participantIds.contains(userId)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cette personne participe déjà')),
          );
        }
        return;
      }

      // Vérifier si une invitation est déjà en attente
      final existingInvite = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tricountInvites')
          .doc(widget.tricountId)
          .get();

      if (existingInvite.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Une invitation est déjà en attente')),
          );
        }
        return;
      }

      // Envoyer l'invitation
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tricountInvites')
          .doc(widget.tricountId)
          .set({
        'tricountId': widget.tricountId,
        'tricountName': data?['name'],
        'invitedBy': FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation envoyée')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi de l\'invitation')),
        );
      }
    }
  }

  Future<void> _leaveTricountDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter le tricount'),
        content: const Text('Êtes-vous sûr de vouloir quitter ce tricount ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _leaveTricount(context);
    }
  }

  Future<void> _leaveTricount(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final tricountRef = FirebaseFirestore.instance
          .collection('tricounts')
          .doc(widget.tricountId);

      final tricountDoc = await tricountRef.get();
      final data = tricountDoc.data();

      final List<String> participantIds = List<String>.from(data?['participantIds'] ?? []);
      final List<Map<String, dynamic>> participants = List<Map<String, dynamic>>.from(data?['participants'] ?? []);

      participantIds.remove(currentUser.uid);
      participants.removeWhere((p) => p['userId'] == currentUser.uid);

      await tricountRef.update({
        'participantIds': participantIds,
        'participants': participants,
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous avez quitté le tricount')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la sortie du tricount')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tricounts')
              .doc(widget.tricountId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text('Chargement...');
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            return Text(data?['name'] ?? 'Sans nom');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showInviteParticipantDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _leaveTricountDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Dépenses'),
                  icon: Icon(Icons.receipt_long),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Equilibre'),
                  icon: Icon(Icons.balance),
                ),
                ButtonSegment(
                  value: 2,
                  label: Text('Photos'),
                  icon: Icon(Icons.photo_library),
                ),
              ],
              selected: {_selectedSegment},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _selectedSegment = newSelection.first;
                });
              },
            ),
          ),
          Expanded(
            child: _buildSelectedView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedSegment) {
      case 0:
        return ExpensesView(tricountId: widget.tricountId);
      case 1:
        return BalanceView(tricountId: widget.tricountId);
      case 2:
        return PhotosView(tricountId: widget.tricountId);
      default:
        return const SizedBox.shrink();
    }
  }
}
