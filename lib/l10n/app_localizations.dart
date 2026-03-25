import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Core App
      'app_name': 'VibeNou',
      'welcome': 'Welcome to VibeNou',
      'meet_n_connect': 'Meet N Connect',
      'connect_community': 'Connect with your community',

      // Authentication
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'reset_password': 'Reset Password',
      'send_reset_link': 'Send Reset Link',
      'continue_with_google': 'Continue with Google',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',

      // Profile
      'name': 'Name',
      'age': 'Age',
      'bio': 'Bio',
      'interests': 'Interests',
      'location': 'Location',
      'profile': 'Profile',
      'edit_profile': 'Edit Profile',
      'manage_photos': 'Manage Photos',
      'profile_views': 'Profile Views',
      'see_who_viewed': 'See who viewed your profile',
      'no_profile_views': 'No profile views yet',

      // Settings
      'settings': 'Settings',
      'preferences': 'Preferences',
      'language': 'Language',
      'theme': 'Theme',
      'light_mode': 'Light Mode',
      'dark_mode': 'Dark Mode',
      'system_default': 'System Default',
      'follows_device_theme': 'Follows your device theme',
      'notification_sound': 'Notification Sound',
      'select_language': 'Select Language',
      'select_theme': 'Select Theme',
      'update_location': 'Update Location',
      'location_updated': 'Location updated to: ',
      'getting_location': 'Getting your location...',
      'location_update_confirm': 'This will update your location using your current GPS position. Continue?',
      'failed_get_location': 'Failed to get location. Please enable location services.',
      'error_updating_location': 'Error updating location: ',
      'account': 'Account',
      'version': 'Version',

      // Logout
      'logout': 'Logout',
      'logout_confirm': 'Are you sure you want to logout?',
      'yes': 'Yes',
      'no': 'No',

      // Navigation
      'discover': 'Discover',
      'matches': 'Matches',
      'chat': 'Chat',
      'nearby_users': 'Nearby Users',
      'similar_interests': 'Similar Interests',
      'distance': 'Distance',

      // Messages
      'send_message': 'Send a message...',
      'start_chat': 'Start Chat',
      'no_messages': 'No messages yet',
      'type_message': 'Type a message...',

      // Actions
      'save': 'Save',
      'cancel': 'Cancel',
      'submit': 'Submit',
      'close': 'Close',
      'continue': 'Continue',
      'skip': 'Skip',
      'done': 'Done',
      'update': 'Update',
      'delete': 'Delete',
      'confirm': 'Confirm',

      // Report
      'report_user': 'Report User',
      'report_reason': 'Report Reason',
      'harassment': 'Harassment',
      'inappropriate_content': 'Inappropriate Content',
      'spam': 'Spam',
      'fake_profile': 'Fake Profile',
      'other': 'Other',
      'report_submitted': 'Report submitted successfully',

      // Errors & Status
      'error': 'An error occurred',
      'no_users_found': 'No users found nearby',
      'enable_location': 'Enable Location',
      'location_permission_required': 'Location permission is required',
      'please_login': 'Please log in to view your profile',
      'profile_not_found': 'Profile data not found',

      // Onboarding
      'get_started': 'Get Started',
      'next': 'Next',
      'onboarding_welcome': 'Welcome to VibeNou',
      'onboarding_discover': 'Discover Your Match',
      'onboarding_chat': 'Connect & Chat',
      'onboarding_safety': 'Safe & Secure',
      'onboarding_ready': 'Ready to Start?',
    },

    'fr': {
      // Core App
      'app_name': 'VibeNou',
      'welcome': 'Bienvenue à VibeNou',
      'meet_n_connect': 'Rencontrer et Se Connecter',
      'connect_community': 'Connectez-vous avec votre communauté',

      // Authentication
      'sign_in': 'Se Connecter',
      'sign_up': 'S\'inscrire',
      'email': 'E-mail',
      'password': 'Mot de passe',
      'forgot_password': 'Mot de passe oublié?',
      'reset_password': 'Réinitialiser le mot de passe',
      'send_reset_link': 'Envoyer le lien de réinitialisation',
      'continue_with_google': 'Continuer avec Google',
      'dont_have_account': 'Vous n\'avez pas de compte?',
      'already_have_account': 'Vous avez déjà un compte?',

      // Profile
      'name': 'Nom',
      'age': 'Âge',
      'bio': 'Biographie',
      'interests': 'Intérêts',
      'location': 'Localisation',
      'profile': 'Profil',
      'edit_profile': 'Modifier le profil',
      'manage_photos': 'Gérer les photos',
      'profile_views': 'Vues du profil',
      'see_who_viewed': 'Voir qui a consulté votre profil',
      'no_profile_views': 'Aucune vue de profil pour le moment',

      // Settings
      'settings': 'Paramètres',
      'preferences': 'Préférences',
      'language': 'Langue',
      'theme': 'Thème',
      'light_mode': 'Mode Clair',
      'dark_mode': 'Mode Sombre',
      'system_default': 'Par Défaut du Système',
      'follows_device_theme': 'Suit le thème de votre appareil',
      'notification_sound': 'Son de notification',
      'select_language': 'Sélectionner la langue',
      'select_theme': 'Sélectionner le thème',
      'update_location': 'Mettre à jour la localisation',
      'location_updated': 'Localisation mise à jour vers: ',
      'getting_location': 'Obtention de votre localisation...',
      'location_update_confirm': 'Cela mettra à jour votre position GPS actuelle. Continuer?',
      'failed_get_location': 'Échec de l\'obtention de la localisation. Veuillez activer les services de localisation.',
      'error_updating_location': 'Erreur lors de la mise à jour de la localisation: ',
      'account': 'Compte',
      'version': 'Version',

      // Logout
      'logout': 'Déconnexion',
      'logout_confirm': 'Êtes-vous sûr de vouloir vous déconnecter?',
      'yes': 'Oui',
      'no': 'Non',

      // Navigation
      'discover': 'Découvrir',
      'matches': 'Correspondances',
      'chat': 'Chat',
      'nearby_users': 'Utilisateurs à proximité',
      'similar_interests': 'Intérêts similaires',
      'distance': 'Distance',

      // Messages
      'send_message': 'Envoyer un message...',
      'start_chat': 'Commencer le chat',
      'no_messages': 'Pas encore de messages',
      'type_message': 'Tapez un message...',

      // Actions
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'submit': 'Soumettre',
      'close': 'Fermer',
      'continue': 'Continuer',
      'skip': 'Passer',
      'done': 'Terminé',
      'update': 'Mettre à jour',
      'delete': 'Supprimer',
      'confirm': 'Confirmer',

      // Report
      'report_user': 'Signaler l\'utilisateur',
      'report_reason': 'Raison du signalement',
      'harassment': 'Harcèlement',
      'inappropriate_content': 'Contenu inapproprié',
      'spam': 'Spam',
      'fake_profile': 'Faux profil',
      'other': 'Autre',
      'report_submitted': 'Signalement soumis avec succès',

      // Errors & Status
      'error': 'Une erreur s\'est produite',
      'no_users_found': 'Aucun utilisateur trouvé à proximité',
      'enable_location': 'Activer la localisation',
      'location_permission_required': 'L\'autorisation de localisation est requise',
      'please_login': 'Veuillez vous connecter pour voir votre profil',
      'profile_not_found': 'Données de profil introuvables',

      // Onboarding
      'get_started': 'Commencer',
      'next': 'Suivant',
      'onboarding_welcome': 'Bienvenue à VibeNou',
      'onboarding_discover': 'Découvrez Votre Match',
      'onboarding_chat': 'Connectez-vous et Discutez',
      'onboarding_safety': 'Sûr et Sécurisé',
      'onboarding_ready': 'Prêt à Commencer?',
    },

    'ht': {
      // Core App
      'app_name': 'VibeNou',
      'welcome': 'Byenveni nan VibeNou',
      'meet_n_connect': 'Rankontre epi Konekte',
      'connect_community': 'Konekte avèk kominote w',

      // Authentication
      'sign_in': 'Konekte',
      'sign_up': 'Enskri',
      'email': 'Imèl',
      'password': 'Modpas',
      'forgot_password': 'Bliye modpas?',
      'reset_password': 'Reyajiste modpas',
      'send_reset_link': 'Voye lyen reyajisteman',
      'continue_with_google': 'Kontinye avèk Google',
      'dont_have_account': 'Ou pa gen kont?',
      'already_have_account': 'Ou deja gen yon kont?',

      // Profile
      'name': 'Non',
      'age': 'Laj',
      'bio': 'Byografi',
      'interests': 'Enterè',
      'location': 'Kote w ye',
      'profile': 'Pwofil',
      'edit_profile': 'Modifye pwofil',
      'manage_photos': 'Jere foto yo',
      'profile_views': 'Moun ki gade pwofil ou',
      'see_who_viewed': 'Gade ki moun ki te gade pwofil ou',
      'no_profile_views': 'Pèsonn poko gade pwofil ou',

      // Settings
      'settings': 'Paramèt',
      'preferences': 'Preferans',
      'language': 'Lang',
      'theme': 'Tèm',
      'light_mode': 'Mòd Klè',
      'dark_mode': 'Mòd Fènwa',
      'system_default': 'Pa Defo Sistèm',
      'follows_device_theme': 'Suiv tèm aparèy ou a',
      'notification_sound': 'Son notifikasyon',
      'select_language': 'Chwazi lang',
      'select_theme': 'Chwazi tèm',
      'update_location': 'Mete ajou kote w ye',
      'location_updated': 'Kote w ye mete ajou nan: ',
      'getting_location': 'N ap jwenn kote w ye...',
      'location_update_confirm': 'Sa ap mete ajou pozisyon GPS ou kounye a. Kontinye?',
      'failed_get_location': 'Pa t ka jwenn kote w ye. Tanpri aktive sèvis lokalizasyon.',
      'error_updating_location': 'Erè pandan mete ajou kote w ye: ',
      'account': 'Kont',
      'version': 'Vèsyon',

      // Logout
      'logout': 'Dekonekte',
      'logout_confirm': 'Ou sèten ou vle dekonekte?',
      'yes': 'Wi',
      'no': 'Non',

      // Navigation
      'discover': 'Dekouvri',
      'matches': 'Koneksyon',
      'chat': 'Diskite',
      'nearby_users': 'Itilizatè tou pre',
      'similar_interests': 'Menm enterè',
      'distance': 'Distans',

      // Messages
      'send_message': 'Voye yon mesaj...',
      'start_chat': 'Kòmanse diskite',
      'no_messages': 'Poko gen mesaj',
      'type_message': 'Ekri yon mesaj...',

      // Actions
      'save': 'Anrejistre',
      'cancel': 'Anile',
      'submit': 'Soumèt',
      'close': 'Fèmen',
      'continue': 'Kontinye',
      'skip': 'Sote',
      'done': 'Fini',
      'update': 'Mete ajou',
      'delete': 'Efase',
      'confirm': 'Konfime',

      // Report
      'report_user': 'Rapòte itilizatè',
      'report_reason': 'Rezon rapò',
      'harassment': 'Atak',
      'inappropriate_content': 'Kontni pa apwopriye',
      'spam': 'Spam',
      'fake_profile': 'Fo pwofil',
      'other': 'Lòt',
      'report_submitted': 'Rapò soumèt avèk siksè',

      // Errors & Status
      'error': 'Yon erè rive',
      'no_users_found': 'Pa gen itilizatè tou pre',
      'enable_location': 'Aktive lokalizasyon',
      'location_permission_required': 'Ou bezwen pèmisyon lokalizasyon',
      'please_login': 'Tanpri konekte pou gade pwofil ou',
      'profile_not_found': 'Pa jwenn done pwofil',

      // Onboarding
      'get_started': 'Kòmanse Kounye a',
      'next': 'Swivan',
      'onboarding_welcome': 'Byenveni nan VibeNou',
      'onboarding_discover': 'Dekouvri Patnè w',
      'onboarding_chat': 'Konekte epi Pale',
      'onboarding_safety': 'Sekirite epi Konfyans',
      'onboarding_ready': 'Ou Pare Kòmanse?',
    },
  };

  String translate(String key) {
    final value = _localizedValues[locale.languageCode]?[key];
    if (value == null) {
      AppLogger.warning('Missing translation for key "$key" in locale "${locale.languageCode}"');
    }
    return value ?? key;
  }

  // Core App
  String get appName => translate('app_name');
  String get welcome => translate('welcome');
  String get meetNConnect => translate('meet_n_connect');
  String get connectCommunity => translate('connect_community');

  // Authentication
  String get signIn => translate('sign_in');
  String get signUp => translate('sign_up');
  String get email => translate('email');
  String get password => translate('password');
  String get forgotPassword => translate('forgot_password');
  String get resetPassword => translate('reset_password');
  String get sendResetLink => translate('send_reset_link');
  String get continueWithGoogle => translate('continue_with_google');
  String get dontHaveAccount => translate('dont_have_account');
  String get alreadyHaveAccount => translate('already_have_account');

  // Profile
  String get name => translate('name');
  String get age => translate('age');
  String get bio => translate('bio');
  String get interests => translate('interests');
  String get location => translate('location');
  String get profile => translate('profile');
  String get editProfile => translate('edit_profile');
  String get managePhotos => translate('manage_photos');
  String get profileViews => translate('profile_views');
  String get seeWhoViewed => translate('see_who_viewed');
  String get noProfileViews => translate('no_profile_views');

  // Settings
  String get settings => translate('settings');
  String get preferences => translate('preferences');
  String get language => translate('language');
  String get theme => translate('theme');
  String get lightMode => translate('light_mode');
  String get darkMode => translate('dark_mode');
  String get systemDefault => translate('system_default');
  String get followsDeviceTheme => translate('follows_device_theme');
  String get notificationSound => translate('notification_sound');
  String get selectLanguage => translate('select_language');
  String get selectTheme => translate('select_theme');
  String get updateLocation => translate('update_location');
  String get locationUpdated => translate('location_updated');
  String get gettingLocation => translate('getting_location');
  String get locationUpdateConfirm => translate('location_update_confirm');
  String get failedGetLocation => translate('failed_get_location');
  String get errorUpdatingLocation => translate('error_updating_location');
  String get account => translate('account');
  String get version => translate('version');

  // Logout
  String get logout => translate('logout');
  String get logoutConfirm => translate('logout_confirm');
  String get yes => translate('yes');
  String get no => translate('no');

  // Navigation
  String get discover => translate('discover');
  String get matches => translate('matches');
  String get chat => translate('chat');
  String get nearbyUsers => translate('nearby_users');
  String get similarInterests => translate('similar_interests');
  String get distance => translate('distance');

  // Messages
  String get sendMessage => translate('send_message');
  String get startChat => translate('start_chat');
  String get noMessages => translate('no_messages');
  String get typeMessage => translate('type_message');

  // Actions
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get submit => translate('submit');
  String get close => translate('close');
  String get continueText => translate('continue');
  String get skip => translate('skip');
  String get done => translate('done');
  String get update => translate('update');
  String get delete => translate('delete');
  String get confirm => translate('confirm');

  // Report
  String get reportUser => translate('report_user');
  String get reportReason => translate('report_reason');
  String get harassment => translate('harassment');
  String get inappropriateContent => translate('inappropriate_content');
  String get spam => translate('spam');
  String get fakeProfile => translate('fake_profile');
  String get other => translate('other');
  String get reportSubmitted => translate('report_submitted');

  // Errors & Status
  String get error => translate('error');
  String get noUsersFound => translate('no_users_found');
  String get enableLocation => translate('enable_location');
  String get locationPermissionRequired => translate('location_permission_required');
  String get pleaseLogin => translate('please_login');
  String get profileNotFound => translate('profile_not_found');

  // Onboarding
  String get getStarted => translate('get_started');
  String get next => translate('next');
  String get onboardingWelcome => translate('onboarding_welcome');
  String get onboardingDiscover => translate('onboarding_discover');
  String get onboardingChat => translate('onboarding_chat');
  String get onboardingSafety => translate('onboarding_safety');
  String get onboardingReady => translate('onboarding_ready');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fr', 'ht'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
