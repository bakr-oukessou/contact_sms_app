import 'package:flutter/material.dart';
import '../models/favorite_model.dart';
import '../services/favorites_service.dart';
import '../widgets/favorite_card.dart';

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
    try {
      final favorites = await FavoritesService().getAllFavorites();
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load favorites: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? const Center(child: Text('No favorites yet'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final favorite = _favorites[index];
                    return FavoriteCard(
                      favorite: favorite,
                      onCallPressed: () => _makeCall(favorite),
                      onSmsPressed: () => _sendSms(favorite),
                      onTap: () => _showContactDetails(favorite),
                    );
                  },
                ),
    );
  }

  void _makeCall(Favorite favorite) {
    // Implement call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${favorite.name}...')),
    );
  }

  void _sendSms(Favorite favorite) {
    // Implement SMS functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preparing SMS to ${favorite.name}...')),
    );
  }

  void _showContactDetails(Favorite favorite) {
    // Implement navigation to contact details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Showing details for ${favorite.name}')),
    );
  }
}