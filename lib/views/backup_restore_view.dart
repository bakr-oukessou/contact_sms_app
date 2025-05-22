import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/contact_service.dart';
import '../services/firebase_service.dart';
import '../services/sms_service.dart';

class BackupRestoreView extends StatelessWidget {
  const BackupRestoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBackupCard(context),
            const SizedBox(height: 20),
            _buildRestoreCard(context),
            const SizedBox(height: 20),
            _buildSyncInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Backup to Cloud',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Save your contacts and messages to the cloud'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.contacts),
                  label: const Text('Backup Contacts'),
                  onPressed: () => _backupContacts(context),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.message),
                  label: const Text('Backup SMS'),
                  onPressed: () => _backupSms(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoreCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Restore from Cloud',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Restore your contacts and messages from the cloud'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.contacts),
                  label: const Text('Restore Contacts'),
                  onPressed: () => _restoreContacts(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.message),
                  label: const Text('Restore SMS'),
                  onPressed: () => _restoreSms(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncInfo() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Last backup: Yesterday at 14:30'),
            Text('Last restore: Never'),
            SizedBox(height: 8),
            Text(
              'Note: Only new and modified items will be synced',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _backupContacts(BuildContext context) async {
    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final contactService = Provider.of<ContactService>(context, listen: false);
      
      final userId = firebaseService.getCurrentUser()?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting contacts backup...')),
      );

      final contacts = await contactService.getDeviceContacts();
      await contactService.backupContactsToFirebase(userId, contacts);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${contacts.length} contacts backed up successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }

  Future<void> _backupSms(BuildContext context) async {
    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final smsService = Provider.of<SmsService>(context, listen: false);
      
      final userId = firebaseService.getCurrentUser()?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting SMS backup...')),
      );

      final messages = await smsService.getDeviceSms();
      await smsService.backupSmsToFirebase(userId, messages);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${messages.length} messages backed up successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }

  Future<void> _restoreContacts(BuildContext context) async {
    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final contactService = Provider.of<ContactService>(context, listen: false);
      
      final userId = firebaseService.getCurrentUser()?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restoring contacts...')),
      );

      final contacts = await contactService.restoreContactsFromFirebase(userId);
      
      if (contacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No contacts found in backup')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${contacts.length} contacts restored successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    }
  }

  Future<void> _restoreSms(BuildContext context) async {
    try {
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      final smsService = Provider.of<SmsService>(context, listen: false);
      
      final userId = firebaseService.getCurrentUser()?.uid;
      if (userId == null) throw Exception('User not logged in');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restoring SMS messages...')),
      );

      final messages = await smsService.restoreSmsFromFirebase(userId);
      
      if (messages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No messages found in backup')),
        );
        return;
      }

      // Write to device
      final success = await smsService.writeSmsToDevice(messages);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not write to device SMS storage')),
        );
      }

      // Refresh the SMS view
      // if (context.mounted) {
      //   final smsViewState = context.findAncestorStateOfType<_SmsViewState>();
      //   smsViewState?._loadSms(fromCloud: true);
      // }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${messages.length} messages restored successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    }
  }
}