import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BalanceService {
  static Future<Map<String, double>> calculateBalances(String tricountId) async {
    final tricountDoc = await FirebaseFirestore.instance
        .collection('tricounts')
        .doc(tricountId)
        .get();

    // Récupérer les participants et créer les maps de conversion
    final participants = (tricountDoc.data()?['participants'] as List<dynamic>? ?? [])
        .map((p) => p as Map<String, dynamic>)
        .toList();

    final nameToId = {
      for (var p in participants)
        p['name'].toString(): p['id'].toString()
    };

    final idToName = {
      for (var p in participants)
        p['id'].toString(): p['name'].toString()
    };

    // Initialiser les balances avec les noms (pas les IDs)
    Map<String, double> paidAmounts = {};
    for (var participant in participants) {
      paidAmounts[participant['name']] = 0;
    }

    // Récupérer et calculer les dépenses
    final expenses = await FirebaseFirestore.instance
        .collection('tricounts')
        .doc(tricountId)
        .collection('expenses')
        .get();

    double totalAmount = 0;

    // Calculer ce que chacun a payé (en utilisant les noms)
    for (var expense in expenses.docs) {
      final data = expense.data();
      final amount = double.tryParse(data['value'].toString()) ?? 0;
      final paidBy = data['paidBy'] ?? '';

      totalAmount += amount;
      paidAmounts[paidBy] = (paidAmounts[paidBy] ?? 0) + amount;
    }

    // Calculer la part équitable par personne
    final sharePerPerson = totalAmount / participants.length;

    // Calculer les balances finales (en utilisant les noms)
    Map<String, double> balances = {};
    for (var participant in participants) {
      final name = participant['name'];
      final amountPaid = paidAmounts[name] ?? 0;
      balances[name] = amountPaid - sharePerPerson;
    }

    print('Total amount: $totalAmount');
    print('Share per person: $sharePerPerson');
    print('Paid amounts: $paidAmounts');
    print('Final balances: $balances');

    return balances;
  }
}
