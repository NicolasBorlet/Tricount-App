import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExpenseDetailSheet extends StatelessWidget {
  final Map<String, dynamic> expense;
  final String tricountId;

  const ExpenseDetailSheet({
    super.key,
    required this.expense,
    required this.tricountId,
  });

  @override
  Widget build(BuildContext context) {
    final dateTime = (expense['createdAt'] as Timestamp).toDate();
    final formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                expense['name'] ?? 'Sans nom',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Montant', '${expense['value']} €'),
          _buildInfoRow('Payé par', expense['paidBy'] ?? 'Non spécifié'),
          _buildInfoRow('Date', formattedDate),
          const SizedBox(height: 16),
          if (expense['photoUrl'] != null) ...[
            const Text(
              'Justificatif',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showFullScreenImage(context, expense['photoUrl']),
              child: Hero(
                tag: expense['photoUrl'],
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    expense['photoUrl'],
                    fit: BoxFit.cover,
                    height: 200,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Hero(
              tag: imageUrl,
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }
}
