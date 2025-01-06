import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BalanceService {
  static Future<Map<String, double>> calculateBalances(String tricountId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final expenses = await FirebaseFirestore.instance
        .collection('tricounts')
        .doc(tricountId)
        .collection('expenses')
        .get();

    // Total des dépenses
    double totalAmount = 0;
    Map<String, double> paidAmounts = {};

    // Calculer ce que chacun a payé
    for (var expense in expenses.docs) {
      final data = expense.data();
      final amount = double.tryParse(data['value'].toString()) ?? 0;
      final paidBy = data['paidBy'] ?? '';

      totalAmount += amount;
      paidAmounts[paidBy] = (paidAmounts[paidBy] ?? 0) + amount;
    }

    // Calculer ce que chacun devrait payer (partage égal)
    final participants = paidAmounts.keys.toList();
    final sharePerPerson = totalAmount / participants.length;

    // Calculer les balances finales
    Map<String, double> balances = {};
    for (var person in participants) {
      balances[person] = (paidAmounts[person] ?? 0) - sharePerPerson;
    }

    return balances;
  }
}
