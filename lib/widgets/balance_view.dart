import 'package:flutter/material.dart';
import '../services/balance_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BalanceView extends StatefulWidget {
  final String tricountId;

  const BalanceView({
    super.key,
    required this.tricountId,
  });

  @override
  State<BalanceView> createState() => _BalanceViewState();
}

class _BalanceViewState extends State<BalanceView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, double>> _balancesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _balancesFuture = BalanceService.calculateBalances(widget.tricountId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Général',
              icon: Icon(Icons.account_balance),
            ),
            Tab(
              text: AppLocalizations.of(context)!.suggestions,
              icon: Icon(Icons.payment),
            ),
          ],
        ),
        Expanded(
          child: FutureBuilder<Map<String, double>>(
            future: _balancesFuture,
            builder: (context, balanceSnapshot) {
              if (balanceSnapshot.hasError) {
                return Center(child: Text('Erreur: ${balanceSnapshot.error}'));
              }

              if (!balanceSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final balances = balanceSnapshot.data!;
              final payments = BalanceService.calculatePayments(balances);
              final currentUser = FirebaseAuth.instance.currentUser;

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildBalancesList(balances, currentUser),
                  _buildPaymentsList(payments, currentUser),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBalancesList(Map<String, double> balances, User? currentUser) {
    return ListView.builder(
      itemCount: balances.length,
      itemBuilder: (context, index) {
        final name = balances.keys.elementAt(index);
        final balance = balances[name]!;
        final isCurrentUser = currentUser?.displayName == name;

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
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
  }

  Widget _buildPaymentsList(List<Map<String, dynamic>> payments, User? currentUser) {
    if (payments.isEmpty) {
      return const Center(
        child: Text('Aucun remboursement nécessaire'),
      );
    }

    return ListView.builder(
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final payment = payments[index];
        final isCurrentUserPaying = payment['from'] == currentUser?.displayName;
        final isCurrentUserReceiving = payment['to'] == currentUser?.displayName;

        String message;
        if (isCurrentUserPaying) {
          message = 'Vous devez payer ${payment['amount'].toStringAsFixed(2)} € à ${payment['to']}';
        } else if (isCurrentUserReceiving) {
          message = '${payment['from']} doit vous payer ${payment['amount'].toStringAsFixed(2)} €';
        } else {
          message = '${payment['from']} doit payer ${payment['amount'].toStringAsFixed(2)} € à ${payment['to']}';
        }

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: ListTile(
            leading: const Icon(Icons.payment),
            title: Text(message),
          ),
        );
      },
    );
  }
}
