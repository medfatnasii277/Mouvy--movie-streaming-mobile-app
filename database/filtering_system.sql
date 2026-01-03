-- =====================================================
-- Netflix-Style Movie Filtering System - Database Functions
-- =====================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =====================================================
-- 1. HIERARCHICAL CATEGORY FILTERING
-- =====================================================

-- Function to get movies by categories including subcategories
CREATE OR REPLACE FUNCTION get_movies_by_categories_hierarchical(
  category_ids UUID[],
  sort_by TEXT DEFAULT 'release_date',
  ascending BOOLEAN DEFAULT FALSE,
  result_limit INTEGER DEFAULT 20,
  result_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  release_date DATE,
  duration INTERVAL,
  maturity_rating TEXT,
  language TEXT,
  poster_url TEXT,
  status TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  categories JSONB,
  actors JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  category_query TEXT;
BEGIN
  -- Build query to get all category IDs including subcategories
  category_query := format('
    WITH RECURSIVE category_tree AS (
      -- Base categories
      SELECT id, name, parent_id, 0 as depth
      FROM categories
      WHERE id = ANY(%L::UUID[])

      UNION ALL

      -- Child categories
      SELECT c.id, c.name, c.parent_id, ct.depth + 1
      FROM categories c
      INNER JOIN category_tree ct ON c.parent_id = ct.id
      WHERE ct.depth < 5  -- Prevent infinite recursion
    )
    SELECT DISTINCT id FROM category_tree
  ', category_ids);

  RETURN QUERY
  EXECUTE format('
    SELECT
      m.id,
      m.title,
      m.description,
      m.release_date,
      m.duration,
      m.maturity_rating,
      m.language,
      m.poster_url,
      m.status,
      m.created_at,
      m.updated_at,
      COALESCE(
        jsonb_agg(
          DISTINCT jsonb_build_object(
            ''id'', c.id,
            ''name'', c.name,
            ''description'', c.description,
            ''parent_id'', c.parent_id
          )
        ) FILTER (WHERE c.id IS NOT NULL),
        ''[]''::jsonb
      ) as categories,
      COALESCE(
        jsonb_agg(
          DISTINCT jsonb_build_object(
            ''id'', ma.id,
            ''movie_id'', ma.movie_id,
            ''actor_id'', ma.actor_id,
            ''role_name'', ma.role_name,
            ''billing_order'', ma.billing_order,
            ''actor'', jsonb_build_object(
              ''id'', a.id,
              ''name'', a.name,
              ''birth_date'', a.birth_date,
              ''biography'', a.biography
            )
          )
        ) FILTER (WHERE ma.id IS NOT NULL),
        ''[]''::jsonb
      ) as actors
    FROM movies m
    LEFT JOIN movie_categories mc ON m.id = mc.movie_id
    LEFT JOIN categories c ON mc.category_id = c.id
    LEFT JOIN movie_actors ma ON m.id = ma.movie_id
    LEFT JOIN actors a ON ma.actor_id = a.id
    WHERE mc.category_id IN (' || category_query || ')
    GROUP BY m.id, m.title, m.description, m.release_date, m.duration,
             m.maturity_rating, m.language, m.poster_url, m.status,
             m.created_at, m.updated_at
    ORDER BY
      CASE WHEN %L = ''release_date'' AND %L = false THEN m.release_date END DESC,
      CASE WHEN %L = ''release_date'' AND %L = true THEN m.release_date END ASC,
      CASE WHEN %L = ''title'' AND %L = false THEN m.title END DESC,
      CASE WHEN %L = ''title'' AND %L = true THEN m.title END ASC,
      CASE WHEN %L = ''created_at'' AND %L = false THEN m.created_at END DESC,
      CASE WHEN %L = ''created_at'' AND %L = true THEN m.created_at END ASC
    LIMIT %s OFFSET %s
  ',
  sort_by, ascending, sort_by, ascending,
  sort_by, ascending, sort_by, ascending,
  sort_by, ascending, sort_by, ascending,
  result_limit, result_offset);
END;
$$;

-- =====================================================
-- 2. ADVANCED TEXT SEARCH
-- =====================================================

-- Function for advanced movie search
CREATE OR REPLACE FUNCTION search_movies(
  search_query TEXT,
  result_limit INTEGER DEFAULT 20,
  result_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  release_date DATE,
  duration INTERVAL,
  maturity_rating TEXT,
  language TEXT,
  poster_url TEXT,
  status TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  categories JSONB,
  actors JSONB,
  search_rank REAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    m.id,
    m.title,
    m.description,
    m.release_date,
    m.duration,
    m.maturity_rating,
    m.language,
    m.poster_url,
    m.status,
    m.created_at,
    m.updated_at,
    COALESCE(
      jsonb_agg(
        DISTINCT jsonb_build_object(
          'id', c.id,
          'name', c.name,
          'description', c.description,
          'parent_id', c.parent_id
        )
      ) FILTER (WHERE c.id IS NOT NULL),
      '[]'::jsonb
    ) as categories,
    COALESCE(
      jsonb_agg(
        DISTINCT jsonb_build_object(
          'id', ma.id,
          'movie_id', ma.movie_id,
          'actor_id', ma.actor_id,
          'role_name', ma.role_name,
          'billing_order', ma.billing_order,
          'actor', jsonb_build_object(
            'id', a.id,
            'name', a.name,
            'birth_date', a.birth_date,
            'biography', a.biography
          )
        )
      ) FILTER (WHERE ma.id IS NOT NULL),
      '[]'::jsonb
    ) as actors,
    -- Full-text search ranking
    (
      ts_rank_cd(to_tsvector('english', m.title), plainto_tsquery('english', search_query)) +
      ts_rank_cd(to_tsvector('english', COALESCE(m.description, '')), plainto_tsquery('english', search_query)) +
      ts_rank_cd(to_tsvector('english', COALESCE(string_agg(DISTINCT a.name, ' '), '')), plainto_tsquery('english', search_query)) +
      ts_rank_cd(to_tsvector('english', COALESCE(string_agg(DISTINCT c.name, ' '), '')), plainto_tsquery('english', search_query))
    ) as search_rank
  FROM movies m
  LEFT JOIN movie_categories mc ON m.id = mc.movie_id
  LEFT JOIN categories c ON mc.category_id = c.id
  LEFT JOIN movie_actors ma ON m.id = ma.movie_id
  LEFT JOIN actors a ON ma.actor_id = a.id
  WHERE
    -- Full-text search condition
    to_tsvector('english', m.title) @@ plainto_tsquery('english', search_query) OR
    to_tsvector('english', COALESCE(m.description, '')) @@ plainto_tsquery('english', search_query) OR
    to_tsvector('english', COALESCE(a.name, '')) @@ plainto_tsquery('english', search_query) OR
    to_tsvector('english', COALESCE(c.name, '')) @@ plainto_tsquery('english', search_query) OR
    -- Fuzzy matching fallback
    m.title % search_query OR
    COALESCE(m.description, '') % search_query
  GROUP BY m.id, m.title, m.description, m.release_date, m.duration,
           m.maturity_rating, m.language, m.poster_url, m.status,
           m.created_at, m.updated_at
  HAVING
    -- Ensure at least one match
    COUNT(*) FILTER (
      WHERE to_tsvector('english', m.title) @@ plainto_tsquery('english', search_query) OR
            to_tsvector('english', COALESCE(m.description, '')) @@ plainto_tsquery('english', search_query) OR
            to_tsvector('english', COALESCE(a.name, '')) @@ plainto_tsquery('english', search_query) OR
            to_tsvector('english', COALESCE(c.name, '')) @@ plainto_tsquery('english', search_query) OR
            m.title % search_query OR
            COALESCE(m.description, '') % search_query
    ) > 0
  ORDER BY search_rank DESC, m.created_at DESC
  LIMIT result_limit OFFSET result_offset;
END;
$$;

-- =====================================================
-- 3. PERFORMANCE INDEXES
-- =====================================================

-- Core movie filtering indexes
CREATE INDEX IF NOT EXISTS idx_movies_status ON movies(status);
CREATE INDEX IF NOT EXISTS idx_movies_language ON movies(language);
CREATE INDEX IF NOT EXISTS idx_movies_maturity_rating ON movies(maturity_rating);
CREATE INDEX IF NOT EXISTS idx_movies_release_date ON movies(release_date DESC);
CREATE INDEX IF NOT EXISTS idx_movies_duration ON movies(duration);
CREATE INDEX IF NOT EXISTS idx_movies_created_at ON movies(created_at DESC);

-- Text search indexes
CREATE INDEX IF NOT EXISTS idx_movies_title_trgm ON movies USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_movies_description_trgm ON movies USING gin (description gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_movies_title_tsv ON movies USING gin (to_tsvector('english', title));
CREATE INDEX IF NOT EXISTS idx_movies_description_tsv ON movies USING gin (to_tsvector('english', description));

-- Category relationship indexes
CREATE INDEX IF NOT EXISTS idx_movie_categories_movie_id ON movie_categories(movie_id);
CREATE INDEX IF NOT EXISTS idx_movie_categories_category_id ON movie_categories(category_id);
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories(parent_id);

-- Actor relationship indexes
CREATE INDEX IF NOT EXISTS idx_movie_actors_movie_id ON movie_actors(movie_id);
CREATE INDEX IF NOT EXISTS idx_movie_actors_actor_id ON movie_actors(actor_id);
CREATE INDEX IF NOT EXISTS idx_movie_actors_billing_order ON movie_actors(billing_order);

-- Actor search indexes
CREATE INDEX IF NOT EXISTS idx_actors_name_trgm ON actors USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_actors_name_tsv ON actors USING gin (to_tsvector('english', name));

-- Category search indexes
CREATE INDEX IF NOT EXISTS idx_categories_name_trgm ON categories USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_categories_name_tsv ON categories USING gin (to_tsvector('english', name));

-- Composite indexes for common filter combinations
CREATE INDEX IF NOT EXISTS idx_movies_status_release_date ON movies(status, release_date DESC);
CREATE INDEX IF NOT EXISTS idx_movies_language_release_date ON movies(language, release_date DESC);
CREATE INDEX IF NOT EXISTS idx_movies_maturity_release_date ON movies(maturity_rating, release_date DESC);

-- =====================================================
-- 4. USEFUL VIEWS FOR COMMON QUERIES
-- =====================================================

-- View for movies with category counts (useful for UI)
CREATE OR REPLACE VIEW movie_category_counts AS
SELECT
  m.id,
  m.title,
  COUNT(mc.category_id) as category_count,
  array_agg(c.name ORDER BY c.name) as category_names
FROM movies m
LEFT JOIN movie_categories mc ON m.id = mc.movie_id
LEFT JOIN categories c ON mc.category_id = c.id
GROUP BY m.id, m.title;

-- View for movies with actor counts
CREATE OR REPLACE VIEW movie_actor_counts AS
SELECT
  m.id,
  m.title,
  COUNT(ma.actor_id) as actor_count,
  array_agg(a.name ORDER BY ma.billing_order) as actor_names
FROM movies m
LEFT JOIN movie_actors ma ON m.id = ma.movie_id
LEFT JOIN actors a ON ma.actor_id = a.id
GROUP BY m.id, m.title;

-- View for category hierarchy
CREATE OR REPLACE VIEW category_hierarchy AS
WITH RECURSIVE category_tree AS (
  -- Root categories
  SELECT
    id,
    name,
    parent_id,
    0 as level,
    ARRAY[name] as path,
    id as root_id
  FROM categories
  WHERE parent_id IS NULL

  UNION ALL

  -- Child categories
  SELECT
    c.id,
    c.name,
    c.parent_id,
    ct.level + 1,
    ct.path || c.name,
    ct.root_id
  FROM categories c
  JOIN category_tree ct ON c.parent_id = ct.id
  WHERE ct.level < 5  -- Prevent infinite recursion
)
SELECT * FROM category_tree;

-- =====================================================
-- 5. RLS POLICIES (if not already set)
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE movies ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE actors ENABLE ROW LEVEL SECURITY;
ALTER TABLE movie_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE movie_actors ENABLE ROW LEVEL SECURITY;

-- Public read access for movies (as requested)
CREATE POLICY "Public read access for movies" ON movies
  FOR SELECT USING (status = 'released');

CREATE POLICY "Public read access for categories" ON categories
  FOR SELECT USING (true);

CREATE POLICY "Public read access for actors" ON actors
  FOR SELECT USING (true);

CREATE POLICY "Public read access for movie_categories" ON movie_categories
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM movies m
      WHERE m.id = movie_categories.movie_id
      AND m.status = 'released'
    )
  );

CREATE POLICY "Public read access for movie_actors" ON movie_actors
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM movies m
      WHERE m.id = movie_actors.movie_id
      AND m.status = 'released'
    )
  );

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_movies_by_categories_hierarchical TO anon, authenticated;
GRANT EXECUTE ON FUNCTION search_movies TO anon, authenticated;