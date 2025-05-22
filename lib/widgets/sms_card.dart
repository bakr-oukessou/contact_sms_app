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
    final theme = Theme.of(context);
    final bool isSent = sms.type == 2;
    final colorScheme = theme.colorScheme;
    final bgColor = isSent 
        ? colorScheme.primaryContainer 
        : colorScheme.surfaceContainerHighest;
    final textColor = isSent
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Container(
      margin: EdgeInsets.only(
        top: isFirstInGroup ? 8 : 4,
        bottom: isLastInGroup ? 8 : 4,
      ),
      child: Align(
        alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isSent ? 16 : 4),
                topRight: Radius.circular(isSent ? 4 : 16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              color: bgColor,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment: isSent 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    sms.body ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(sms.date),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: textColor.withOpacity(0.6),
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