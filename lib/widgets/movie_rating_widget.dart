import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/movie_provider.dart';

class MovieRatingWidget extends StatefulWidget {
  final String movieId;

  const MovieRatingWidget({super.key, required this.movieId});

  @override
  State<MovieRatingWidget> createState() => _MovieRatingWidgetState();
}

class _MovieRatingWidgetState extends State<MovieRatingWidget> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovieProvider>().fetchRatings(widget.movieId);
    });
  }

  Future<void> _rateMovie(int rating) async {
    setState(() => _isLoading = true);
    final success = await context.read<MovieProvider>().addOrUpdateRating(widget.movieId, rating);
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rated $rating star${rating != 1 ? 's' : ''}!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to rate movie')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieProvider>(
      builder: (context, movieProvider, child) {
        final userRating = movieProvider.getUserRating(widget.movieId);
        final averageRating = movieProvider.getAverageRating(widget.movieId);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rating',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Average rating display
              Row(
                children: [
                  _buildStarRating(averageRating, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // User rating
              if (userRating == null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rate this movie:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF00FF7F))
                        : Row(
                            children: List.generate(6, (index) {
                              if (index == 0) return const SizedBox(width: 8);
                              return IconButton(
                                icon: Icon(
                                  Icons.star_border,
                                  color: const Color(0xFF00FF7F),
                                  size: 32,
                                ),
                                onPressed: () => _rateMovie(index),
                              );
                            }),
                          ),
                  ],
                )
              else
                Row(
                  children: [
                    const Text(
                      'Your rating:',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 8),
                    _buildStarRating(userRating.toDouble(), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$userRating star${userRating != 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Color(0xFF00FF7F),
                        size: 20,
                      ),
                      onPressed: () => _showRatingDialog(context),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStarRating(double rating, {double size = 24}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starRating = index + 1;
        IconData icon;
        Color color;

        if (rating >= starRating) {
          icon = Icons.star;
          color = Colors.amber;
        } else if (rating >= starRating - 0.5) {
          icon = Icons.star_half;
          color = Colors.amber;
        } else {
          icon = Icons.star_border;
          color = Colors.white70;
        }

        return Icon(
          icon,
          color: color,
          size: size,
        );
      }),
    );
  }

  void _showRatingDialog(BuildContext context) {
    int selectedRating = context.read<MovieProvider>().getUserRating(widget.movieId) ?? 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Rating'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select your rating:'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  if (index == 0) return const SizedBox(width: 8);
                  final isSelected = selectedRating == index;
                  return IconButton(
                    icon: Icon(
                      isSelected ? Icons.star : Icons.star_border,
                      color: isSelected ? Colors.amber : const Color(0xFF00FF7F),
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() => selectedRating = index);
                    },
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _rateMovie(selectedRating);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}