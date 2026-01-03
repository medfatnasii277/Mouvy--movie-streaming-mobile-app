import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/movie.dart';

class MovieProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Movie> _movies = [];
  bool _isLoading = false;
  String? _error;

  List<Movie> get movies => _movies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMovies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch movies with their categories and actors
      final response = await _supabase
          .from('movies')
          .select('''
            *,
            categories:movie_categories(
              categories(*)
            ),
            actors:movie_actors(
              *,
              actor:actors(*)
            )
          ''')
          .eq('status', 'released')
          .order('release_date', ascending: false);

      _movies = (response as List)
          .map((json) => Movie.fromJson(_transformMovieJson(json)))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Movie?> fetchMovieById(String movieId) async {
    try {
      final response = await _supabase
          .from('movies')
          .select('''
            *,
            categories:movie_categories(
              categories(*)
            ),
            actors:movie_actors(
              *,
              actor:actors(*)
            )
          ''')
          .eq('id', movieId)
          .single();

      return Movie.fromJson(_transformMovieJson(response));
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Map<String, dynamic> _transformMovieJson(Map<String, dynamic> json) {
    // Transform the nested data structure to match our model
    final categories = (json['categories'] as List<dynamic>?)
        ?.map((mc) => (mc as Map<String, dynamic>)['categories'])
        .where((c) => c != null)
        .cast<Map<String, dynamic>>()
        .toList() ?? [];

    final actors = (json['actors'] as List<dynamic>?)
        ?.map((ma) {
          final maMap = ma as Map<String, dynamic>;
          return {
            ...maMap,
            'actor': maMap['actor'] as Map<String, dynamic>,
          } as Map<String, dynamic>;
        })
        .toList() ?? [];

    return {
      ...json,
      'categories': categories,
      'actors': actors,
    };
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}