import 'package:flutter/material.dart';
import '../models/favorite_model.dart';
import 'package:intl/intl.dart'; // For date formatting

class FavoriteCard extends StatelessWidget {
  final Favorite favorite;
  final VoidCallback? onCallPressed;
  final VoidCallback? onSmsPressed;
  final VoidCallback? onTap;

  const FavoriteCard({
    Key? key,
    required this.favorite,
    this.onCallPressed,
    this.onSmsPressed,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 16),
                  _buildContactInfo(),
                  const Spacer(),
                  _buildInteractionStats(),
                ],
              ),
              const SizedBox(height: 12),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 30,
      backgroundImage: favorite.avatar != null
          ? MemoryImage(favorite.avatar!)
          : null,
      child: favorite.avatar == null
          ? Text(favorite.name.substring(0, 1),
              style: const TextStyle(fontSize: 24))
          : null,
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          favorite.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Last interaction: ${_formatDate(favorite.lastInteraction)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInteractionStats() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.call, size: 16, color: Colors.green),
            const SizedBox(width: 4),
            Text(favorite.callCount.toString()),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.message, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Text(favorite.smsCount.toString()),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.call, size: 20),
          label: const Text('Call'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          onPressed: onCallPressed,
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.message, size: 20),
          label: const Text('SMS'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          onPressed: onSmsPressed,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}