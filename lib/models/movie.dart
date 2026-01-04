class Movie {
  final String id;
  final String title;
  final String? description;
  final DateTime? releaseDate;
  final Duration? duration;
  final String? maturityRating;
  final String? language;
  final String? posterUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Category> categories;
  final List<MovieActor> actors;

  Movie({
    required this.id,
    required this.title,
    this.description,
    this.releaseDate,
    this.duration,
    this.maturityRating,
    this.language,
    this.posterUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.categories,
    required this.actors,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Title',
      description: json['description']?.toString(),
      releaseDate: json['release_date'] != null ? DateTime.parse(json['release_date']) : null,
      duration: json['duration'] != null ? parseDuration(json['duration']) : null,
      maturityRating: json['maturity_rating']?.toString(),
      language: json['language']?.toString(),
      posterUrl: json['poster_url']?.toString(),
      status: json['status']?.toString() ?? 'unknown',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      categories: (json['categories'] as List<dynamic>?)
          ?.map((c) => Category.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      actors: (json['actors'] as List<dynamic>?)
          ?.map((a) => MovieActor.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  static Duration? parseDuration(String? durationString) {
    if (durationString == null) return null;
    final parts = durationString.split(':');
    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]) ?? 0;
      final minutes = int.tryParse(parts[1]) ?? 0;
      final seconds = int.tryParse(parts[2]) ?? 0;
      return Duration(hours: hours, minutes: minutes, seconds: seconds);
    }
    return null;
  }

  String get formattedDuration {
    if (duration == null) return '';
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get categoriesText => categories.map((c) => c.name).join(', ');
}

class Category {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      parentId: json['parent_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class Actor {
  final String id;
  final String name;
  final DateTime? birthDate;
  final String? biography;
  final DateTime createdAt;
  final DateTime updatedAt;

  Actor({
    required this.id,
    required this.name,
    this.birthDate,
    this.biography,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Actor.fromJson(Map<String, dynamic> json) {
    return Actor(
      id: json['id'],
      name: json['name'],
      birthDate: json['birth_date'] != null ? DateTime.parse(json['birth_date']) : null,
      biography: json['biography'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class MovieActor {
  final String id;
  final String movieId;
  final String actorId;
  final String? roleName;
  final int? billingOrder;
  final DateTime createdAt;
  final Actor actor;

  MovieActor({
    required this.id,
    required this.movieId,
    required this.actorId,
    this.roleName,
    this.billingOrder,
    required this.createdAt,
    required this.actor,
  });

  factory MovieActor.fromJson(Map<String, dynamic> json) {
    return MovieActor(
      id: json['id'],
      movieId: json['movie_id'],
      actorId: json['actor_id'],
      roleName: json['role_name'],
      billingOrder: json['billing_order'],
      createdAt: DateTime.parse(json['created_at']),
      actor: Actor.fromJson(json['actor'] as Map<String, dynamic>),
    );
  }
}