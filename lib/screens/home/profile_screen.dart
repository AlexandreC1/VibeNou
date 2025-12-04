import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/profile_view_service.dart';
import '../../utils/app_theme.dart';
import '../profile/profile_visitors_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    print('Loading user profile...');
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser == null) {
      print('ERROR: No authenticated user in profile screen');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to view your profile'),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
      return;
    }

    print('Fetching user data for UID: ${authService.currentUser!.uid}');

    try {
      final user = await authService.getUserData(authService.currentUser!.uid);

      if (user == null) {
        print('ERROR: User data not found in Firestore');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile not found. Please try logging in again.'),
              backgroundColor: AppTheme.coral,
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      print('Profile loaded successfully: ${user.name}');
      print('Location: ${user.location != null ? "Set (${user.city})" : "Not set"}');
      print('Interests: ${user.interests.length} interests');

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      print('ERROR loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.coral,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        print('Logging out user...');
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();
        print('Logout successful, navigating to login screen...');

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to login screen and clear all previous routes
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        print('Logout error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: ${e.toString()}'),
              backgroundColor: AppTheme.coral,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    if (mounted) {
      // Restart app or update locale
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Language updated. Please restart the app.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.profile)),
        body: const Center(
          child: Text('Please log in to view your profile'),
        ),
      );
    }

    final profileViewService = ProfileViewService();

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.profile),
        actions: [
          // Profile Visitors Button with Badge
          StreamBuilder<int>(
            stream: profileViewService.getUnreadViewsCount(
              Provider.of<AuthService>(context, listen: false).currentUser!.uid,
            ),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileVisitorsScreen(),
                        ),
                      );
                    },
                    tooltip: 'Profile Visitors',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.coral,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit profile screen
              _showEditProfile();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: Text(
                      _currentUser!.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 48,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentUser!.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentUser!.age} years old',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  if (_currentUser!.city != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _currentUser!.city!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bio Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.bio,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentUser!.bio,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Interests Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.interests,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _currentUser!.interests.map((interest) {
                      return Chip(
                        label: Text(interest),
                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Settings
            _buildSettingsSection(localizations),

            const SizedBox(height: 24),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: Text(localizations.logout),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.coral,
                    side: const BorderSide(color: AppTheme.coral),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.settings,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(localizations.language),
                  subtitle: Text(_getLanguageName(_currentUser!.preferredLanguage)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showLanguageSelector,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(localizations.location),
                  subtitle: Text(_currentUser!.city ?? 'Not set'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Update location
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        return 'English';
    }
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: _currentUser!.preferredLanguage,
              onChanged: (value) {
                if (value != null) {
                  _changeLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Français'),
              value: 'fr',
              groupValue: _currentUser!.preferredLanguage,
              onChanged: (value) {
                if (value != null) {
                  _changeLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Kreyòl Ayisyen'),
              value: 'ht',
              groupValue: _currentUser!.preferredLanguage,
              onChanged: (value) {
                if (value != null) {
                  _changeLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfile() {
    // This would open an edit profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile feature coming soon!')),
    );
  }
}
