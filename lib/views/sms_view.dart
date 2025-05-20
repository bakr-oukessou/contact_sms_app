import 'package:flutter/material.dart';
import '../models/sms_model.dart';
import '../services/sms_service.dart';
import '../widgets/sms_card.dart';

class SmsView extends StatefulWidget {
  const SmsView({Key? key}) : super(key: key);

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
    try {
      final smsList = await SmsService().getDeviceSms();
      final grouped = _groupByContact(smsList);
      setState(() {
        _conversations.addAll(grouped);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load SMS: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backing up SMS...')),
      );
      final smsList = await SmsService().getDeviceSms();
      await SmsService().backupSmsToFirebase('user-id', smsList);
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