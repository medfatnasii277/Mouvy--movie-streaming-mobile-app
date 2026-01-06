import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/movie_provider.dart';
import '../providers/auth_provider.dart';
import '../models/movie.dart';
import '../widgets/movie_filter_bar.dart';

class MoviesListScreen extends StatefulWidget {
  const MoviesListScreen({super.key});

  @override
  State<MoviesListScreen> createState() => _MoviesListScreenState();
}

class _MoviesListScreenState extends State<MoviesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MovieProvider>();
      provider.fetchMovies();
      provider.loadFavoriteIds();
      provider.fetchLastViewedMovie();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Movies', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'favorites') {
                Navigator.pushNamed(context, '/favorites');
              } else if (value == 'logout') {
                final authProvider = context.read<AuthProvider>();
                authProvider.signOut();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'favorites',
                child: Text('View Favorites'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          const MovieFilterBar(),
          Expanded(
            child: Consumer<MovieProvider>(
              builder: (context, movieProvider, child) {
                if (movieProvider.isLoading) {
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
                          'Error: ${movieProvider.error}',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            movieProvider.clearError();
                            movieProvider.fetchMovies();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (movieProvider.movies.isEmpty) {
                  return const Center(
                    child: Text(
                      'No movies available',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final movies = movieProvider.movies;
                final lastViewedId = movieProvider.lastViewedMovieId;
                List<Movie> sortedMovies = List.from(movies);
                if (lastViewedId != null) {
                  final lastViewedMovie = movies.firstWhere(
                    (m) => m.id == lastViewedId,
                    orElse: () => null as Movie,
                  );
                  if (lastViewedMovie != null) {
                    sortedMovies.remove(lastViewedMovie);
                    sortedMovies.insert(0, lastViewedMovie);
                  }
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: sortedMovies.length,
                  itemBuilder: (context, index) {
                    final movie = sortedMovies[index];
                    final isRecentlyViewed = index == 0 && lastViewedId != null && movie.id == lastViewedId;
                    return MovieCard(movie: movie, isRecentlyViewed: isRecentlyViewed);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MovieCard extends StatelessWidget {
  final Movie movie;
  final bool isRecentlyViewed;

  const MovieCard({super.key, required this.movie, this.isRecentlyViewed = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieProvider>(
      builder: (context, movieProvider, child) {
        final isFav = movieProvider.isFavorite(movie.id);
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
                          icon: Icon(
                            isFav ? Icons.star : Icons.star_border,
                            color: isFav ? Colors.yellow : Colors.white,
                            size: 24,
                          ),
                          onPressed: () {
                            movieProvider.toggleFavorite(movie.id);
                          },
                        ),
                      ),
                      if (isRecentlyViewed)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF7F),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Recently Viewed',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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