import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'expense_detail_sheet.dart';

class GroupedExpensesList extends StatelessWidget {
  final List<QueryDocumentSnapshot> expenses;
  final String tricountId;

  const GroupedExpensesList({
    super.key,
    required this.expenses,
    required this.tricountId,
  });

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Map<String, List<QueryDocumentSnapshot>> _groupExpensesByDate() {
    final groupedExpenses = <String, List<QueryDocumentSnapshot>>{};

    for (var expense in expenses) {
      final data = expense.data() as Map<String, dynamic>;
      final createdAt = data['createdAt'] as Timestamp?;

      if (createdAt != null) {
        final date = createdAt.toDate();
        final dateString = _formatDate(date);

        groupedExpenses.putIfAbsent(dateString, () => []);
        groupedExpenses[dateString]!.add(expense);
      }
    }

    return groupedExpenses;
  }

  @override
  Widget build(BuildContext context) {
    final groupedExpenses = _groupExpensesByDate();

    return ListView.builder(
      itemCount: groupedExpenses.length,
      itemBuilder: (context, index) {
        final dateString = groupedExpenses.keys.elementAt(index);
        final dayExpenses = groupedExpenses[dateString]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                dateString,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...dayExpenses.map((expense) {
              final data = expense.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'Sans nom'),
                subtitle: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      const TextSpan(text: 'Payé par: '),
                      TextSpan(
                        text: data['paidBy'] ?? 'Non spécifié',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                trailing: Text(
                  '${data['value']?.toString() ?? '0'} €',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ExpenseDetailSheet(
                      expense: data,
                      tricountId: tricountId,
                    ),
                  );
                },
              );
            }),
          ],
        );
      },
    );
  }
}
