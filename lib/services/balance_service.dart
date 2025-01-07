import 'package:cloud_firestore/cloud_firestore.dart';

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

    return balances;
  }

  static List<Map<String, dynamic>> calculatePayments(Map<String, double> balances) {
    List<Map<String, dynamic>> payments = [];

    // Créer deux listes: débiteurs et créditeurs avec typage explicite
    var debtors = balances.entries
        .where((e) => e.value < 0)
        .map((e) => {
              'name': e.key,
              'amount': e.value.abs(),
            })
        .toList();
    var creditors = balances.entries
        .where((e) => e.value > 0)
        .map((e) => {
              'name': e.key,
              'amount': e.value,
            })
        .toList();

    // Trier par montant décroissant avec cast explicite
    debtors.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    creditors.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

    while (debtors.isNotEmpty && creditors.isNotEmpty) {
      var debtor = debtors[0];
      var creditor = creditors[0];

      // Calculer le montant du remboursement avec cast explicite
      double paymentAmount = (debtor['amount'] as double) < (creditor['amount'] as double)
          ? (debtor['amount'] as double)
          : (creditor['amount'] as double);

      payments.add({
        'from': debtor['name'],
        'to': creditor['name'],
        'amount': paymentAmount,
      });

      // Mettre à jour les montants
      debtor['amount'] = (debtor['amount'] as double) - paymentAmount;
      creditor['amount'] = (creditor['amount'] as double) - paymentAmount;

      // Retirer les personnes qui ont soldé leur compte
      if ((debtor['amount'] as double) < 0.01) debtors.removeAt(0);
      if ((creditor['amount'] as double) < 0.01) creditors.removeAt(0);
    }

    return payments;
  }
}
