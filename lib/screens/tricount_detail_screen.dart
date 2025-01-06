import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/expenses_view.dart';
import '../widgets/balance_view.dart';
import '../widgets/photos_view.dart';

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
                          initialDate: selectedDate.isAfter(DateTime(2025))
                              ? DateTime(2025)
                              : selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2025, 12, 31),
                        );
                        if (picked != null && picked != selectedDate) {
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
                    await FirebaseFirestore.instance
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
