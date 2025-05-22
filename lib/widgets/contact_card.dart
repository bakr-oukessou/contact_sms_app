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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: colorScheme.primary.withOpacity(0.1),
        highlightColor: colorScheme.primary.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(theme),
              const SizedBox(width: 16),
              _buildContactInfo(theme),
              const Spacer(),
              _buildFavoriteButton(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: contact.avatar == null
            ? LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              )
            : null,
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.transparent,
        foregroundImage: contact.avatar != null 
            ? MemoryImage(contact.avatar!) 
            : null,
        child: contact.avatar == null
            ? Text(
                contact.displayName?.substring(0, 1).toUpperCase() ?? '?',
                style: TextStyle(
                  fontSize: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildContactInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          contact.displayName ?? 'Unknown',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (contact.phones?.isNotEmpty ?? false) ...[
          const SizedBox(height: 4),
          Text(
            contact.phones!.first.value ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
        if (contact.createdAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Added ${DateFormat('MMM d, y').format(contact.createdAt!)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFavoriteButton(ColorScheme colorScheme) {
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
        color: isFavorite ? colorScheme.primary : colorScheme.outline,
        size: 24,
      ),
      onPressed: () => onFavoriteChanged?.call(!isFavorite),
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      splashRadius: 20,
    );
  }
}