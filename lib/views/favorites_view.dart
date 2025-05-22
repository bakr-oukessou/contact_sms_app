import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import '../models/favorite_model.dart';
import '../services/favorites_service.dart';
import '../services/firebase_service.dart';

class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  List<Favorite> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final favoritesService =
          Provider.of<FavoritesService>(context, listen: false);
      final favorites = await favoritesService.getAllFavorites();
      print("Favorites loaded: ${favorites.length}");
      setState(() => _favorites = favorites);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading favorites: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _makePhoneCall(Favorite favorite) async {
    try {
      final favoritesService = Provider.of<FavoritesService>(context, listen: false);
      final phone = await favoritesService.getContactPhone(favorite.contactId);
      
      if (phone != null) {
        // Format the phone number properly
        final formattedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
        final url = 'tel:$formattedPhone';
        
        if (await launcher.canLaunchUrl(Uri.parse(url))) {
          final launched = await launcher.launchUrl(
            Uri.parse(url),
            mode: launcher.LaunchMode.externalApplication,
          );
          
          if (launched) {
            await favoritesService.incrementInteractionCount(favorite.contactId, isCall: true);
            await _loadFavorites();
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not launch phone app')),
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No phone number found')),
          );
        }
      }
    } catch (e) {
      print('Error making phone call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to make call: $e')),
        );
      }
    }
  }

  Future<void> _sendSms(Favorite favorite) async {
    try {
      final favoritesService = Provider.of<FavoritesService>(context, listen: false);
      final phone = await favoritesService.getContactPhone(favorite.contactId);
      
      if (phone != null) {
        // Format the phone number properly
        final formattedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
        final url = 'sms:$formattedPhone';
        
        if (await launcher.canLaunchUrl(Uri.parse(url))) {
          final launched = await launcher.launchUrl(
            Uri.parse(url),
            mode: launcher.LaunchMode.externalApplication,
          );
          
          if (launched) {
            await favoritesService.incrementInteractionCount(favorite.contactId, isCall: false);
            await _loadFavorites();
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not launch messaging app')),
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No phone number found')),
          );
        }
      }
    } catch (e) {
      print('Error sending SMS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send SMS: $e')),
        );
      }
    }
  }

  Future<void> _backupFavorites() async {
    try {
      final favoritesService = Provider.of<FavoritesService>(context, listen: false);
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      
      final userId = firebaseService.getCurrentUser()?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backing up favorites...')),
      );

      await favoritesService.syncFavoritesToFirebase(userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favorites backed up successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to backup favorites: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: _backupFavorites,
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
                    'Loading favorites...',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_outline_rounded,
                        size: 64,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No favorites yet',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add contacts to favorites from your contacts list',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final favorite = _favorites[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildAvatar(favorite, theme),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        favorite.name,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _buildInteractionStats(favorite, theme),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildActionButtons(favorite, theme),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildAvatar(Favorite favorite, ThemeData theme) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: favorite.avatar == null
            ? LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              )
            : null,
      ),
      child: CircleAvatar(
        backgroundColor: Colors.transparent,
        backgroundImage: favorite.avatar != null ? MemoryImage(favorite.avatar!) : null,
        child: favorite.avatar == null
            ? Text(
                favorite.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildInteractionStats(Favorite favorite, ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.call_outlined,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          '${favorite.callCount}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.message_outlined,
          size: 16,
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(width: 4),
        Text(
          '${favorite.smsCount}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Favorite favorite, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _makePhoneCall(favorite),
            icon: const Icon(Icons.call),
            label: const Text('Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _sendSms(favorite),
            icon: const Icon(Icons.message),
            label: const Text('Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondaryContainer,
              foregroundColor: theme.colorScheme.onSecondaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}