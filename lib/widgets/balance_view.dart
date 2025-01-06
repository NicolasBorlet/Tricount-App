import 'package:flutter/material.dart';
import '../services/balance_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BalanceView extends StatelessWidget {
  final String tricountId;

  const BalanceView({
    super.key,
    required this.tricountId,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<Map<String, double>>(
      future: BalanceService.calculateBalances(tricountId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Une erreur est survenue'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final balances = snapshot.data!;

        return ListView.builder(
          itemCount: balances.length,
          itemBuilder: (context, index) {
            final person = balances.keys.elementAt(index);
            final balance = balances[person]!;
            final isCurrentUser = person == currentUserId;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(person[0].toUpperCase()),
                ),
                title: Text(
                  isCurrentUser ? 'Vous' : person,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  balance > 0
                      ? 'Doit recevoir ${balance.abs().toStringAsFixed(2)} €'
                      : 'Doit payer ${balance.abs().toStringAsFixed(2)} €',
                  style: TextStyle(
                    color: balance > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
