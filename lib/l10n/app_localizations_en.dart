import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Mouvy';

  @override
  String get movies => 'Movies';

  @override
  String welcome(Object username) {
    return 'Welcome back, $username';
  }

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get createAccount => 'Create account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get username => 'Username';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Register';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get logout => 'Logout';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get viewFavorites => 'View Favorites';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get changeProfilePicture => 'Change Profile Picture';

  @override
  String get searchMovies => 'Search movies...';

  @override
  String get noMoviesFound => 'No movies found';

  @override
  String get noMoviesAvailable => 'No movies available';

  @override
  String get movieNotFound => 'Movie not found';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get addComment => 'Add a comment...';

  @override
  String get submit => 'Submit';

  @override
  String get like => 'Like';

  @override
  String get likes => 'likes';

  @override
  String get comments => 'Comments';

  @override
  String get rateMovie => 'Rate this movie';

  @override
  String get yourRating => 'Your rating';

  @override
  String get averageRating => 'Average rating';

  @override
  String get cast => 'Cast';

  @override
  String get director => 'Director';

  @override
  String get genre => 'Genre';

  @override
  String get releaseDate => 'Release Date';

  @override
  String get duration => 'Duration';

  @override
  String get description => 'Description';

  @override
  String get watchTrailer => 'Watch Trailer';

  @override
  String get play => 'Play';

  @override
  String get playComingSoon => 'Play functionality coming soon!';

  @override
  String get addToFavorites => 'Add to Favorites';

  @override
  String get removeFromFavorites => 'Remove from Favorites';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get markAsRead => 'Mark as read';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get french => 'French';

  @override
  String get settings => 'Settings';

  @override
  String get as => 'as';

  @override
  String get permissionDeniedPhotos => 'Permission denied to access photos. Please enable it in settings.';

  @override
  String get failedToPickImage => 'Failed to pick image';

  @override
  String get failedToUploadImage => 'Failed to upload image';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String get failedToUpdateProfile => 'Failed to update profile';
}
