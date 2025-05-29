import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import 'package:intl/intl.dart'; // For date formatting

class ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;
  final bool isFavorite;
  final ValueChanged<bool>? onFavoriteChanged;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onTap,
    this.isFavorite = false,
    this.onFavoriteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 16),
              _buildContactInfo(),
              const Spacer(),
              _buildFavoriteButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundImage: contact.avatar != null 
          ? MemoryImage(contact.avatar!) 
          : null,
      child: contact.avatar == null
          ? Text(contact.displayName?.substring(0, 1) ?? '?',
              style: const TextStyle(fontSize: 20))
          : null,
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          contact.displayName ?? 'Unknown',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (contact.phones?.isNotEmpty ?? false)
          Text(
            contact.phones!.first.value ?? '',
            style: const TextStyle(color: Colors.grey),
          ),
        if (contact.createdAt != null)
          Text(
            'Created: ${DateFormat('MMM d, y').format(contact.createdAt!)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildFavoriteButton() {
    if (onFavoriteChanged == null) return const SizedBox();

    return IconButton(
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite ? Colors.amber : Colors.grey,
      ),
      onPressed: () => onFavoriteChanged?.call(!isFavorite),
    );
  }
}