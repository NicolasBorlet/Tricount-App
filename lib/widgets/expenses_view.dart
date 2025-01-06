import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'grouped_expenses_list.dart';

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
          .orderBy('createdAt', descending: true)
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

        return GroupedExpensesList(expenses: expenses);
      },
    );
  }
}
