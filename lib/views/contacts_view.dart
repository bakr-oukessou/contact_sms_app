import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/contact_model.dart';
import '../services/contact_service.dart';
import '../services/favorites_service.dart';
import '../widgets/contact_card.dart';
import 'contact_detail_view.dart';

class ContactsView extends StatefulWidget {
  const ContactsView({super.key});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  List<Contact> _contacts = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _loadFavorites();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final contactService = Provider.of<ContactService>(context, listen: false);
      final contacts = await contactService.getDeviceContacts();
      
      if (contacts.isEmpty) {
        bool shouldRequestAgain = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Contacts Permission Required"),
            content: const Text("We need access to your contacts to backup them securely"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Grant Permission"),
              ),
            ],
          ),
        );
        
        if (shouldRequestAgain == true) {
          await openAppSettings();
        }
      }
      
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load contacts: $e')),
        );
      }
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favoritesService = Provider.of<FavoritesService>(context, listen: false);
      final favorites = await favoritesService.getAllFavorites();
      setState(() {
        _favoriteIds = favorites.map((f) => f.contactId).toSet();
      });
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  List<Contact> get _filteredContacts {
    if (_searchQuery.isEmpty) return _contacts;
    return _contacts.where((contact) {
      return contact.displayName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
    }).toList();
  }

  Future<void> _toggleFavorite(Contact contact) async {
    try {
      final favoritesService = Provider.of<FavoritesService>(context, listen: false);
      if (_favoriteIds.contains(contact.identifier)) {
        await favoritesService.removeFavorite(contact.identifier!);
        setState(() => _favoriteIds.remove(contact.identifier));
      } else {
        await favoritesService.addToFavorites(
          contact.identifier!,
          contact.displayName ?? 'Unknown',
          avatar: contact.avatar,
        );
        setState(() => _favoriteIds.add(contact.identifier!));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorite: $e')),
      );
    }
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
      body: RefreshIndicator(
        onRefresh: _loadContacts,
        child: Column(
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
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(
                              height: 200,
                              child: Center(child: Text('No contacts found')),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: _filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _filteredContacts[index];
                            return ContactCard(
                              contact: contact,
                              onTap: () => _showContactDetails(contact),
                              isFavorite: _favoriteIds.contains(contact.identifier),
                              onFavoriteChanged: (_) => _toggleFavorite(contact),
                            );
                          },
                        ),
            ),
          ],
        ),
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