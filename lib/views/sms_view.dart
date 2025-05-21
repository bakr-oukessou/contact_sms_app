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
      print("Got ${smsList.length} messages from service");

      if (smsList.isEmpty) {
        if (!mounted) return;
        bool shouldOpenSettings = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('SMS Permission Required'),
            content: const Text('Please grant SMS permissions to view your messages.'),
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
        }
      } else {
        final grouped = _groupByContact(smsList);
        if (mounted) {
          setState(() {
            _conversations.clear();
            _conversations.addAll(grouped);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Conversations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: _backupSms,
            tooltip: 'Backup to Cloud',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(child: Text('No SMS conversations'))
              : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final address = _conversations.keys.elementAt(index);
                    final messages = _conversations[address]!;
                    return ExpansionTile(
                      title: Text(address),
                      subtitle: Text(messages.first.body ?? ''),
                      children: [
                        for (int i = 0; i < messages.length; i++)
                          SmsCard(
                            sms: messages[i],
                            isFirstInGroup: i == 0,
                            isLastInGroup: i == messages.length - 1,
                          ),
                      ],
                    );
                  },
                ),
    );
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