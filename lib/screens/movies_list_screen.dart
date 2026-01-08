import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/movie_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../models/movie.dart';
import '../widgets/movie_filter_bar.dart';
import '../l10n/app_localizations.dart';

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
      provider.fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.movies, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          Consumer<MovieProvider>(
            builder: (context, movieProvider, child) {
              final unreadCount = movieProvider.unreadNotificationsCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'favorites') {
                Navigator.pushNamed(context, '/favorites');
              } else if (value == 'edit_profile') {
                Navigator.pushNamed(context, '/edit_profile');
              } else if (value == 'language') {
                final localeProvider = context.read<LocaleProvider>();
                localeProvider.toggleLanguage();
              } else if (value == 'logout') {
                final authProvider = context.read<AuthProvider>();
                authProvider.signOut();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'favorites',
                child: Text(AppLocalizations.of(context)!.viewFavorites),
              ),
              PopupMenuItem<String>(
                value: 'edit_profile',
                child: Text(AppLocalizations.of(context)!.editProfile),
              ),
              PopupMenuItem<String>(
                value: 'language',
                child: Text('🌐 ${AppLocalizations.of(context)!.language}'),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Text(AppLocalizations.of(context)!.logout),
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
                          '${AppLocalizations.of(context)!.error}: ${movieProvider.error}',
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            movieProvider.clearError();
                            movieProvider.fetchMovies();
                          },
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ],
                    ),
                  );
                }

                if (movieProvider.movies.isEmpty) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.noMoviesAvailable,
                      style: const TextStyle(color: Colors.white),
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