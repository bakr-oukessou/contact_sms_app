import 'package:contact_sms_app/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/sms_model.dart';
import '../services/sms_service.dart';
import '../widgets/sms_card.dart';

class SmsView extends StatefulWidget {
  const SmsView({super.key});

  @override
  State<SmsView> createState() => _SmsViewState();
}

class _SmsViewState extends State<SmsView> {
  final Map<String, List<SmsMessage>> _conversations = {};
  final Map<String, String> _contactNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSms();
  }

  Future<void> _loadSms() async {
    setState(() => _isLoading = true);
    try {
      // Request permissions first
      Map<Permission, PermissionStatus> statuses = await [
        Permission.sms,
        Permission.phone,
      ].request();

      if (!statuses.values.every((status) => status.isGranted)) {
        if (!mounted) return;
        bool shouldOpenSettings = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
              'SMS and Phone permissions are required to read your messages. '
              'Please grant these permissions in settings.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ) ?? false;

        if (shouldOpenSettings) {
          await openAppSettings();
          // Wait a bit for settings to be changed
          await Future.delayed(const Duration(seconds: 2));
          // Try loading again
          if (mounted) {
            _loadSms();
          }
          return;
        }
      }

      final smsService = Provider.of<SmsService>(context, listen: false);
      final smsList = await smsService.getDeviceSms();
      
      if (smsList.isNotEmpty) {
        final phoneNumbers = smsList.map((sms) => sms.address ?? '').toSet();
        final contactNames = await smsService.getContactNames(phoneNumbers);
        
        final grouped = _groupByContact(smsList);
        if (mounted) {
          setState(() {
            _conversations.clear();
            _conversations.addAll(grouped);
            _contactNames.clear();
            _contactNames.addAll(contactNames);
          });
        }
      }
    } catch (e) {
      print("Error loading SMS: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load SMS: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, List<SmsMessage>> _groupByContact(List<SmsMessage> smsList) {
    final Map<String, List<SmsMessage>> result = {};
    for (final sms in smsList) {
      final address = sms.address ?? 'Unknown';
      if (!result.containsKey(address)) {
        result[address] = [];
      }
      result[address]!.add(sms);
    }
    // Sort messages by date in each conversation
    for (final entry in result.entries) {
      entry.value.sort((a, b) => b.date!.compareTo(a.date!));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: _backupSms,
            tooltip: 'Backup to Cloud',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading messages...',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 64,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages found',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your SMS conversations will appear here',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final address = _conversations.keys.elementAt(index);
                    final messages = _conversations[address]!;
                    final latestMessage = messages.first;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            (_contactNames[address] ?? address).substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          _contactNames[address] ?? address,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              latestMessage.body ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (latestMessage.date != null)
                              Text(
                                _formatDate(latestMessage.date!),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                                ),
                              ),
                          ],
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: messages.map((sms) => _buildMessageBubble(sms, theme)).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildMessageBubble(SmsMessage sms, ThemeData theme) {
    final isReceived = sms.type == 1; // Adjust based on your SMS type values
    
    return Align(
      alignment: isReceived ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isReceived 
              ? theme.colorScheme.surface 
              : theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: isReceived
              ? Border.all(color: theme.colorScheme.outline.withOpacity(0.2))
              : null,
        ),
        child: Column(
          crossAxisAlignment: isReceived 
              ? CrossAxisAlignment.start 
              : CrossAxisAlignment.end,
          children: [
            Text(
              sms.body ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isReceived
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(sms.date!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: (isReceived
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onPrimaryContainer)
                    .withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${_getWeekday(date)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _getWeekday(DateTime date) {
    switch (date.weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  Future<void> _backupSms() async {
    try {
      final smsService = Provider.of<SmsService>(context, listen: false);
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backing up SMS...')),
      );

      final userId = firebaseService.getCurrentUser()?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      final smsList = await smsService.getDeviceSms();
      await smsService.backupSmsToFirebase(userId, smsList);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMS backed up successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }
}