import 'package:flutter/material.dart';
import '../services/balance_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BalanceView extends StatelessWidget {
  final String tricountId;

  const BalanceView({
    super.key,
    required this.tricountId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: BalanceService.calculateBalances(tricountId),
      builder: (context, balanceSnapshot) {
        if (balanceSnapshot.hasError) {
          return const Center(child: Text('Une erreur est survenue'));
        }

        if (!balanceSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final balances = balanceSnapshot.data!;
        final currentUser = FirebaseAuth.instance.currentUser;

        return ListView.builder(
          itemCount: balances.length,
          itemBuilder: (context, index) {
            final name = balances.keys.elementAt(index);
            final balance = balances[name]!;
            final isCurrentUser = currentUser?.displayName == name;

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8
              ),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(name[0].toUpperCase()),
                ),
                title: Text(
                  isCurrentUser ? 'Vous' : name,
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
