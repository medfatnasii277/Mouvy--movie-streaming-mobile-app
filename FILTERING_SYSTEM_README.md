# Netflix-Style Movie Filtering System - Implementation Guide

## Overview

This document outlines the production-ready filtering system implemented for the Netflix-style movie browsing experience using Supabase, PostgreSQL, and Flutter.

## Architecture

### Core Components

1. **MovieFilterService** (`lib/services/movie_filter_service.dart`)
   - Handles all filtering logic
   - Uses Supabase/PostgREST for database queries
   - Supports complex many-to-many relationships

2. **MovieProvider** (`lib/providers/movie_provider.dart`)
   - State management for movie data
   - Integrates with filtering service
   - Supports pagination and infinite scrolling

3. **Database Functions** (`database/filtering_system.sql`)
   - PostgreSQL functions for advanced filtering
   - Full-text search capabilities
   - Hierarchical category support

## Filtering Capabilities

### Movie-Level Filters

```dart
// Status filtering
statuses: ['released', 'upcoming']

// Language filtering
languages: ['en', 'es', 'fr']

// Maturity rating filtering
maturityRatings: ['PG', 'PG-13', 'R']

// Release year range
releaseYearFrom: DateTime(2020, 1, 1)
releaseYearTo: DateTime(2023, 12, 31)

// Duration range
durationMin: Duration(hours: 1, minutes: 30)
durationMax: Duration(hours: 3, minutes: 0)

// Title search (case-insensitive)
titleSearch: "action movie"
```

### Category-Based Filters

```dart
// Single category
categoryIds: ['uuid-1']

// Multiple categories (OR logic)
categoryIds: ['uuid-1', 'uuid-2', 'uuid-3']

// Parent category with subcategories
categoryIds: ['parent-uuid']
includeSubcategories: true  // Default: true
```

### Actor-Based Filters

```dart
// Single actor
actorIds: ['uuid-1']

// Multiple actors (OR logic)
actorIds: ['uuid-1', 'uuid-2']
```

### Sorting Options

```dart
// Available sort fields
sortBy: 'release_date'  // 'release_date', 'title', 'created_at'
ascending: false        // true for ascending, false for descending
```

## Database Implementation

### Key Functions

#### 1. Hierarchical Category Filtering

```sql
get_movies_by_categories_hierarchical(
  category_ids UUID[],
  sort_by TEXT DEFAULT 'release_date',
  ascending BOOLEAN DEFAULT FALSE,
  result_limit INTEGER DEFAULT 20,
  result_offset INTEGER DEFAULT 0
)
```

**Features:**
- Recursive CTE to traverse category hierarchy
- Includes all subcategories automatically
- Prevents infinite recursion (max depth: 5)
- Returns complete movie data with relationships

#### 2. Advanced Text Search

```sql
search_movies(
  search_query TEXT,
  result_limit INTEGER DEFAULT 20,
  result_offset INTEGER DEFAULT 0
)
```

**Features:**
- Full-text search across title, description, actors, and categories
- Fuzzy matching fallback using pg_trgm
- Search ranking based on relevance
- Supports partial matches and typos

### Performance Indexes

```sql
-- Core filtering indexes
CREATE INDEX idx_movies_status ON movies(status);
CREATE INDEX idx_movies_language ON movies(language);
CREATE INDEX idx_movies_maturity_rating ON movies(maturity_rating);
CREATE INDEX idx_movies_release_date ON movies(release_date DESC);
CREATE INDEX idx_movies_duration ON movies(duration);

-- Text search indexes
CREATE INDEX idx_movies_title_tsv ON movies USING gin (to_tsvector('english', title));
CREATE INDEX idx_movies_title_trgm ON movies USING gin (title gin_trgm_ops);

-- Relationship indexes
CREATE INDEX idx_movie_categories_movie_id ON movie_categories(movie_id);
CREATE INDEX idx_movie_categories_category_id ON movie_categories(category_id);
CREATE INDEX idx_movie_actors_movie_id ON movie_actors(movie_id);
CREATE INDEX idx_movie_actors_actor_id ON movie_actors(actor_id);

-- Composite indexes for common queries
CREATE INDEX idx_movies_status_release_date ON movies(status, release_date DESC);
```

## Usage Examples

### Basic Filtering

```dart
// Filter by action movies released in 2023
final filters = MovieFilters(
  categoryIds: ['action-category-uuid'],
  releaseYearFrom: DateTime(2023, 1, 1),
  releaseYearTo: DateTime(2023, 12, 31),
  sortBy: 'release_date',
  ascending: false,
);

await movieProvider.applyFilters(filters);
```

### Advanced Search

```dart
// Search for movies with "marvel" in title, description, actors, or categories
await movieProvider.searchMovies("marvel");
```

### Infinite Scrolling

```dart
// Load more movies when reaching the end of the list
if (movieProvider.hasMore && !movieProvider.isLoading) {
  await movieProvider.loadMore();
}
```

## Supabase Query Examples

### Simple Movie Filtering

```dart
// Filter by status and language
final response = await supabase
  .from('movies')
  .select('*, categories:movie_categories(categories(*))')
  .in_('status', ['released'])
  .in_('language', ['en', 'es'])
  .order('release_date', ascending: false)
  .limit(20);
```

