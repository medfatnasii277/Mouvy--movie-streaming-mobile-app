import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/movie.dart';
import '../services/movie_filter_service.dart';
import '../models/comment.dart';

class MovieProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final MovieFilterService _filterService = MovieFilterService();

  List<Movie> _movies = [];
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;

  // Current filter state
  MovieFilters _currentFilters = MovieFilters();

  // Favorites
  Set<String> _favoriteIds = {};
  List<Movie> _favorites = [];
  bool _favoritesLoading = false;

  // Comments
  List<Comment> _comments = [];
  bool _commentsLoading = false;

  // Comment likes
  Map<String, int> _commentLikesCount = {};
  Set<String> _likedCommentIds = {};

  List<Movie> get movies => _movies;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  MovieFilters get currentFilters => _currentFilters;

  // Favorites
  Set<String> get favoriteIds => _favoriteIds;
  List<Movie> get favorites => _favorites;
  bool get favoritesLoading => _favoritesLoading;

  // Comments
  List<Comment> get comments => _comments;
  bool get commentsLoading => _commentsLoading;

  // Comment likes
  int getCommentLikesCount(String commentId) => _commentLikesCount[commentId] ?? 0;
  bool isCommentLiked(String commentId) => _likedCommentIds.contains(commentId);

  /// Fetch movies with current filters
  Future<void> fetchMovies({bool loadMore = false}) async {
    if (loadMore && !_hasMore) return;

    _isLoading = true;
    if (!loadMore) {
      _currentPage = 0;
      _movies.clear();
      _hasMore = true;
    }
    _error = null;
    notifyListeners();

    try {
      final offset = loadMore ? _currentPage * _pageSize : 0;
      final response = await _filterService.fetchMovies(
        statuses: _currentFilters.statuses,
        languages: _currentFilters.languages,
        maturityRatings: _currentFilters.maturityRatings,
        releaseYearFrom: _currentFilters.releaseYearFrom,
        releaseYearTo: _currentFilters.releaseYearTo,
        durationMin: _currentFilters.durationMin,
        durationMax: _currentFilters.durationMax,
        titleSearch: _currentFilters.titleSearch,
        categoryIds: _currentFilters.categoryIds,
        includeSubcategories: _currentFilters.includeSubcategories,
        actorIds: _currentFilters.actorIds,
        sortBy: _currentFilters.sortBy,
        ascending: _currentFilters.ascending,
        limit: _pageSize,
        offset: offset,
      );

      final newMovies = response
          .map((json) => Movie.fromJson(_transformMovieJson(json)))
          .toList();

      if (loadMore) {
        _movies.addAll(newMovies);
      } else {
        _movies = newMovies;
      }

      _hasMore = newMovies.length == _pageSize;
      if (_hasMore) _currentPage++;
    } catch (e) {
      _error = e.toString();
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search movies with query
  Future<void> searchMovies(String query) async {
    _isLoading = true;
    _error = null;
    _movies.clear();
    _hasMore = false; // Search doesn't support pagination for simplicity
    notifyListeners();

    try {
      final response = await _filterService.searchMovies(
        query: query,
        limit: 50, // More results for search
      );

      _movies = response
          .map((json) => Movie.fromJson(_transformMovieJson(json)))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Apply new filters
  Future<void> applyFilters(MovieFilters filters) async {
    _currentFilters = filters;
    await fetchMovies();
  }

  /// Update sorting
  Future<void> updateSorting(String sortBy, bool ascending) async {
    _currentFilters = _currentFilters.copyWith(sortBy: sortBy, ascending: ascending);
    await fetchMovies();
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    _currentFilters.clear();
    await fetchMovies();
  }

  /// Load more movies (for infinite scrolling)
  Future<void> loadMore() async {
    if (!currentFilters.hasActiveFilters) {
      await fetchMovies(loadMore: true);
    }
  }

  /// Get filter metadata
  Future<Map<String, dynamic>> getFilterMetadata() async {
    try {
      return await _filterService.getFilterMetadata();
    } catch (e) {
      _error = e.toString();
      return {};
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

  /// Load favorite movie IDs for current user
  Future<void> loadFavoriteIds() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('favorites')
          .select('movie_id')
          .eq('user_id', user.id);

      final Set<String> ids = {};
      for (var f in response) {
        final id = f['movie_id'];
        if (id is String) ids.add(id);
      }
      _favoriteIds = ids;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Check if movie is favorited
  bool isFavorite(String movieId) => _favoriteIds.contains(movieId);

  /// Toggle favorite status
  Future<void> toggleFavorite(String movieId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      if (isFavorite(movieId)) {
        // Remove from favorites
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('movie_id', movieId);
        _favoriteIds.remove(movieId);
      } else {
        // Add to favorites
        await _supabase
            .from('favorites')
            .insert({'user_id': user.id, 'movie_id': movieId});
        _favoriteIds.add(movieId);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Fetch user's favorite movies
  Future<void> fetchFavorites() async {
    _favoritesLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('favorites')
          .select('movies!inner(*, categories:movie_categories!inner(categories(*)), actors:movie_actors!inner(*, actor:actors(*)))')
          .eq('user_id', user.id);

      final List<Movie> favoritesList = [];
      for (var item in response) {
        final movieData = item['movies'] ?? item;
        favoritesList.add(Movie.fromJson(_transformMovieJson(movieData as Map<String, dynamic>)));
      }
      _favorites = favoritesList;
    } catch (e) {
      _error = e.toString();
    } finally {
      _favoritesLoading = false;
      notifyListeners();
    }
  }

  /// Fetch comments for a movie
  Future<void> fetchComments(String movieId) async {
    _commentsLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('comments')
          .select('*, profiles!user_id(username)')
          .eq('movie_id', movieId)
          .order('created_at', ascending: false);

      _comments = (response as List<dynamic>?)
          ?.map((c) => Comment.fromJson(c as Map<String, dynamic>))
          .toList() ?? [];

      // Fetch likes for these comments
      await _fetchCommentLikes(movieId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _commentsLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchCommentLikes(String movieId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get likes count for each comment
      final likesResponse = await _supabase
          .from('comment_likes')
          .select('comment_id')
          .in_('comment_id', _comments.map((c) => c.id).toList());

      final likesCount = <String, int>{};
      for (var like in likesResponse) {
        final commentId = like['comment_id'] as String;
        likesCount[commentId] = (likesCount[commentId] ?? 0) + 1;
      }
      _commentLikesCount = likesCount;

      // Get user's liked comments
      final userLikesResponse = await _supabase
          .from('comment_likes')
          .select('comment_id')
          .eq('user_id', user.id)
          .in_('comment_id', _comments.map((c) => c.id).toList());

      _likedCommentIds = userLikesResponse.map((l) => l['comment_id'] as String).toSet();
    } catch (e) {
      // Ignore errors for likes
    }
  }

  /// Toggle like on a comment
  Future<void> toggleCommentLike(String commentId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // First try to delete (if liked)
      final deleteResult = await _supabase
          .from('comment_likes')
          .delete()
          .eq('comment_id', commentId)
          .eq('user_id', user.id)
          .select();

      if (deleteResult.isNotEmpty) {
        // Was liked, now unliked
        _likedCommentIds.remove(commentId);
        _commentLikesCount[commentId] = (_commentLikesCount[commentId] ?? 0) - 1;
      } else {
        // Was not liked, so like it
        await _supabase
            .from('comment_likes')
            .insert({'comment_id': commentId, 'user_id': user.id});
        _likedCommentIds.add(commentId);
        _commentLikesCount[commentId] = (_commentLikesCount[commentId] ?? 0) + 1;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Add a comment to a movie
  Future<bool> addComment(String movieId, String commentText) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from('comments')
          .insert({
            'user_id': user.id,
            'movie_id': movieId,
            'comment_text': commentText,
          })
          .select('*, profiles!user_id(username)')
          .single();

      final newComment = Comment.fromJson(response as Map<String, dynamic>);
      _comments.insert(0, newComment);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update a comment
  Future<bool> updateComment(String commentId, String newText) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from('comments')
          .update({'comment_text': newText, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', commentId)
          .eq('user_id', user.id)
          .select('*, profiles!user_id(username)')
          .single();

      final updatedComment = Comment.fromJson(response as Map<String, dynamic>);
      final index = _comments.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        _comments[index] = updatedComment;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a comment
  Future<bool> deleteComment(String commentId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      await _supabase
          .from('comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', user.id);

      _comments.removeWhere((c) => c.id == commentId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear comments (when switching movies)
  void clearComments() {
    _comments = [];
    notifyListeners();
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
          };
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