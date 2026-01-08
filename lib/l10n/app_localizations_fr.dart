import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Mouvy';

  @override
  String get movies => 'Films';

  @override
  String welcome(Object username) {
    return 'Bienvenue, $username';
  }

  @override
  String get login => 'Se connecter';

  @override
  String get register => 'S\'inscrire';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte ? S\'inscrire';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ? Se connecter';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get viewFavorites => 'Voir les favoris';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get changeProfilePicture => 'Changer la photo de profil';

  @override
  String get searchMovies => 'Rechercher des films...';

  @override
  String get noMoviesFound => 'Aucun film trouvé';

  @override
  String get noMoviesAvailable => 'Aucun film disponible';

  @override
  String get movieNotFound => 'Film non trouvé';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get retry => 'Réessayer';

  @override
  String get addComment => 'Ajouter un commentaire...';

  @override
  String get submit => 'Soumettre';

  @override
  String get like => 'Aimer';

  @override
  String get likes => 'j\'aime';

  @override
  String get comments => 'Commentaires';

  @override
  String get rateMovie => 'Évaluer ce film';

  @override
  String get yourRating => 'Votre note';

  @override
  String get averageRating => 'Note moyenne';

  @override
  String get cast => 'Distribution';

  @override
  String get director => 'Réalisateur';

  @override
  String get genre => 'Genre';

  @override
  String get releaseDate => 'Date de sortie';

  @override
  String get duration => 'Durée';

  @override
  String get description => 'Description';

  @override
  String get watchTrailer => 'Voir la bande-annonce';

  @override
  String get play => 'Lire';

  @override
  String get playComingSoon => 'Fonctionnalité de lecture bientôt disponible !';

  @override
  String get addToFavorites => 'Ajouter aux favoris';

  @override
  String get removeFromFavorites => 'Retirer des favoris';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'Aucune notification pour le moment';

  @override
  String get markAsRead => 'Marquer comme lu';

  @override
  String get language => 'Langue';

  @override
  String get english => 'Anglais';

  @override
  String get french => 'Français';

  @override
  String get settings => 'Paramètres';

  @override
  String get as => 'en tant que';

  @override
  String get permissionDeniedPhotos => 'Permission refusée pour accéder aux photos. Veuillez l\'activer dans les paramètres.';

  @override
  String get failedToPickImage => 'Échec de la sélection de l\'image';

  @override
  String get failedToUploadImage => 'Échec du téléchargement de l\'image';

  @override
  String get profileUpdatedSuccessfully => 'Profil mis à jour avec succès';

  @override
  String get failedToUpdateProfile => 'Échec de la mise à jour du profil';
}
