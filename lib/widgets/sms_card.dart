import 'package:flutter/material.dart';
import '../models/sms_model.dart';
import 'package:intl/intl.dart'; // For date formatting

class SmsCard extends StatelessWidget {
  final SmsMessage sms;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  const SmsCard({
    super.key,
    required this.sms,
    this.isFirstInGroup = false,
    this.isLastInGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSent = sms.type == 2;
    final color = isSent ? Colors.blue[100] : Colors.grey[200];
    final alignment = isSent ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      margin: EdgeInsets.only(
        top: isFirstInGroup ? 8 : 2,
        bottom: isLastInGroup ? 8 : 2,
      ),
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Card(
            color: color,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: isSent 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    sms.body ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(sms.date),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    if (date.year == now.year && 
        date.month == now.month && 
        date.day == now.day) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('MMM d, HH:mm').format(date);
  }
}