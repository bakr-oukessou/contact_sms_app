import 'package:contact_sms_app/models/favorite_model.dart';
import 'package:flutter/foundation.dart';

import '../models/sms_model.dart';
import 'contact_service.dart';
import 'sms_service.dart';
import 'favorites_service.dart';
import 'local_db_service.dart';

class SyncService extends ChangeNotifier {
  final ContactService _contactService = ContactService();
  final SmsService _smsService = SmsService();
  final FavoritesService _favoritesService = FavoritesService();
  final LocalDatabaseService _localDb = LocalDatabaseService();

  Future<void> fullSync(String userId) async {
    await _syncContacts(userId);
    await _syncSms(userId);
    await _updateSyncTimes();
  }

  Future<void> _syncContacts(String userId) async {
    try {
      final lastSync = await _localDb.getLastSyncTime('contacts');
      final deviceContacts = await _contactService.getDeviceContacts();
      
      if (lastSync == null) {
        // First sync - backup all contacts
        await _contactService.backupContactsToFirebase(userId, deviceContacts);
      } else {
        // Incremental sync - only backup new/modified contacts
        final modifiedContacts = deviceContacts.where((contact) {
          return contact.updatedAt == null || 
              contact.updatedAt!.isAfter(lastSync);
        }).toList();
        
        if (modifiedContacts.isNotEmpty) {
          await _contactService.backupContactsToFirebase(
              userId, modifiedContacts);
        }
      }
    } catch (e) {
      print("Error syncing contacts: $e");
      rethrow;
    }
  }

  Future<void> _syncSms(String userId) async {
    try {
      final lastSync = await _localDb.getLastSyncTime('sms');
      final deviceSms = await _smsService.getDeviceSms();
      
      if (lastSync == null) {
        // First sync - backup all SMS
        await _smsService.backupSmsToFirebase(userId, deviceSms);
      } else {
        // Incremental sync - only backup new SMS
        final newSms = deviceSms.where((sms) {
          return sms.date == null || sms.date!.isAfter(lastSync);
        }).toList();
        
        if (newSms.isNotEmpty) {
          await _smsService.backupSmsToFirebase(userId, newSms);
        }
      }
    } catch (e) {
      print("Error syncing SMS: $e");
      rethrow;
    }
  }

  Future<void> _updateSyncTimes() async {
    final now = DateTime.now();
    await _localDb.updateLastSyncTime('contacts', now);
    await _localDb.updateLastSyncTime('sms', now);
  }

  Future<void> restoreFromBackup(String userId) async {
    try {
      // Restore contacts
      final _ = await _contactService.restoreContactsFromFirebase(userId);
      // Here you would implement saving to device (not directly possible on all devices)
      
      // Restore SMS
      final cloudSms = await _smsService.restoreSmsFromFirebase(userId);
      // Here you would implement saving to device (not directly possible on all devices)
      
      // Update favorites based on interaction counts from SMS
      await _updateFavoritesFromSms(cloudSms);
    } catch (e) {
      if (kDebugMode) {
        print("Error restoring from backup: $e");
      }
      rethrow;
    }
  }

  Future<void> _updateFavoritesFromSms(List<SmsMessage> smsList) async {
    // Group SMS by contact and count interactions
    final Map<String, int> contactSmsCount = {};
    
    for (final sms in smsList) {
      final address = sms.address ?? 'unknown';
      contactSmsCount[address] = (contactSmsCount[address] ?? 0) + 1;
    }
    
    // Update favorites in local database
    for (final entry in contactSmsCount.entries) {
      if (entry.value > 5) { // Threshold for becoming a favorite
        final favorite = await _favoritesService.getFavorite(entry.key);
        if (favorite == null) {
          await _favoritesService.addFavorite(Favorite(
            id: entry.key,
            contactId: entry.key,
            name: entry.key, // In real app, get name from contacts
            callCount: 0,
            smsCount: entry.value,
            lastInteraction: DateTime.now(),
            createdAt: DateTime.now(),
          ));
        } else {
          await _favoritesService.incrementInteractionCount(
            entry.key,
            isCall: false,
          );
        }
      }
    }
  }
}