import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_image_service.dart';
import '../../services/location_service.dart';
import '../../utils/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel currentUser;

  const EditProfileScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final SupabaseImageService _imageUploadService = SupabaseImageService();
  final LocationService _locationService = LocationService();

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _ageController;
  late TabController _tabController;

  List<String> _selectedInterests = [];
  final List<String> _availableInterests = [
    'Music',
    'Dance',
    'Food',
    'Art',
    'Sports',
    'Travel',
    'Photography',
    'Reading',
    'Movies',
    'Fitness',
    'Technology',
    'Fashion',
    'Cooking',
    'Gaming',
    'Nature',
    'Hiking',
    'Yoga',
    'Meditation',
  ];

  String? _photoUrl;
  List<String> _photos = [];
  final List<XFile> _newPhotoFiles = [];
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _locationSharingEnabled = true;
  final int _maxPhotos = 6;

  // Dating preferences
  int _preferredAgeMin = 18;
  int _preferredAgeMax = 100;
  String? _preferredGender; // 'male', 'female', 'other', or null for any
  String? _preferredGenderOther; // Custom text when 'other' is selected
  int? _preferredMaxDistance; // in km
  String? _selectedGender; // User's own gender

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _nameController = TextEditingController(text: widget.currentUser.name);
    _bioController = TextEditingController(text: widget.currentUser.bio);
    _ageController =
        TextEditingController(text: widget.currentUser.age.toString());
    _selectedInterests = List.from(widget.currentUser.interests);
    _photoUrl = widget.currentUser.photoUrl;
    _photos = List.from(widget.currentUser.photos);
    _locationSharingEnabled = widget.currentUser.locationSharingEnabled;

    // Initialize dating preferences
    _preferredAgeMin = widget.currentUser.preferredAgeMin;
    _preferredAgeMax = widget.currentUser.preferredAgeMax;
    _preferredGender = widget.currentUser.preferredGender;
    _preferredMaxDistance = widget.currentUser.preferredMaxDistance;
    _selectedGender = widget.currentUser.gender;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (_photos.length + _newPhotoFiles.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum of $_maxPhotos photos allowed'),
          backgroundColor: AppTheme.coral,
        ),
      );
      return;
    }

    try {
      setState(() => _isUploadingImage = true);

      final image = await _imageUploadService.pickImageFromGallery();
      if (image != null && mounted) {
        setState(() {
          _newPhotoFiles.add(image);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo added! Save profile to upload.'),
            backgroundColor: AppTheme.royalPurple,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add photo: $e'),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _pickProfilePicture() async {
    try {
      setState(() => _isUploadingImage = true);

      final image = await _imageUploadService.pickImageFromGallery();
      if (image != null) {
        // Upload immediately for profile picture
        final photoUrl = await _imageUploadService.uploadProfilePicture(
          image,
          widget.currentUser.uid,
        );

        if (photoUrl != null && mounted) {
          setState(() {
            _photoUrl = photoUrl;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated!'),
              backgroundColor: AppTheme.royalPurple,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload profile picture: $e'),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _removePhoto(int index, {bool isNew = false}) {
    setState(() {
      if (isNew) {
        _newPhotoFiles.removeAt(index);
      } else {
        _photos.removeAt(index);
      }
    });
  }

  Future<void> _updateLocation() async {
    setState(() => _isLoading = true);

    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location updated: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
            ),
            backgroundColor: AppTheme.royalPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showOtherGenderDialog() {
    final controller = TextEditingController(text: _preferredGenderOther ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What are you looking for?'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., Non-binary, Genderfluid, etc.',
            border: OutlineInputBorder(),
          ),
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _preferredGenderOther = controller.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0); // Go to basic info tab if validation fails
      return;
    }

    if (_selectedInterests.isEmpty) {
      _tabController.animateTo(1); // Go to interests tab
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one interest'),
          backgroundColor: AppTheme.coral,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Upload new photos
      List<String> uploadedPhotoUrls = List.from(_photos);

      for (var file in _newPhotoFiles) {
        final url = await _imageUploadService.uploadProfilePicture(
          file,
          '${widget.currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (url != null) {
          uploadedPhotoUrls.add(url);
        }
      }

      final updatedUser = widget.currentUser.copyWith(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        age: int.parse(_ageController.text),
        interests: _selectedInterests,
        photoUrl: _photoUrl,
        photos: uploadedPhotoUrls,
        locationSharingEnabled: _locationSharingEnabled,
        gender: _selectedGender,
        preferredAgeMin: _preferredAgeMin,
        preferredAgeMax: _preferredAgeMax,
        preferredGender: _preferredGender,
        preferredMaxDistance: _preferredMaxDistance,
      );

      await authService.updateUserProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.royalPurple,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Gender-based theming
    final gradient = widget.currentUser.gender == 'male'
        ? AppTheme.primaryBlueGradient
        : AppTheme.primaryGradient;
    final accentColor = widget.currentUser.gender == 'male'
        ? AppTheme.primaryBlue
        : AppTheme.primaryRose;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: gradient),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Basic'),
            Tab(icon: Icon(Icons.favorite), text: 'Interests'),
            Tab(icon: Icon(Icons.photo_library), text: 'Photos'),
            Tab(icon: Icon(Icons.tune), text: 'Preferences'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicInfoTab(localizations),
          _buildInterestsTab(localizations),
          _buildPhotosTab(localizations),
          _buildPreferencesTab(localizations),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab(AppLocalizations localizations) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Picture Section
            Container(
              decoration: BoxDecoration(
                gradient: gradient,
              ),
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickProfilePicture,
                        child: Hero(
                          tag: 'edit_profile_avatar',
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
                              radius: 70,
                              backgroundColor: Colors.white,
                              backgroundImage: _photoUrl != null
                                  ? CachedNetworkImageProvider(_photoUrl!)
                                  : null,
                              child: _photoUrl == null
                                  ? Text(
                                      widget.currentUser.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 56,
                                        color: AppTheme.primaryRose,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingImage ? null : _pickProfilePicture,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: gradient,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryRose
                                      .withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _isUploadingImage
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tap to change profile picture',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: localizations.name,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: localizations.age,
                      prefixIcon: const Icon(Icons.cake_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your age';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 18 || age > 100) {
                        return 'Please enter a valid age (18-100)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.person_outline),
                      helperText: 'Your gender',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: localizations.bio,
                      prefixIcon: const Icon(Icons.edit_outlined),
                      alignLabelWithHint: true,
                      helperText: 'Tell people about yourself',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please write a short bio';
                      }
                      if (value.length < 20) {
                        return 'Bio must be at least 20 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Location Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Share My Location'),
                          subtitle: const Text(
                            'Allow others to see your approximate location',
                          ),
                          value: _locationSharingEnabled,
                          activeTrackColor:
                              AppTheme.primaryRose.withValues(alpha: 0.5),
                          activeThumbColor: AppTheme.primaryRose,
                          onChanged: (value) {
                            setState(() {
                              _locationSharingEnabled = value;
                            });
                          },
                        ),
                        if (_locationSharingEnabled) ...[
                          const Divider(height: 1),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.softPink,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.my_location,
                                color: AppTheme.deepPink,
                              ),
                            ),
                            title: const Text('Update Location'),
                            subtitle: const Text('Get current GPS location'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _updateLocation,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestsTab(AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.interests,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Select at least one interest to help us connect you with like-minded people',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          // Selected count
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  '${_selectedInterests.length} interests selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return FilterChip(
                label: Text(interest),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedInterests.add(interest);
                    } else {
                      _selectedInterests.remove(interest);
                    }
                  });
                },
                selectedColor: AppTheme.softPink,
                checkmarkColor: AppTheme.deepPink,
                labelStyle: TextStyle(
                  color:
                      isSelected ? AppTheme.deepPink : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosTab(AppLocalizations localizations) {
    final totalPhotos = _photos.length + _newPhotoFiles.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photo Gallery',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add up to $_maxPhotos photos to showcase your personality',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          // Photo count
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.photo_library, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  '$totalPhotos / $_maxPhotos photos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Photo Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: totalPhotos + (totalPhotos < _maxPhotos ? 1 : 0),
            itemBuilder: (context, index) {
              // Add photo button
              if (index == totalPhotos) {
                return GestureDetector(
                  onTap: _isUploadingImage ? null : _addPhoto,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.primaryRose,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isUploadingImage
                              ? Icons.hourglass_empty
                              : Icons.add_photo_alternate,
                          color: AppTheme.primaryRose,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isUploadingImage ? 'Loading...' : 'Add Photo',
                          style: const TextStyle(
                            color: AppTheme.primaryRose,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Existing photos
              if (index < _photos.length) {
                return _buildPhotoTile(
                  _photos[index],
                  index,
                  isNew: false,
                );
              }

              // New photos
              final newIndex = index - _photos.length;
              return _buildNewPhotoTile(_newPhotoFiles[newIndex], newIndex);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoTile(String photoUrl, int index, {required bool isNew}) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: CachedNetworkImageProvider(photoUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removePhoto(index, isNew: isNew),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppTheme.coral,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPhotoTile(XFile file, int index) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[300],
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: MemoryImage(snapshot.data!),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removePhoto(index, isNew: true),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.coral,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.royalPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'New',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreferencesTab(AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dating Preferences',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Set your preferences to find better matches',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 32),

          // Age Range Preference
          Text(
            'Preferred Age Range',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ages $_preferredAgeMin - $_preferredAgeMax',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.royalPurple,
            ),
          ),
          const SizedBox(height: 16),

          // Min Age Slider
          Row(
            children: [
              const Icon(Icons.cake_outlined,
                  color: AppTheme.primaryRose, size: 20),
              const SizedBox(width: 12),
              const Text('Min Age:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(
                '$_preferredAgeMin years',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.deepPink,
                ),
              ),
            ],
          ),
          Slider(
            value: _preferredAgeMin.toDouble(),
            min: 18,
            max: 100,
            divisions: 82,
            activeColor: AppTheme.primaryRose,
            onChanged: (value) {
              setState(() {
                _preferredAgeMin = value.toInt();
                if (_preferredAgeMin > _preferredAgeMax) {
                  _preferredAgeMax = _preferredAgeMin;
                }
              });
            },
          ),

          const SizedBox(height: 16),

          // Max Age Slider
          Row(
            children: [
              const Icon(Icons.cake_outlined,
                  color: AppTheme.primaryRose, size: 20),
              const SizedBox(width: 12),
              const Text('Max Age:',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(
                '$_preferredAgeMax years',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.deepPink,
                ),
              ),
            ],
          ),
          Slider(
            value: _preferredAgeMax.toDouble(),
            min: 18,
            max: 100,
            divisions: 82,
            activeColor: AppTheme.primaryRose,
            onChanged: (value) {
              setState(() {
                _preferredAgeMax = value.toInt();
                if (_preferredAgeMax < _preferredAgeMin) {
                  _preferredAgeMin = _preferredAgeMax;
                }
              });
            },
          ),

          const SizedBox(height: 32),

          // Gender Preference
          Text(
            'Looking For',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: RadioGroup<String?>(
              groupValue: _preferredGender,
              onChanged: (value) {
                setState(() {
                  _preferredGender = value;
                  if (value == 'other') {
                    _showOtherGenderDialog();
                  } else {
                    _preferredGenderOther = null;
                  }
                });
              },
              child: Column(
                children: [
                  RadioListTile<String?>(
                    title: const Text('Everyone'),
                    subtitle: const Text('Show all genders'),
                    value: null,
                    activeColor: AppTheme.primaryRose,
                    toggleable: true,
                  ),
                  const Divider(height: 1),
                  RadioListTile<String?>(
                    title: const Text('Men'),
                    subtitle: const Text('Show only men'),
                    value: 'male',
                    activeColor: AppTheme.primaryRose,
                    toggleable: true,
                  ),
                  const Divider(height: 1),
                  RadioListTile<String?>(
                    title: const Text('Women'),
                    subtitle: const Text('Show only women'),
                    value: 'female',
                    activeColor: AppTheme.primaryRose,
                    toggleable: true,
                  ),
                  const Divider(height: 1),
                  RadioListTile<String?>(
                    title: const Text('Other'),
                    subtitle: Text(
                      _preferredGenderOther != null && _preferredGenderOther!.isNotEmpty
                          ? _preferredGenderOther!
                          : 'Specify what you\'re looking for',
                    ),
                    value: 'other',
                    activeColor: AppTheme.primaryRose,
                    toggleable: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Distance Preference
          Text(
            'Maximum Distance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Limit by Distance'),
                  subtitle: Text(
                    _preferredMaxDistance == null
                        ? 'Show users of any distance'
                        : 'Show users within $_preferredMaxDistance km',
                  ),
                  value: _preferredMaxDistance != null,
                  activeTrackColor: AppTheme.primaryRose.withValues(alpha: 0.5),
                  activeThumbColor: AppTheme.primaryRose,
                  onChanged: (value) {
                    setState(() {
                      _preferredMaxDistance = value ? 50 : null;
                    });
                  },
                ),
                if (_preferredMaxDistance != null) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppTheme.primaryRose, size: 20),
                            const SizedBox(width: 12),
                            const Text('Distance:',
                                style: TextStyle(fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Text(
                              '$_preferredMaxDistance km',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.deepPink,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _preferredMaxDistance!.toDouble(),
                          min: 1,
                          max: 500,
                          divisions: 99,
                          activeColor: AppTheme.primaryRose,
                          onChanged: (value) {
                            setState(() {
                              _preferredMaxDistance = value.toInt();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.softPink,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.primaryRose.withValues(alpha: 0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.deepPink,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How Preferences Work',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.deepPink,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'These preferences help filter who you see in the Discover tab. Users who match your criteria will appear in your feed.',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
