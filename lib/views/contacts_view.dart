import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart' as device_contacts;
import '../models/contact_model.dart';
import '../services/contact_service.dart';
import '../widgets/contact_card.dart';
import 'contact_detail_view.dart'; // <-- Add this import

class ContactsView extends StatefulWidget {
  const ContactsView({Key? key}) : super(key: key);

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  List<Contact> _contacts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final deviceContacts = await device_contacts.ContactsService.getContacts();
      final contacts = deviceContacts.map((c) => Contact(
        displayName: c.displayName ?? '',
        phones: c.phones?.isNotEmpty == true
            ? c.phones!.map((e) => ContactPhone(value: e.value ?? '', label: e.label ?? '')).toList()
            : [],
        emails: c.emails?.isNotEmpty == true
            ? c.emails!.map((e) => ContactEmail(value: e.value ?? '', label: e.label ?? '')).toList()
            : [],
        avatar: c.avatar,
        createdAt: DateTime.now(),
      )).toList();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load contacts: $e')),
      );
    }
  }

  List<Contact> get _filteredContacts {
    if (_searchQuery.isEmpty) return _contacts;
    return _contacts.where((contact) {
      return contact.displayName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: _backupContacts,
            tooltip: 'Backup to Cloud',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                    ? const Center(child: Text('No contacts found'))
                    : ListView.builder(
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          return ContactCard(
                            contact: contact,
                            onTap: () => _showContactDetails(contact),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showContactDetails(Contact contact) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailView(contact: contact),
      ),
    );
  }

  Future<void> _backupContacts() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backing up contacts...')),
      );
      await ContactService().backupContactsToFirebase('user-id', _contacts);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts backed up successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }
}