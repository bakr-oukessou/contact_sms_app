import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contact_model.dart';

class ContactDetailView extends StatelessWidget {
  final Contact contact;

  const ContactDetailView({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(contact.displayName ?? 'Contact Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (contact.phones?.isNotEmpty ?? false) _buildPhoneSection(),
            if (contact.emails?.isNotEmpty ?? false) _buildEmailSection(),
            const SizedBox(height: 24),
            _buildMetadataSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: contact.avatar != null
                ? MemoryImage(contact.avatar!)
                : null,
            child: contact.avatar == null
                ? Text(
                    contact.displayName?.substring(0, 1) ?? '?',
                    style: const TextStyle(fontSize: 40),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            contact.displayName ?? 'Unknown',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PHONE NUMBERS',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        for (final phone in contact.phones!)
          ListTile(
            leading: const Icon(Icons.phone),
            title: Text(phone.value ?? ''),
            subtitle: Text(phone.label ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {}, // Implement SMS action
            ),
          ),
      ],
    );
  }

  Widget _buildEmailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EMAIL ADDRESSES',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        for (final email in contact.emails!)
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(email.value ?? ''),
            subtitle: Text(email.label ?? ''),
          ),
      ],
    );
  }

  Widget _buildMetadataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'METADATA',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: const Text('Created'),
          subtitle: Text(contact.createdAt != null
              ? DateFormat('MMMM d, y - HH:mm').format(contact.createdAt!)
              : 'Unknown'),
        ),
        ListTile(
          leading: const Icon(Icons.update),
          title: const Text('Last Updated'),
          subtitle: Text(contact.updatedAt != null
              ? DateFormat('MMMM d, y - HH:mm').format(contact.updatedAt!)
              : 'Unknown'),
        ),
      ],
    );
  }
}