import 'package:flutter/material.dart';

class BalanceView extends StatelessWidget {
  final String tricountId;

  const BalanceView({
    super.key,
    required this.tricountId,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Vue Equilibre'),
    );
  }
}