### Many-to-Many Category Filtering

```dart
// Movies in specific categories (direct relationship)
final response = await supabase
  .from('movies')
  .select('*, categories:movie_categories(categories(*))')
  .in_('movie_categories.category_id', categoryIds)
  .order('release_date', ascending: false);
```

### Hierarchical Category Filtering

```dart
// Using RPC function for subcategories
final response = await supabase.rpc('get_movies_by_categories_hierarchical', params: {
  'category_ids': categoryIds,
  'sort_by': 'release_date',
  'ascending': false,
  'result_limit': 20,
  'result_offset': 0,
});
```

### Text Search

```dart
// Advanced search with ranking
final response = await supabase.rpc('search_movies', params: {
  'search_query': 'action hero',
  'result_limit': 50,
});
```

## Performance Considerations

### Database Optimization

1. **Indexes**: Comprehensive indexing on all filter fields
2. **Query Planning**: Use EXPLAIN ANALYZE to optimize complex queries
3. **Pagination**: Cursor-based pagination for large datasets
4. **Connection Pooling**: Supabase handles this automatically

### Application-Level Optimization

1. **Caching**: Cache filter metadata and popular results
2. **Debouncing**: Debounce search queries to reduce API calls
3. **Lazy Loading**: Load images and heavy content on demand
4. **State Management**: Efficient state updates to prevent unnecessary rebuilds

### Recommended Index Strategy

```sql
-- High-priority indexes (most frequently used)
CREATE INDEX idx_movies_status_release_date ON movies(status, release_date DESC);
CREATE INDEX idx_movies_title_tsv ON movies USING gin (to_tsvector('english', title));

-- Medium-priority indexes
CREATE INDEX idx_movie_categories_category_id ON movie_categories(category_id);
CREATE INDEX idx_movie_actors_actor_id ON movie_actors(actor_id);

-- Low-priority indexes (for specific use cases)
CREATE INDEX idx_movies_duration ON movies(duration);
CREATE INDEX idx_categories_parent_id ON categories(parent_id);
```

## Security & RLS

### Row Level Security Policies

```sql
-- Public read access for released movies only
CREATE POLICY "Public read access for movies" ON movies
  FOR SELECT USING (status = 'released');

-- Category and actor data is publicly readable
CREATE POLICY "Public read access for categories" ON categories FOR SELECT USING (true);
CREATE POLICY "Public read access for actors" ON actors FOR SELECT USING (true);

-- Junction tables respect movie visibility
CREATE POLICY "Public read access for movie_categories" ON movie_categories
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM movies m WHERE m.id = movie_categories.movie_id AND m.status = 'released')
  );
```

## Deployment Instructions

### 1. Database Setup

Run the SQL file in your Supabase SQL editor:

```bash
# Execute the filtering system SQL
psql -f database/filtering_system.sql
```

### 2. Environment Variables

Ensure your Supabase configuration is set up:

```dart
// In your main.dart or config file
await Supabase.initialize(
  url: 'your-supabase-url',
  anonKey: 'your-anon-key',
);
```

### 3. Testing

Test the filtering system with various combinations:

```dart
// Test basic filtering
await movieProvider.applyFilters(MovieFilters(
  statuses: ['released'],
  languages: ['en'],
));

// Test search
await movieProvider.searchMovies('action');

// Test category filtering
await movieProvider.applyFilters(MovieFilters(
  categoryIds: ['action-category-id'],
  includeSubcategories: true,
));
```

## Monitoring & Maintenance

### Query Performance

Monitor slow queries in Supabase dashboard and optimize with additional indexes if needed.

### Data Consistency

Regularly audit junction tables to ensure referential integrity:

```sql
-- Check for orphaned records
SELECT * FROM movie_categories mc
LEFT JOIN movies m ON mc.movie_id = m.id
WHERE m.id IS NULL;

SELECT * FROM movie_actors ma
LEFT JOIN movies m ON ma.movie_id = m.id
WHERE m.id IS NULL;
```

### Index Maintenance

Rebuild indexes periodically for optimal performance:

```sql
REINDEX INDEX CONCURRENTLY idx_movies_title_tsv;
REINDEX INDEX CONCURRENTLY idx_movies_title_trgm;
```

## Future Enhancements

1. **Advanced Search**: Implement more sophisticated ranking algorithms
2. **Personalization**: User-based recommendations and preferences
3. **Analytics**: Track popular filters and search terms
4. **Caching**: Implement Redis caching for frequently accessed data
5. **Real-time**: Live updates for new releases and status changes

## Troubleshooting

### Common Issues

1. **Slow Queries**: Check indexes and query plans
2. **RLS Blocking**: Verify user permissions and policies
3. **Type Casting Errors**: Ensure proper JSON parsing in models
4. **Pagination Issues**: Verify offset calculations and limits

### Debug Queries

```sql
-- Check query performance
EXPLAIN ANALYZE SELECT * FROM movies WHERE status = 'released' ORDER BY release_date DESC LIMIT 20;

-- Verify RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies WHERE tablename = 'movies';
```

This implementation provides a robust, scalable filtering system suitable for production Netflix-style applications with millions of movies and users.