import 'package:supabase_flutter/supabase_flutter.dart';

/// Production-ready filtering service for Netflix-style movie browsing
class MovieFilterService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Filter options for movie browsing
  static const List<String> statuses = ['released', 'upcoming', 'archived'];
  static const List<String> maturityRatings = ['G', 'PG', 'PG-13', 'R', 'NC-17'];
  static const List<String> languages = ['en', 'es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh'];

  /// Fetch movies with comprehensive filtering
  Future<List<dynamic>> fetchMovies({
    // Movie-level filters
    List<String>? statuses,
    List<String>? languages,
    List<String>? maturityRatings,
    DateTime? releaseYearFrom,
    DateTime? releaseYearTo,
    Duration? durationMin,
    Duration? durationMax,
    String? titleSearch,

    // Category filters
    List<String>? categoryIds,
    bool includeSubcategories = true,

    // Actor filters
    List<String>? actorIds,

    // Sorting
    String sortBy = 'release_date', // 'release_date', 'title', 'created_at'
    bool ascending = false,

    // Pagination
    int limit = 20,
    int offset = 0,
  }) async {
    // Build the base query with joins
    var query = _supabase
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
        ''');

    // Apply movie-level filters
    if (statuses != null && statuses.isNotEmpty) {
      query = query.in_('status', statuses);
    } else {
      // Default to 'released' movies only
      query = query.eq('status', 'released');
    }

    if (languages != null && languages.isNotEmpty) {
      query = query.in_('language', languages);
    }

    if (maturityRatings != null && maturityRatings.isNotEmpty) {
      query = query.in_('maturity_rating', maturityRatings);
    }

    if (releaseYearFrom != null) {
      query = query.gte('release_date', releaseYearFrom.toIso8601String().split('T')[0]);
    }

    if (releaseYearTo != null) {
      query = query.lte('release_date', releaseYearTo.toIso8601String().split('T')[0]);
    }

    if (durationMin != null) {
      query = query.gte('duration', _durationToString(durationMin));
    }

    if (durationMax != null) {
      query = query.lte('duration', _durationToString(durationMax));
    }

    if (titleSearch != null && titleSearch.isNotEmpty) {
      query = query.ilike('title', '%$titleSearch%');
    }

    // Apply category filters (many-to-many)
    if (categoryIds != null && categoryIds.isNotEmpty) {
      if (includeSubcategories) {
        // Use RPC function for hierarchical category filtering
        return await _fetchMoviesWithHierarchicalCategories(
          categoryIds: categoryIds,
          sortBy: sortBy,
          ascending: ascending,
          limit: limit,
          offset: offset,
        );
      } else {
        // Direct many-to-many filtering
        query = query.in_('movie_categories.category_id', categoryIds);
      }
    }

    // Apply actor filters (many-to-many)
    if (actorIds != null && actorIds.isNotEmpty) {
      query = query.in_('movie_actors.actor_id', actorIds);
    }

    // Apply sorting and pagination (chain, don't reassign)
    return await query.order(sortBy, ascending: ascending).range(offset, offset + limit - 1);
  }

  /// Fetch movies with hierarchical category support
  Future<List<dynamic>> _fetchMoviesWithHierarchicalCategories({
    required List<String> categoryIds,
    required String sortBy,
    required bool ascending,
    required int limit,
    required int offset,
  }) async {
    // Use RPC function for complex hierarchical filtering
    final response = await _supabase.rpc('get_movies_by_categories_hierarchical', params: {
      'category_ids': categoryIds,
      'sort_by': sortBy,
      'ascending': ascending,
      'result_limit': limit,
      'result_offset': offset,
    });
    return response as List<dynamic>;
  }

  /// Search movies with advanced text search
  Future<List<dynamic>> searchMovies({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _supabase.rpc('search_movies', params: {
      'search_query': query,
      'result_limit': limit,
      'result_offset': offset,
    });
    return response as List<dynamic>;
  }

  /// Get filter metadata (available options)
  Future<Map<String, dynamic>> getFilterMetadata() async {
    final results = await Future.wait([
      _supabase.from('movies').select('status').neq('status', null),
      _supabase.from('movies').select('language').neq('language', null),
      _supabase.from('movies').select('maturity_rating').neq('maturity_rating', null),
      _supabase.from('categories').select('*'),
      _supabase.from('actors').select('id, name'),
    ]);

    return {
      'statuses': (results[0].data as List).map((m) => m['status']).toSet().toList(),
      'languages': (results[1].data as List).map((m) => m['language']).toSet().toList(),
      'maturityRatings': (results[2].data as List).map((m) => m['maturity_rating']).toSet().toList(),
      'categories': results[3].data,
      'actors': results[4].data,
    };
  }

  /// Helper method to convert Duration to PostgreSQL interval string
  String _durationToString(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '00:$minutes:$seconds';
    }
  }
}

/// Filter configuration class for UI
class MovieFilters {
  List<String>? statuses;
  List<String>? languages;
  List<String>? maturityRatings;
  DateTime? releaseYearFrom;
  DateTime? releaseYearTo;
  Duration? durationMin;
  Duration? durationMax;
  String? titleSearch;
  List<String>? categoryIds;
  bool includeSubcategories;
  List<String>? actorIds;
  String sortBy;
  bool ascending;

  MovieFilters({
    this.statuses,
    this.languages,
    this.maturityRatings,
    this.releaseYearFrom,
    this.releaseYearTo,
    this.durationMin,
    this.durationMax,
    this.titleSearch,
    this.categoryIds,
    this.includeSubcategories = true,
    this.actorIds,
    this.sortBy = 'release_date',
    this.ascending = false,
  });

  /// Check if any filters are active
  bool get hasActiveFilters =>
      (statuses?.isNotEmpty ?? false) ||
      (languages?.isNotEmpty ?? false) ||
      (maturityRatings?.isNotEmpty ?? false) ||
      releaseYearFrom != null ||
      releaseYearTo != null ||
      durationMin != null ||
      durationMax != null ||
      (titleSearch?.isNotEmpty ?? false) ||
      (categoryIds?.isNotEmpty ?? false) ||
      (actorIds?.isNotEmpty ?? false);

  /// Clear all filters
  void clear() {
    statuses = null;
    languages = null;
    maturityRatings = null;
    releaseYearFrom = null;
    releaseYearTo = null;
    durationMin = null;
    durationMax = null;
    titleSearch = null;
    categoryIds = null;
    actorIds = null;
    sortBy = 'release_date';
    ascending = false;
  }

  /// Create a copy with modified values
  MovieFilters copyWith({
    List<String>? statuses,
    List<String>? languages,
    List<String>? maturityRatings,
    DateTime? releaseYearFrom,
    DateTime? releaseYearTo,
    Duration? durationMin,
    Duration? durationMax,
    String? titleSearch,
    List<String>? categoryIds,
    bool? includeSubcategories,
    List<String>? actorIds,
    String? sortBy,
    bool? ascending,
  }) {
    return MovieFilters(
      statuses: statuses ?? this.statuses,
      languages: languages ?? this.languages,
      maturityRatings: maturityRatings ?? this.maturityRatings,
      releaseYearFrom: releaseYearFrom ?? this.releaseYearFrom,
      releaseYearTo: releaseYearTo ?? this.releaseYearTo,
      durationMin: durationMin ?? this.durationMin,
      durationMax: durationMax ?? this.durationMax,
      titleSearch: titleSearch ?? this.titleSearch,
      categoryIds: categoryIds ?? this.categoryIds,
      includeSubcategories: includeSubcategories ?? this.includeSubcategories,
      actorIds: actorIds ?? this.actorIds,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }
}