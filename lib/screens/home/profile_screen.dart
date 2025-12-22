/// ProfileScreen - User Profile Display and Management
///
/// This screen displays the current user's profile information including:
/// - Profile picture and basic info (name, age, location)
/// - Bio and interests
/// - Photo gallery management
/// - Profile view tracking
/// - Settings (language, location)
///
/// FEATURES:
/// - Gender-based theming (Blue for male, Pink for female)
/// - Floating action button for easy profile editing
/// - Prominent photo management card for easy photo uploads
/// - Real-time profile view notifications
/// - Multi-language support
///
/// FUTURE IMPROVEMENTS:
/// - Add profile completion percentage
/// - Add social media links
/// - Add profile verification badge
///
/// Last updated: 2025-12-22
/// Author: VibeNou Team

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../models/profile_view_model.dart';
import '../../services/auth_service.dart';
import '../../services/profile_view_service.dart';
import '../../services/location_service.dart';
import '../../utils/app_theme.dart';
import '../../providers/language_provider.dart';
import '../../widgets/image_gallery_viewer.dart';
import '../profile/edit_profile_screen.dart';

/// ProfileScreen Widget
///
/// Displays the authenticated user's profile with gender-based theming.
/// This is a stateful widget that loads user data from Firestore and
/// displays it in a scrollable, visually appealing layout.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// State class for ProfileScreen
///
/// Manages:
/// - User data loading and caching
/// - Profile view count tracking
/// - UI state (loading, error handling)
/// - Navigation to edit profile and image gallery
class _ProfileScreenState extends State<ProfileScreen> {
  // ========== STATE VARIABLES ==========

  /// Current user's complete profile data from Firestore
  /// Null during initial load or if user is not authenticated
  UserModel? _currentUser;

  /// Loading state for profile data fetch
  /// True during initial load and refresh operations
  bool _isLoading = true;

  /// Count of unread profile views
  /// Updated in real-time via Firestore stream
  int _unreadViewCount = 0;

  /// Service for tracking who viewed the user's profile
  final ProfileViewService _profileViewService = ProfileViewService();

  // ========== LIFECYCLE METHODS ==========

  @override
  void initState() {
    super.initState();
    // Load profile data and view count on first render
    _loadUserProfile();
    _loadUnreadViewCount();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload profile when dependencies change (e.g., after login, language change)
    // This ensures the profile stays in sync with auth state changes
    _loadUserProfile();
    _loadUnreadViewCount();
  }

  // ========== DATA LOADING METHODS ==========

  /// Loads the current user's profile data from Firestore
  ///
  /// This method:
  /// 1. Gets the authenticated user from AuthService
  /// 2. Fetches full profile data from Firestore
  /// 3. Updates UI state with loaded data
  ///
  /// Called on:
  /// - Initial screen load
  /// - Dependency changes (login/logout)
  /// - Manual refresh
  ///
  /// NOTE: Uses `mounted` check to prevent setState on disposed widgets
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

  Future<void> _loadUnreadViewCount() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      final count = await _profileViewService.getUnreadViewCount(
        authService.currentUser!.uid,
      );
      if (mounted) {
        setState(() {
          _unreadViewCount = count;
        });
      }
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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    if (!mounted) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    await languageProvider.setLocale(languageCode);

