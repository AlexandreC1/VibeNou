import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';

class DatingPreferencesScreen extends StatefulWidget {
  final UserModel currentUser;

  const DatingPreferencesScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<DatingPreferencesScreen> createState() => _DatingPreferencesScreenState();
}

class _DatingPreferencesScreenState extends State<DatingPreferencesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late RangeValues _ageRange;
  late String? _preferredGender;
  late List<String> _preferredEthnicities;
  late List<String> _preferredInterests;
  late double _maxDistance;

  bool _isSaving = false;

  // Available options
  final List<String> _ethnicityOptions = [
    'Black/African',
    'White/Caucasian',
    'Hispanic/Latino',
    'Asian',
    'Middle Eastern',
    'Native American',
    'Pacific Islander',
    'Mixed/Multiracial',
    'Other',
  ];

  final List<String> _interestOptions = [
    'Travel',
    'Music',
    'Movies',
    'Sports',
    'Fitness',
    'Cooking',
    'Art',
    'Photography',
    'Reading',
    'Gaming',
    'Dancing',
    'Fashion',
    'Technology',
    'Nature',
    'Pets',
  ];

  @override
  void initState() {
    super.initState();
    _ageRange = RangeValues(
      widget.currentUser.preferredAgeMin.toDouble(),
      widget.currentUser.preferredAgeMax.toDouble(),
    );
    _preferredGender = widget.currentUser.preferredGender;
    _preferredEthnicities = List.from(widget.currentUser.preferredEthnicities);
    _preferredInterests = List.from(widget.currentUser.preferredInterests);
    _maxDistance = widget.currentUser.preferredMaxDistance?.toDouble() ?? 50.0;
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);

    try {
      await _firestore.collection('users').doc(widget.currentUser.uid).update({
        'preferredAgeMin': _ageRange.start.round(),
        'preferredAgeMax': _ageRange.end.round(),
        'preferredGender': _preferredGender,
        'preferredEthnicities': _preferredEthnicities,
        'preferredInterests': _preferredInterests,
        'preferredMaxDistance': _maxDistance.round(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully!'),
            backgroundColor: AppTheme.primaryRose,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: AppTheme.coral,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dating Preferences'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _savePreferences,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gender Preference
            _buildSectionTitle('Show me'),
            const SizedBox(height: 12),
            _buildGenderSelector(),

            const SizedBox(height: 32),

            // Age Range
            _buildSectionTitle('Age Range'),
            const SizedBox(height: 8),
            _buildAgeRangeSlider(),

            const SizedBox(height: 32),

            // Maximum Distance
            _buildSectionTitle('Maximum Distance'),
            const SizedBox(height: 8),
            _buildDistanceSlider(),

            const SizedBox(height: 32),

            // Ethnicity Preferences
            _buildSectionTitle('Ethnicity Preferences'),
            const SizedBox(height: 8),
            Text(
              _preferredEthnicities.isEmpty
                  ? 'All ethnicities (tap to select specific)'
                  : '${_preferredEthnicities.length} selected',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            _buildEthnicityChips(),

            const SizedBox(height: 32),

            // Interest Preferences
            _buildSectionTitle('Interest Preferences'),
            const SizedBox(height: 8),
            Text(
              _preferredInterests.isEmpty
                  ? 'All interests (tap to select specific)'
                  : '${_preferredInterests.length} selected',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            _buildInterestChips(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          RadioListTile<String?>(
            title: const Text('Everyone'),
            value: null,
            groupValue: _preferredGender,
            activeColor: AppTheme.primaryRose,
            onChanged: (value) {
              setState(() {
                _preferredGender = value;
              });
            },
          ),
          const Divider(height: 1),
          RadioListTile<String?>(
            title: const Text('Men'),
            value: 'male',
            groupValue: _preferredGender,
            activeColor: AppTheme.primaryRose,
            onChanged: (value) {
              setState(() {
                _preferredGender = value;
              });
            },
          ),
          const Divider(height: 1),
          RadioListTile<String?>(
            title: const Text('Women'),
            value: 'female',
            groupValue: _preferredGender,
            activeColor: AppTheme.primaryRose,
            onChanged: (value) {
              setState(() {
                _preferredGender = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAgeRangeSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_ageRange.start.round()} years',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text('to'),
              Text(
                '${_ageRange.end.round()} years',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 100,
            divisions: 82,
            activeColor: AppTheme.primaryRose,
            inactiveColor: AppTheme.lavender,
            labels: RangeLabels(
              _ageRange.start.round().toString(),
              _ageRange.end.round().toString(),
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _ageRange = values;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Within',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '${_maxDistance.round()} km',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryRose,
                ),
              ),
            ],
          ),
          Slider(
            value: _maxDistance,
            min: 1,
            max: 500,
            divisions: 499,
            activeColor: AppTheme.primaryRose,
            inactiveColor: AppTheme.lavender,
            label: '${_maxDistance.round()} km',
            onChanged: (double value) {
              setState(() {
                _maxDistance = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEthnicityChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _ethnicityOptions.map((ethnicity) {
        final isSelected = _preferredEthnicities.contains(ethnicity);
        return FilterChip(
          label: Text(ethnicity),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _preferredEthnicities.add(ethnicity);
              } else {
                _preferredEthnicities.remove(ethnicity);
              }
            });
          },
          selectedColor: AppTheme.primaryRose.withValues(alpha: 0.2),
          checkmarkColor: AppTheme.primaryRose,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.primaryRose : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInterestChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _interestOptions.map((interest) {
        final isSelected = _preferredInterests.contains(interest);
        return FilterChip(
          label: Text(interest),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _preferredInterests.add(interest);
              } else {
                _preferredInterests.remove(interest);
              }
            });
          },
          selectedColor: AppTheme.royalPurple.withValues(alpha: 0.2),
          checkmarkColor: AppTheme.royalPurple,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.royalPurple : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
