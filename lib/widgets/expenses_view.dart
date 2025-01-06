import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpensesView extends StatelessWidget {
  final String tricountId;

  const ExpensesView({
    super.key,
    required this.tricountId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tricounts')
          .doc(tricountId)
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
  }
}
