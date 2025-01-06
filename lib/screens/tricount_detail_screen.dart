import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                await FirebaseFirestore.instance
                    .collection('tricounts')
                    .doc(widget.tricountId)
                    .collection('expenses')
                    .add({
                      'name': expenseName,
                      'paidBy': paidBy,
                      'value': value,
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedSegment) {
      case 0:
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tricounts')
              .doc(widget.tricountId)
              .collection('expenses')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Une erreur est survenue'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final expenses = snapshot.data!.docs;
            if (expenses.isEmpty) {
              return const Center(child: Text('Aucune dépense'));
            }

            return ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final data = expenses[index].data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(data['name'] ?? 'Sans nom'),
                  subtitle: Text('Payé par: ${data['paidBy'] ?? 'Non spécifié'}'),
                  trailing: Text(
                    '${data['value']?.toString() ?? '0'} €',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            );
          },
        );
      case 1:
        return const Center(child: Text('Vue Equilibre'));
      case 2:
        return const Center(child: Text('Vue Photos'));
      default:
        return const SizedBox.shrink();
    }
  }
}
