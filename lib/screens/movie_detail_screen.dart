import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/movie_provider.dart';
import '../models/movie.dart';

class MovieDetailScreen extends StatefulWidget {
  final String movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  Movie? _movie;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMovie();
  }

  Future<void> _loadMovie() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final movie = await context.read<MovieProvider>().fetchMovieById(widget.movieId);
      setState(() {
        _movie = movie;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF7F)),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMovie,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _movie == null
                  ? const Center(
                      child: Text(
                        'Movie not found',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : _buildMovieDetail(),
    );
  }

  Widget _buildMovieDetail() {
    final movie = _movie!;
    return CustomScrollView(
      slivers: [
        // Hero poster section
        SliverAppBar(
          expandedHeight: 400,
          pinned: true,
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Poster image
                movie.posterUrl != null
                    ? Image.network(
                        movie.posterUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.movie,
                              color: Colors.white54,
                              size: 100,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.movie,
                          color: Colors.white54,
                          size: 100,
                        ),
                      ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                // Play button overlay
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement play functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Play functionality coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Movie details
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and basic info
                Text(
                  movie.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (movie.releaseDate != null)
                      Text(
                        '${movie.releaseDate!.year}',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    if (movie.maturityRating != null) ...[
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white70),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          movie.maturityRating!,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                    if (movie.duration != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        movie.formattedDuration,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ],
                ),

                // Categories
                if (movie.categories.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: movie.categories.map((category) {
                      return Chip(
                        label: Text(
                          category.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF333333),
                      );
                    }).toList(),
                  ),
                ],

                // Description
                if (movie.description != null) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Storyline',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    movie.description!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],

                // Cast
                if (movie.actors.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Cast',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: _buildCastList(movie.actors),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCastList(List<MovieActor> actors) {
    final sortedActors = actors
        .where((ma) => ma.billingOrder != null)
        .toList()
      ..sort((a, b) => (a.billingOrder ?? 999).compareTo(b.billingOrder ?? 999));
    
    return sortedActors.map((movieActor) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(
              movieActor.actor.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            if (movieActor.roleName != null) ...[
              const SizedBox(width: 8),
              Text(
                'as ${movieActor.roleName}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }
}