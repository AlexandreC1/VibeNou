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
      'app_name': 'VibeNou',
      'welcome': 'Welcome to VibeNou',
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'name': 'Name',
      'age': 'Age',
      'bio': 'Bio',
      'interests': 'Interests',
      'location': 'Location',
      'discover': 'Discover',
      'matches': 'Matches',
      'chat': 'Chat',
      'profile': 'Profile',
      'settings': 'Settings',
      'logout': 'Logout',
      'send_message': 'Send a message...',
      'report_user': 'Report User',
      'report_reason': 'Report Reason',
      'submit': 'Submit',
      'cancel': 'Cancel',
      'nearby_users': 'Nearby Users',
      'similar_interests': 'Similar Interests',
      'distance': 'Distance',
      'start_chat': 'Start Chat',
      'no_users_found': 'No users found nearby',
      'enable_location': 'Enable Location',
      'location_permission_required': 'Location permission is required',
      'save': 'Save',
      'edit_profile': 'Edit Profile',
      'language': 'Language',
      'harassment': 'Harassment',
      'inappropriate_content': 'Inappropriate Content',
      'spam': 'Spam',
      'fake_profile': 'Fake Profile',
      'other': 'Other',
      'report_submitted': 'Report submitted successfully',
      'error': 'An error occurred',
    },
    'fr': {
      'app_name': 'VibeNou',
      'welcome': 'Bienvenue à VibeNou',
      'sign_in': 'Se Connecter',
      'sign_up': 'S\'inscrire',
      'email': 'E-mail',
      'password': 'Mot de passe',
      'name': 'Nom',
      'age': 'Âge',
      'bio': 'Biographie',
      'interests': 'Intérêts',
      'location': 'Localisation',
      'discover': 'Découvrir',
      'matches': 'Correspondances',
      'chat': 'Chat',
      'profile': 'Profil',
      'settings': 'Paramètres',
      'logout': 'Déconnexion',
      'send_message': 'Envoyer un message...',
      'report_user': 'Signaler l\'utilisateur',
      'report_reason': 'Raison du signalement',
      'submit': 'Soumettre',
      'cancel': 'Annuler',
      'nearby_users': 'Utilisateurs à proximité',
      'similar_interests': 'Intérêts similaires',
      'distance': 'Distance',
      'start_chat': 'Commencer le chat',
      'no_users_found': 'Aucun utilisateur trouvé à proximité',
      'enable_location': 'Activer la localisation',
      'location_permission_required': 'L\'autorisation de localisation est requise',
      'save': 'Enregistrer',
      'edit_profile': 'Modifier le profil',
      'language': 'Langue',
      'harassment': 'Harcèlement',
      'inappropriate_content': 'Contenu inapproprié',
      'spam': 'Spam',
      'fake_profile': 'Faux profil',
      'other': 'Autre',
      'report_submitted': 'Signalement soumis avec succès',
      'error': 'Une erreur s\'est produite',
    },
    'ht': {
      'app_name': 'VibeNou',
      'welcome': 'Byenveni nan VibeNou',
      'sign_in': 'Konekte',
      'sign_up': 'Enskri',
      'email': 'Imèl',
      'password': 'Modpas',
      'name': 'Non',
      'age': 'Laj',
      'bio': 'Byografi',
      'interests': 'Enterè',
      'location': 'Kote w ye',
      'discover': 'Dekouvri',
      'matches': 'Koneksyon',
      'chat': 'Diskite',
      'profile': 'Pwofil',
      'settings': 'Paramèt',
      'logout': 'Dekonekte',
      'send_message': 'Voye yon mesaj...',
      'report_user': 'Rapòte Itilizatè',
      'report_reason': 'Rezon Rapò',
      'submit': 'Soumèt',
      'cancel': 'Anile',
      'nearby_users': 'Itilizatè tou pre',
      'similar_interests': 'Enterè similè',
      'distance': 'Distans',
      'start_chat': 'Kòmanse diskite',
      'no_users_found': 'Pa gen itilizatè tou pre',
      'enable_location': 'Aktive lokalizasyon',
      'location_permission_required': 'Pèmisyon lokalizasyon obligatwa',
      'save': 'Anrejistre',
      'edit_profile': 'Modifye pwofil',
      'language': 'Lang',
      'harassment': 'Atak',
      'inappropriate_content': 'Kontni pa apwopriye',
      'spam': 'Spam',
      'fake_profile': 'Fo pwofil',
      'other': 'Lòt',
      'report_submitted': 'Rapò soumèt avèk siksè',
      'error': 'Yon erè rive',
    },
  };

  String translate(String key) {
    // Debug: Print current locale for troubleshooting
    // AppLogger.debug('AppLocalizations: locale=${locale.languageCode}, key=$key');
    final value = _localizedValues[locale.languageCode]?[key];
    if (value == null) {
      AppLogger.warning('Missing translation for key "$key" in locale "${locale.languageCode}"');
    }
    return value ?? key;
  }

  String get appName => translate('app_name');
  String get welcome => translate('welcome');
  String get signIn => translate('sign_in');
  String get signUp => translate('sign_up');
  String get email => translate('email');
  String get password => translate('password');
  String get name => translate('name');
  String get age => translate('age');
  String get bio => translate('bio');
  String get interests => translate('interests');
  String get location => translate('location');
  String get discover => translate('discover');
  String get matches => translate('matches');
  String get chat => translate('chat');
  String get profile => translate('profile');
  String get settings => translate('settings');
  String get logout => translate('logout');
  String get sendMessage => translate('send_message');
  String get reportUser => translate('report_user');
  String get reportReason => translate('report_reason');
  String get submit => translate('submit');
  String get cancel => translate('cancel');
  String get nearbyUsers => translate('nearby_users');
  String get similarInterests => translate('similar_interests');
  String get distance => translate('distance');
  String get startChat => translate('start_chat');
  String get noUsersFound => translate('no_users_found');
  String get enableLocation => translate('enable_location');
  String get locationPermissionRequired => translate('location_permission_required');
  String get save => translate('save');
  String get editProfile => translate('edit_profile');
  String get language => translate('language');
  String get harassment => translate('harassment');
  String get inappropriateContent => translate('inappropriate_content');
  String get spam => translate('spam');
  String get fakeProfile => translate('fake_profile');
  String get other => translate('other');
  String get reportSubmitted => translate('report_submitted');
  String get error => translate('error');
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
