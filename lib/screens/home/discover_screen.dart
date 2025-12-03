import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/location_service.dart';
import '../../services/profile_view_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/user_card.dart';
import '../chat/chat_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  final LocationService _locationService = LocationService();

  List<UserModel> _nearbyUsers = [];
  List<Map<String, dynamic>> _similarUsers = [];
  bool _isLoadingNearby = false;
  bool _isLoadingSimilar = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      final user = await authService.getUserData(authService.currentUser!.uid);
      if (user == null) {
        print('ERROR: User data not found in Firestore for ${authService.currentUser!.uid}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User profile not found. Please try logging in again.'),
              backgroundColor: AppTheme.coral,
            ),
          );
        }
        return;
      }
      setState(() {
        _currentUser = user;
      });
      print('Current user loaded: ${user.name}, Location: ${user.location != null ? "Set" : "Not set"}');
      _loadNearbyUsers();
      _loadSimilarUsers();
    } else {
      print('ERROR: No authenticated user');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to continue'),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
    }
  }

  Future<void> _loadNearbyUsers() async {
    print('Loading nearby users...');

    if (_currentUser == null) {
      print('ERROR: Current user is null');
      setState(() => _isLoadingNearby = false);
      return;
    }

    if (_currentUser!.location == null) {
      print('User location not set, requesting permission...');
      // Request location permission
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        print('ERROR: Failed to get location permission');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission required to find nearby users'),
              backgroundColor: AppTheme.coral,
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isLoadingNearby = false);
        return;
      }

      print('Got location: ${position.latitude}, ${position.longitude}');

      // Update user location
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        try {
          // Get city and country
          final address = await _locationService.getAddressFromCoordinates(
            position.latitude,
            position.longitude,
          );

          await _userService.updateUserLocation(
            authService.currentUser!.uid,
            position,
            city: address?['city'],
            country: address?['country'],
          );

          _currentUser = _currentUser?.copyWith(
            location: GeoPoint(position.latitude, position.longitude),
            city: address?['city'],
            country: address?['country'],
          );

          print('Location updated in Firestore');
        } catch (e) {
          print('ERROR updating location: $e');
        }
      }
    }

    if (_currentUser?.location == null) {
      print('ERROR: Still no location after update attempt');
      return;
    }

    setState(() => _isLoadingNearby = true);

    try {
      print('Searching for users within 50km of ${_currentUser!.location!.latitude}, ${_currentUser!.location!.longitude}');

      final users = await _userService.getNearbyUsers(
        currentUserId: _currentUser!.uid,
        userLocation: _currentUser!.location!,
        radiusInKm: 50,
      );

      print('Found ${users.length} nearby users');

      setState(() {
        _nearbyUsers = users;
        _isLoadingNearby = false;
      });

      if (users.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No users found nearby. Try creating more test accounts!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('ERROR loading nearby users: $e');
      setState(() => _isLoadingNearby = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading nearby users: $e'),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
    }
  }

  Future<void> _loadSimilarUsers() async {
    if (_currentUser == null) return;

    setState(() => _isLoadingSimilar = true);

    try {
      final users = await _userService.getUsersBySimilarity(
        currentUserId: _currentUser!.uid,
        currentUserInterests: _currentUser!.interests,
      );

      setState(() {
        _similarUsers = users;
        _isLoadingSimilar = false;
      });
    } catch (e) {
      setState(() => _isLoadingSimilar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.discover),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: localizations.nearbyUsers),
            Tab(text: localizations.similarInterests),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNearbyTab(localizations),
          _buildSimilarTab(localizations),
        ],
      ),
    );
  }

  Widget _buildNearbyTab(AppLocalizations localizations) {
    if (_isLoadingNearby) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_nearbyUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.noUsersFound,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try enabling location or expanding your search',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadNearbyUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNearbyUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _nearbyUsers.length,
        itemBuilder: (context, index) {
          final user = _nearbyUsers[index];
          double? distance;
          if (_currentUser?.location != null && user.location != null) {
            distance = _locationService.getDistanceBetween(
              _currentUser!.location!.latitude,
              _currentUser!.location!.longitude,
              user.location!.latitude,
              user.location!.longitude,
            );
          }

          return UserCard(
            user: user,
            subtitle: distance != null
                ? '${distance.toStringAsFixed(1)} km away'
                : user.city ?? '',
            onTap: () => _showUserProfile(user),
          );
        },
      ),
    );
  }

  Widget _buildSimilarTab(AppLocalizations localizations) {
    if (_isLoadingSimilar) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_similarUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.noUsersFound,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSimilarUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSimilarUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _similarUsers.length,
        itemBuilder: (context, index) {
          final userWithSimilarity = _similarUsers[index];
          final user = userWithSimilarity['user'] as UserModel;
          final similarity = userWithSimilarity['similarity'] as double;

          return UserCard(
            user: user,
            subtitle: '${similarity.toStringAsFixed(0)}% similar interests',
            onTap: () => _showUserProfile(user),
          );
        },
      ),
    );
  }

  void _showUserProfile(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserProfileSheet(
        user: user,
        currentUser: _currentUser,
      ),
    );
  }
}

class _UserProfileSheet extends StatefulWidget {
  final UserModel user;
  final UserModel? currentUser;

  const _UserProfileSheet({
    required this.user,
    required this.currentUser,
  });

  @override
  State<_UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends State<_UserProfileSheet> {
  final ProfileViewService _profileViewService = ProfileViewService();

  @override
  void initState() {
    super.initState();
    _recordProfileView();
  }

  Future<void> _recordProfileView() async {
    if (widget.currentUser != null) {
      await _profileViewService.recordProfileView(
        viewerId: widget.currentUser!.uid,
        viewedUserId: widget.user.uid,
      );
      print('Profile view recorded: ${widget.currentUser!.name} viewed ${widget.user.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.primaryBlue,
                      child: Text(
                        widget.user.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Name and age
                  Center(
                    child: Text(
                      '${widget.user.name}, ${widget.user.age}',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Location
                  if (widget.user.city != null)
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            widget.user.city!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Bio
                  Text(
                    localizations.bio,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.user.bio,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),

                  const SizedBox(height: 24),

                  // Interests
                  Text(
                    localizations.interests,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.user.interests.map((interest) {
                      return Chip(
                        label: Text(interest),
                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                        labelStyle: const TextStyle(color: AppTheme.primaryBlue),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // Report user
                            _showReportDialog(context, widget.user);
                          },
                          icon: const Icon(Icons.flag_outlined),
                          label: Text(localizations.reportUser),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.coral,
                            side: const BorderSide(color: AppTheme.coral),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // Start chat
                            if (widget.currentUser != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    otherUser: widget.user,
                                    currentUser: widget.currentUser!,
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.chat_bubble),
                          label: Text(localizations.startChat),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, UserModel user) {
    // This will be implemented in the report dialog widget
  }
}
