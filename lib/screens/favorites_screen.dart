import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/movie_provider.dart';
import '../models/movie.dart';
import '../l10n/app_localizations.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovieProvider>().fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.viewFavorites, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<MovieProvider>(
        builder: (context, movieProvider, child) {
          if (movieProvider.favoritesLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF7F)),
            );
          }

          if (movieProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.error}: ${movieProvider.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      movieProvider.clearError();
                      movieProvider.fetchFavorites();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (movieProvider.favorites.isEmpty) {
            return const Center(
              child: Text(
                'No favorite movies yet',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: movieProvider.favorites.length,
            itemBuilder: (context, index) {
              final movie = movieProvider.favorites[index];
              return FavoriteMovieCard(movie: movie);
            },
          );
        },
      ),
    );
  }
}

class FavoriteMovieCard extends StatelessWidget {
  final Movie movie;

  const FavoriteMovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieProvider>(
      builder: (context, movieProvider, child) {
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/movie-detail',
              arguments: movie.id,
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF1A1A1A),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster placeholder
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          color: Colors.grey[800],
                        ),
                        child: movie.posterUrl != null
                            ? Image.network(
                                movie.posterUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.movie,
                                    color: Colors.white54,
                                    size: 48,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.movie,
                                color: Colors.white54,
                                size: 48,
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(
                            Icons.star,
                            color: Colors.yellow,
                            size: 24,
                          ),
                          onPressed: () {
                            movieProvider.toggleFavorite(movie.id);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Movie info
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (movie.releaseDate != null)
                          Text(
                            '${movie.releaseDate!.year}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        if (movie.maturityRating != null)
                          Text(
                            movie.maturityRating!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}