import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact_model.dart';

class ContactDetailView extends StatelessWidget {
  final Contact contact;

  const ContactDetailView({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(contact.displayName ?? 'Contact Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Implement edit functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            if (contact.phones?.isNotEmpty ?? false) _buildPhoneSection(context),
            if (contact.emails?.isNotEmpty ?? false) _buildEmailSection(context),
            const SizedBox(height: 24),
            _buildMetadataSection(context),
          ],
        ),
      ),
      floatingActionButton: (contact.phones?.isNotEmpty ?? false)
          ? FloatingActionButton(
              onPressed: () async {
                final number = contact.phones!.first.value ?? '';
                final uri = Uri.parse('sms:${number.replaceAll(' ', '')}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Icon(Icons.message),
              backgroundColor: theme.colorScheme.primary,
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Hero(
      tag: 'contact-${contact.identifier}',
      child: Center(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: isDarkMode 
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.primaryContainer,
                backgroundImage: contact.avatar != null
                    ? MemoryImage(contact.avatar!)
                    : null,
                child: contact.avatar == null
                    ? Text(
                        contact.displayName?.substring(0, 1).toUpperCase() ?? '?',
                        style: TextStyle(
                          fontSize: 48,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              contact.displayName ?? 'Unknown',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            if (contact.phones?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  contact.phones!.first.value ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'PHONE NUMBERS',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            for (final phone in contact.phones!)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phone,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(
                  phone.value ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
                subtitle: Text(
                  phone.label?.toUpperCase() ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.message,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () async {
                        final number = phone.value ?? '';
                        final uri = Uri.parse('sms:${number.replaceAll(' ', '')}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.call,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () async {
                        final number = phone.value ?? '';
                        final uri = Uri.parse('tel:${number.replaceAll(' ', '')}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'EMAIL ADDRESSES',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            for (final email in contact.emails!)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.email,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                title: Text(
                  email.value ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
                subtitle: Text(
                  email.label?.toUpperCase() ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.mail_outline,
                    color: theme.colorScheme.secondary,
                  ),
                  onPressed: () {
                    // Implement email action
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'METADATA',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              title: const Text(
                'Created',
                style: TextStyle(fontSize: 16),
              ),
              subtitle: Text(
                contact.createdAt != null
                    ? DateFormat('MMMM d, y - HH:mm').format(contact.createdAt!)
                    : 'Unknown',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.update,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              title: const Text(
                'Last Updated',
                style: TextStyle(fontSize: 16),
              ),
              subtitle: Text(
                contact.updatedAt != null
                    ? DateFormat('MMMM d, y - HH:mm').format(contact.updatedAt!)
                    : 'Unknown',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}