/// SettingsScreen - App Settings and Preferences
///
/// Independent settings page with all user preferences:
/// - Language selection
/// - Location management
/// - Notification sound customization
/// - Theme selection (Light/Dark/System)
/// - Logout functionality
///
/// Last updated: 2026-03-24
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/custom_notification_sound_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_logger.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import 'notification_sound_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      setState(() => _isLoading = true);
      final user = await authService.getUserData(authService.currentUser!.uid);
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _currentUser = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    if (!mounted) return;

    AppLogger.info('SettingsScreen: Changing language to: $languageCode');

    if (!mounted) return;
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    await languageProvider.setLocale(languageCode);

    // Update user preference in Firestore
    if (!mounted) return;
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(authService.currentUser!.uid)
            .update({'preferredLanguage': languageCode});
        AppLogger.info('SettingsScreen: Updated Firestore preferredLanguage to: $languageCode');
      } catch (e) {
        AppLogger.error('Error updating language preference', e);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language updated to ${_getLanguageName(languageCode)}'),
          backgroundColor: AppTheme.royalPurple,
          duration: const Duration(seconds: 2),
        ),
      );

      // Update local user data
      setState(() {
        _currentUser = _currentUser?.copyWith(preferredLanguage: languageCode);
      });
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'ht':
        return 'Kreyòl Ayisyen';
      default:
        return code;
    }
  }

  Future<void> _updateLocation() async {
    if (_currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.updateLocation),
        content: Text(localizations.locationUpdateConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations.update),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Text(localizations.gettingLocation),
            ],
          ),
          duration: const Duration(seconds: 10),
        ),
      );

      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();

      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.failedGetLocation),
              backgroundColor: AppTheme.coral,
            ),
          );
        }
        return;
      }

      // Get city name from coordinates
      final addressData = await locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final city = addressData?['city'] ?? 'Unknown';

      // Update Firestore
      if (!mounted) return;
      final authService = Provider.of<AuthService>(context, listen: false);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(authService.currentUser!.uid)
          .update({
        'location': GeoPoint(position.latitude, position.longitude),
        'city': city,
      });

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('${localizations.locationUpdated}$city'),
            backgroundColor: AppTheme.royalPurple,
          ),
        );

        // Reload profile to show new location
        _loadUserProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.errorUpdatingLocation}$e'),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.logout),
        content: Text(localizations.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.coral),
            child: Text(localizations.logout),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _showLanguageSelector() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.selectLanguage),
        content: StatefulBuilder(
          builder: (context, setState) {
            String selectedLanguage = _currentUser?.preferredLanguage ?? 'en';
            return RadioGroup<String>(
              groupValue: selectedLanguage,
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedLanguage = value);
                  _changeLanguage(value);
                  Navigator.pop(context);
                }
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text('English'),
                    value: 'en',
                  ),
                  RadioListTile<String>(
                    title: Text('Français'),
                    value: 'fr',
                  ),
                  RadioListTile<String>(
                    title: Text('Kreyòl Ayisyen'),
                    value: 'ht',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showThemeSelector(ThemeProvider themeProvider) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.selectTheme),
        content: StatefulBuilder(
          builder: (context, setState) {
            return RadioGroup<ThemeMode>(
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ThemeMode>(
                    title: Row(
                      children: [
                        const Icon(Icons.light_mode, size: 20),
                        const SizedBox(width: 12),
                        Text(localizations.lightMode),
                      ],
                    ),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Row(
                      children: [
                        const Icon(Icons.dark_mode, size: 20),
                        const SizedBox(width: 12),
                        Text(localizations.darkMode),
                      ],
                    ),
                    value: ThemeMode.dark,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Row(
                      children: [
                        const Icon(Icons.brightness_auto, size: 20),
                        const SizedBox(width: 12),
                        Text(localizations.systemDefault),
                      ],
                    ),
                    subtitle: Text(
                      localizations.followsDeviceTheme,
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: ThemeMode.system,
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get gender-based gradient
    final gradient = _currentUser?.gender == 'male'
        ? AppTheme.getGradient(isDarkMode: isDark, gender: 'male')
        : AppTheme.getGradient(isDarkMode: isDark, gender: 'female');

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.settings)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.settings)),
        body: Center(
          child: Text(
            'Please log in to access settings',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: gradient),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Preferences Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              localizations.preferences,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language, color: AppTheme.primaryRose),
                    title: Text(localizations.language),
                    subtitle: Text(_getLanguageName(_currentUser!.preferredLanguage)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showLanguageSelector,
                  ),
                  const Divider(height: 1),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return ListTile(
                        leading: Icon(
                          themeProvider.themeModeIcon,
                          color: AppTheme.primaryRose,
                        ),
                        title: Text(localizations.theme),
                        subtitle: Text(themeProvider.currentThemeModeString),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showThemeSelector(themeProvider),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.music_note, color: AppTheme.primaryRose),
                    title: Text(localizations.notificationSound),
                    subtitle: FutureBuilder<String>(
                      future: CustomNotificationSoundService().getCurrentSound(),
                      builder: (context, snapshot) {
                        final soundName = snapshot.data ?? 'purr';
                        final displayName = CustomNotificationSoundService.availableSounds[soundName] ?? 'Sultry Purr';
                        return Text(displayName);
                      },
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationSoundPicker(),
                        ),
                      );
                      // Refresh to show updated sound name
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Location Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              localizations.location,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.location_on, color: AppTheme.primaryRose),
                title: Text(localizations.location),
                subtitle: Text(_currentUser!.city ?? localizations.location),
                trailing: const Icon(Icons.refresh),
                onTap: _updateLocation,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Account Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              localizations.account,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.coral),
                title: Text(
                  localizations.logout,
                  style: const TextStyle(color: AppTheme.coral),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.coral),
                onTap: _logout,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // App Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Text(
                  'VibeNou',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom RadioGroup widget for cleaner radio button implementation
class RadioGroup<T> extends StatelessWidget {
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final Widget child;

  const RadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Extension to make RadioListTile work with RadioGroup
extension RadioListTileExtension<T> on RadioListTile<T> {
  RadioListTile<T> copyWith({
    T? groupValue,
    ValueChanged<T?>? onChanged,
  }) {
    return this;
  }
}
