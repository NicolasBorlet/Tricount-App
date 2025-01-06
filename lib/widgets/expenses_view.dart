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

        // Calcul des totaux
        double totalExpenses = 0;
        double myExpenses = 0;
        for (var expense in expenses) {
          final data = expense.data() as Map<String, dynamic>;
          final value = double.tryParse(data['value'].toString()) ?? 0;
          totalExpenses += value;
          if (data['paidBy'] == 'Julia') { // Remplace par le nom de l'utilisateur actuel
            myExpenses += value;
          }
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Mes dépenses',
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${myExpenses.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Dépenses totales',
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${totalExpenses.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GroupedExpensesList(expenses: expenses),
            ),
          ],
        );
      },
    );
  }
}
