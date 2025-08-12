import 'package:cuddlecare2/screens/pet_sitter_details_screen.dart';
import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../services/profile_service.dart';
import '../models/user_profile.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  final ProfileService _profileService = ProfileService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<String>>(
        stream: _favoritesService.getFavoriteProviderIds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You haven\'t added any favorites yet.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final providerIds = snapshot.data!;
          return FutureBuilder<List<UserProfile>>(
            future: _profileService.getProfilesByIds(providerIds),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!profileSnapshot.hasData || profileSnapshot.data!.isEmpty) {
                return const Center(
                  child: Text('Could not load provider details.'),
                );
              }

              final providers = profileSnapshot.data!;
              return ListView.builder(
                itemCount: providers.length,
                itemBuilder: (context, index) {
                  final provider = providers[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: provider.profilePicUrl != null
                            ? NetworkImage(provider.profilePicUrl!)
                            : null,
                        child: provider.profilePicUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(provider.name),
                      subtitle: Text(
                          provider.services?.join(', ') ?? 'Pet Care Provider'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PetSitterDetailsScreen(
                                petSitterId: provider.uid),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
