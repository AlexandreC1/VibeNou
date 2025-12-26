import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/location_service.dart';
import '../../services/profile_view_service.dart';
import '../../services/online_presence_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/app_theme.dart';
import '../../utils/haptic_feedback_util.dart';
import '../../widgets/user_card.dart';
import '../../widgets/image_gallery_viewer.dart';
import '../../widgets/online_counter_widget.dart';
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
  final OnlinePresenceService _presenceService = OnlinePresenceService();
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _nearbyUsers = [];
  List<UserModel> _filteredNearbyUsers = [];
  List<Map<String, dynamic>> _similarUsers = [];
  List<Map<String, dynamic>> _filteredSimilarUsers = [];
  bool _isLoadingNearby = false;
  bool _isLoadingSimilar = false;
  UserModel? _currentUser;
  double _maxDistance = 50;
  int _minAge = 18;
  int _maxAge = 100;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_filterUsers);
    _loadCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when user logs in
    if (_currentUser == null) {
      _loadCurrentUser();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      // Apply ALL filters: age, search, gender preference, and distance
      _filteredNearbyUsers = _nearbyUsers.where((user) {
        // Age filter (use manual filter OR user's preferences)
        final passesAgeFilter = user.age >= _minAge && user.age <= _maxAge;

        // Search filter (if query is empty, passes by default)
        final passesSearchFilter = query.isEmpty ||
            user.name.toLowerCase().contains(query) ||
            user.interests.any((interest) => interest.toLowerCase().contains(query));

        // Gender preference filter
        final passesGenderFilter = _currentUser?.preferredGender == null ||
            user.gender == _currentUser?.preferredGender;

        return passesAgeFilter && passesSearchFilter && passesGenderFilter;
      }).toList();

      _filteredSimilarUsers = _similarUsers.where((item) {
        final user = item['user'] as UserModel;

        // Age filter
        final passesAgeFilter = user.age >= _minAge && user.age <= _maxAge;

        // Search filter
        final passesSearchFilter = query.isEmpty ||
            user.name.toLowerCase().contains(query) ||
            user.interests.any((interest) => interest.toLowerCase().contains(query));

        // Gender preference filter
        final passesGenderFilter = _currentUser?.preferredGender == null ||
            user.gender == _currentUser?.preferredGender;

        return passesAgeFilter && passesSearchFilter && passesGenderFilter;
      }).toList();
    });
  }

  void _applyFilters() {
    // Just call _filterUsers which now applies both filters
    _filterUsers();
  }

  Future<void> _loadCurrentUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    AppLogger.debug('Loading current user. Auth user: ${authService.currentUser?.uid}');
    if (authService.currentUser != null) {
      final user = await authService.getUserData(authService.currentUser!.uid);
      AppLogger.debug('Current user loaded: ${user?.name}, Location: ${user?.location}');

      // Update online presence
      await _presenceService.updatePresence(authService.currentUser!.uid);

      if (mounted) {
        setState(() {
          _currentUser = user;
          // Initialize filters from user's dating preferences
          if (user != null) {
            _minAge = user.preferredAgeMin;
            _maxAge = user.preferredAgeMax;
            if (user.preferredMaxDistance != null) {
              _maxDistance = user.preferredMaxDistance!.toDouble();
            }
          }
        });
        _loadNearbyUsers();
        _loadSimilarUsers();
      }
    } else {
      AppLogger.debug('No authenticated user found');
    }
  }

  Future<void> _loadNearbyUsers() async {
    AppLogger.debug('_loadNearbyUsers called. Current user: ${_currentUser?.name}, Location: ${_currentUser?.location}');

    if (_currentUser == null || _currentUser!.location == null) {
      AppLogger.debug('Requesting location permission...');
      // Request location permission
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        AppLogger.debug('Location permission denied');
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Location permission required'),
              backgroundColor: AppTheme.coral,
            ),
          );
        }
        return;
      }

      AppLogger.debug('Location obtained: ${position.latitude}, ${position.longitude}');

      // Update user location
      if (!mounted) return;
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        await _userService.updateUserLocation(
          authService.currentUser!.uid,
          position,
        );
        if (mounted) {
          setState(() {
            _currentUser = _currentUser?.copyWith(
              location: GeoPoint(position.latitude, position.longitude),
            );
          });
        }
        AppLogger.debug('User location updated in Firestore');
      }
    }

    if (_currentUser?.location == null) {
      AppLogger.debug('Still no location after update, returning');
      return;
    }

    setState(() => _isLoadingNearby = true);

    try {
      // Use user's preferred max distance, default to 10000km (global) if not set
      final radiusInKm = _currentUser!.preferredMaxDistance?.toDouble() ?? 10000.0;
      AppLogger.debug('Fetching nearby users within ${radiusInKm}km...');
      final users = await _userService.getNearbyUsers(
        currentUserId: _currentUser!.uid,
        userLocation: _currentUser!.location!,
        radiusInKm: radiusInKm,
      );

      AppLogger.debug('Found ${users.length} nearby users');
      setState(() {
        _nearbyUsers = users;
        _filteredNearbyUsers = users;
        _isLoadingNearby = false;
      });
      _applyFilters();
    } catch (e) {
      AppLogger.error('Error loading nearby users', e);
      setState(() => _isLoadingNearby = false);
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
        _filteredSimilarUsers = users;
        _isLoadingSimilar = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoadingSimilar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  localizations.discover,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3.0,
                        color: Color.fromARGB(100, 0, 0, 0),
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.sunsetGradient,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 40,
                        right: -30,
                        child: Icon(
                          Icons.favorite,
                          size: 150,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: -20,
                        child: Icon(
                          Icons.people,
                          size: 100,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primaryRose,
                    indicatorWeight: 3,
                    labelColor: AppTheme.primaryRose,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.location_on, size: 20),
                        text: localizations.nearbyUsers,
                      ),
                      Tab(
                        icon: const Icon(Icons.favorite, size: 20),
                        text: localizations.similarInterests,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Search and Filter Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name or interests...',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary.withValues(alpha: 0.6),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppTheme.primaryRose,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: AppTheme.textSecondary,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: AppTheme.primaryRose,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: _showFilterDialog,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        child: const Icon(
                          Icons.tune,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Online Counter - Social Proof Element
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: OnlineCounterWidget(),
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNearbyTab(localizations),
                  _buildSimilarTab(localizations),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: AppTheme.primaryRose),
                  SizedBox(width: 12),
                  Text(
                    'Filter Users',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_tabController.index == 0) ...[
                      const Text(
                        'Maximum Distance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _maxDistance,
                              min: 5,
                              max: 100,
                              divisions: 19,
                              activeColor: AppTheme.primaryRose,
                              label: '${_maxDistance.round()} km',
                              onChanged: (value) {
                                setState(() => _maxDistance = value);
                              },
                            ),
                          ),
                          Text(
                            '${_maxDistance.round()} km',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryRose,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    const Text(
                      'Age Range',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Min Age',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              Slider(
                                value: _minAge.toDouble(),
                                min: 18,
                                max: 100,
                                divisions: 82,
                                activeColor: AppTheme.royalPurple,
                                label: '$_minAge',
                                onChanged: (value) {
                                  setState(() {
                                    _minAge = value.round();
                                    if (_minAge > _maxAge) _maxAge = _minAge;
                                  });
                                },
                              ),
                              Center(
                                child: Text(
                                  '$_minAge years',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.royalPurple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Max Age',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              Slider(
                                value: _maxAge.toDouble(),
                                min: 18,
                                max: 100,
                                divisions: 82,
                                activeColor: AppTheme.royalPurple,
                                label: '$_maxAge',
                                onChanged: (value) {
                                  setState(() {
                                    _maxAge = value.round();
                                    if (_maxAge < _minAge) _minAge = _maxAge;
                                  });
                                },
                              ),
                              Center(
                                child: Text(
                                  '$_maxAge years',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.royalPurple,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _maxDistance = 50;
                          _minAge = 18;
                          _maxAge = 100;
                        });
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppTheme.primaryRose),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _applyFilters();
                        if (_tabController.index == 0) {
                          _loadNearbyUsers();
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyTab(AppLocalizations localizations) {
    if (_isLoadingNearby) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Finding people nearby...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredNearbyUsers.isEmpty && _nearbyUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: AppTheme.sunsetGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryRose.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_off_outlined,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                localizations.noUsersFound,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Try enabling location or expanding your search radius',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadNearbyUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredNearbyUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  gradient: AppTheme.purpleGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No matches found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Try adjusting your search or filters',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _maxDistance = 50;
                    _minAge = 18;
                    _maxAge = 100;
                  });
                  _applyFilters();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedbackUtil.mediumImpact();
        await _loadNearbyUsers();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _filteredNearbyUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredNearbyUsers[index];
          double? distance;
          if (_currentUser?.location != null && user.location != null) {
            distance = _userService.calculateSimilarity(
              [
                _currentUser!.location!.latitude.toString(),
                _currentUser!.location!.longitude.toString()
              ],
              [
                user.location!.latitude.toString(),
                user.location!.longitude.toString()
              ],
            );
          }

          // Animate each card with staggered delay
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(30 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: UserCard(
              user: user,
              subtitle: distance != null
                  ? '${distance.toStringAsFixed(1)} km away'
                  : user.city ?? '',
              onTap: () => _showUserProfile(user),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSimilarTab(AppLocalizations localizations) {
    if (_isLoadingSimilar) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AppTheme.purpleGradient,
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Finding similar interests...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredSimilarUsers.isEmpty && _similarUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: AppTheme.loveGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryRose.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                localizations.noUsersFound,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Add more interests in your profile to find similar users',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadSimilarUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredSimilarUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  gradient: AppTheme.purpleGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No matches found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Try adjusting your search or filters',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _minAge = 18;
                    _maxAge = 100;
                  });
                  _applyFilters();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedbackUtil.mediumImpact();
        await _loadSimilarUsers();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _filteredSimilarUsers.length,
        itemBuilder: (context, index) {
          final userWithSimilarity = _filteredSimilarUsers[index];
          final user = userWithSimilarity['user'] as UserModel;
          final similarity = userWithSimilarity['similarity'] as double;

          // Animate each card with staggered delay
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(30 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: UserCard(
              user: user,
              subtitle: '${similarity.toStringAsFixed(0)}% similar interests',
              onTap: () => _showUserProfile(user),
            ),
          );
        },
      ),
    );
  }

  void _showUserProfile(UserModel user) {
    // Record profile view
    if (_currentUser != null) {
      ProfileViewService().recordProfileView(
        viewerId: _currentUser!.uid,
        viewedUserId: user.uid,
      );
    }

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

class _UserProfileSheet extends StatelessWidget {
  final UserModel user;
  final UserModel? currentUser;

  const _UserProfileSheet({
    required this.user,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture with gradient border (tap to view full size)
                  Center(
                    child: GestureDetector(
                      onTap: () => _showImageGallery(context),
                      child: Hero(
                        tag: 'user_${user.uid}',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.sunsetGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryRose.withValues(alpha: 0.4),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 70,
                                  backgroundColor: AppTheme.primaryRose,
                                  backgroundImage: user.photoUrl != null
                                      ? CachedNetworkImageProvider(user.photoUrl!)
                                      : null,
                                  child: user.photoUrl == null
                                      ? Text(
                                          user.name[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 56,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                // Visual indicator that the image is tappable
                                if (user.photoUrl != null || user.photos.isNotEmpty)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.fullscreen,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Name and age with badge
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryRose.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            '${user.age}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Location with icon
                  if (user.city != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.lavender,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: AppTheme.deepPurple,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              user.city!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Bio section with card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.borderColor,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.loveGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              localizations.bio,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.bio,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Interests section with card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.borderColor,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: AppTheme.purpleGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              localizations.interests,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (user.interests.isEmpty)
                          Text(
                            'No interests added yet',
                            style: TextStyle(
                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: user.interests.map((interest) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.lavender,
                                      AppTheme.lavender.withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.royalPurple.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  interest,
                                  style: const TextStyle(
                                    color: AppTheme.deepPurple,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action buttons with improved design
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppTheme.sunsetGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryRose.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: currentUser == null
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          otherUser: user,
                                          currentUser: currentUser!,
                                        ),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.chat_bubble, size: 20),
                            label: Text(
                              localizations.startChat,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.coral,
                            width: 2,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showReportDialog(context, user);
                          },
                          icon: const Icon(
                            Icons.flag_outlined,
                            color: AppTheme.coral,
                            size: 24,
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

  /// Opens the image gallery viewer to display user's photos
  ///
  /// Collects all available photos (main photo + additional photos)
  /// and opens them in a fullscreen gallery with swipe navigation
  void _showImageGallery(BuildContext context) {
    // Collect all available photos
    List<String> allPhotos = [];

    // Add main photo if available
    if (user.photoUrl != null) {
      allPhotos.add(user.photoUrl!);
    }

    // Add additional photos from gallery
    allPhotos.addAll(user.photos);

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
          userName: user.name,
        ),
      ),
    );
  }
}