    // Update user preference in Firestore
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(authService.currentUser!.uid)
            .update({'preferredLanguage': languageCode});
      } catch (e) {
        print('Error updating language preference: $e');
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
        title: const Text('Update Location'),
        content: const Text(
          'This will update your location using your current GPS position. '
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Getting your location...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();

      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to get location. Please enable location services.'),
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
            content: Text('Location updated to: $city'),
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
            content: Text('Error updating location: $e'),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
    }
  }

  void _showImageGallery() {
    if (_currentUser == null) return;

    // Collect all available photos
    List<String> allPhotos = [];

    // Add main photo if available
    if (_currentUser!.photoUrl != null) {
      allPhotos.add(_currentUser!.photoUrl!);
    }

    // Add additional photos from gallery
    allPhotos.addAll(_currentUser!.photos);

    // Remove duplicates (in case photoUrl is also in photos list)
    allPhotos = allPhotos.toSet().toList();

    if (allPhotos.isEmpty) {
      // No photos available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No photos available'),
          backgroundColor: AppTheme.coral,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGalleryViewer(
          imageUrls: allPhotos,
          initialIndex: 0,
          userName: _currentUser!.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.profile)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      // User is authenticated but Firestore document is missing
      // Show logout button to allow re-authentication which triggers self-healing
      final authService = Provider.of<AuthService>(context, listen: false);
      final isAuthenticated = authService.currentUser != null;

      return Scaffold(
        appBar: AppBar(title: Text(localizations.profile)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isAuthenticated
                    ? 'Profile data not found'
                    : 'Please log in to view your profile',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                if (isAuthenticated) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Please logout and sign in again to fix this issue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRose,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Get gender-based gradient
    final gradient = _currentUser!.gender == 'male'
        ? AppTheme.primaryBlueGradient
        : AppTheme.primaryGradient;
    final accentColor = _currentUser!.gender == 'male'
        ? AppTheme.primaryBlue
        : AppTheme.primaryRose;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.profile),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: gradient),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showEditProfile,
        backgroundColor: accentColor,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: gradient,
                ),
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showImageGallery,
                      child: Hero(
                        tag: 'profile_avatar_${_currentUser!.uid}',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            backgroundImage: _currentUser!.photoUrl != null
                                ? CachedNetworkImageProvider(_currentUser!.photoUrl!)
                                : null,
                            child: _currentUser!.photoUrl == null
                                ? Text(
                                    _currentUser!.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 48,
                                      color: AppTheme.primaryRose,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
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
                        backgroundColor: AppTheme.softPink,
                        labelStyle: const TextStyle(
                          color: AppTheme.deepPink,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Photo Gallery Management Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 4,
                child: InkWell(
                  onTap: () {
                    _showEditProfile();
                    // TODO: Navigate directly to photos tab if we keep tabs
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _currentUser!.gender == 'male'
                            ? [AppTheme.primaryBlue.withValues(alpha: 0.1), AppTheme.teal.withValues(alpha: 0.1)]
                            : [AppTheme.softPink, AppTheme.lavender],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Manage Photos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add up to 6 photos (${_currentUser!.photos.length + (_currentUser!.photoUrl != null ? 1 : 0)}/6)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: accentColor,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Profile Views
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                child: InkWell(
                  onTap: _showProfileViews,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Profile Views',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'See who viewed your profile',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_unreadViewCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.coral,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_unreadViewCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

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
                    foregroundColor: AppTheme.primaryRose,
                    side: const BorderSide(color: AppTheme.primaryRose),
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
                  onTap: _updateLocation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Future<void> _showEditProfile() async {
    if (_currentUser == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentUser: _currentUser!,
        ),
      ),
    );

    // Reload profile if changes were made
    if (result == true) {
      _loadUserProfile();
    }
  }

  void _showProfileViews() {
    if (_currentUser == null) return;

    // Mark views as read
    _profileViewService.markViewsAsRead(_currentUser!.uid);
    setState(() => _unreadViewCount = 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfileViewsSheet(
        currentUserId: _currentUser!.uid,
      ),
    );
  }
}

// Profile Views Sheet Widget
class _ProfileViewsSheet extends StatelessWidget {
  final String currentUserId;

  const _ProfileViewsSheet({
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final ProfileViewService profileViewService = ProfileViewService();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.sunsetGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Profile Views',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<ProfileView>>(
              stream: profileViewService.getProfileViews(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final views = snapshot.data ?? [];

                if (views.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.visibility_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No profile views yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'When people view your profile,\nthey\'ll appear here',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: views.length,
                  itemBuilder: (context, index) {
                    final view = views[index];
                    return _ProfileViewTile(view: view);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Profile View Tile Widget
class _ProfileViewTile extends StatelessWidget {
  final ProfileView view;

  const _ProfileViewTile({
    required this.view,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return FutureBuilder<UserModel?>(
      future: authService.getUserData(view.viewerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final viewer = snapshot.data!;
        final timeAgo = _getTimeAgo(view.viewedAt);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.softPink,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryRose,
              backgroundImage: viewer.photoUrl != null
                  ? CachedNetworkImageProvider(viewer.photoUrl!)
                  : null,
              child: viewer.photoUrl == null
                  ? Text(
                      viewer.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          title: Text(
            viewer.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            timeAgo,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppTheme.textSecondary,
          ),
          onTap: () {
            // Could navigate to viewer's profile
          },
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 7) {
      return '${difference.inDays ~/ 7} week${difference.inDays ~/ 7 > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
