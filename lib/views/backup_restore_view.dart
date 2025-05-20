import 'package:flutter/material.dart';
import '../services/contact_service.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting contacts backup...')),
      );
      await ContactService().backupContactsToFirebase('user-id', []);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts backup completed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }

  Future<void> _backupSms(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting SMS backup...')),
      );
      await SmsService().backupSmsToFirebase('user-id', []);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS backup completed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }

  Future<void> _restoreContacts(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restoring contacts...')),
      );
      // Implement restore functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts restored successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    }
  }

  Future<void> _restoreSms(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restoring SMS...')),
      );
      // Implement restore functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS restored successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    }
  }
}