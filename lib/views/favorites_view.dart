import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import '../models/favorite_model.dart';
import '../services/favorites_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final favorite = _favorites[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: favorite.avatar != null
                        ? MemoryImage(favorite.avatar!)
                        : null,
                    child: favorite.avatar == null
                        ? Text(favorite.name[0])
                        : null,
                  ),
                  title: Text(favorite.name),
                  subtitle: Text(
                    'Calls: ${favorite.callCount} | SMS: ${favorite.smsCount}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.call),
                        onPressed: () => _makePhoneCall(favorite),
                        tooltip: 'Call ${favorite.name}',
                      ),
                      IconButton(
                        icon: const Icon(Icons.message),
                        onPressed: () => _sendSms(favorite),
                        tooltip: 'Message ${favorite.name}',
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}