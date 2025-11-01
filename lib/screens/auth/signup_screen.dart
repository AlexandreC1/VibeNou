import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../utils/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentPage = 0;

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
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInterests.isEmpty) {
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
      final locationService = LocationService();

      // Get user location
      final position = await locationService.getCurrentPosition();
      GeoPoint? geoPoint;
      if (position != null) {
        geoPoint = GeoPoint(position.latitude, position.longitude);
      }

      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        bio: _bioController.text.trim(),
        interests: _selectedInterests,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign up failed: ${e.toString()}'),
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

  void _nextPage() {
    if (_currentPage == 0) {
      // Validate first page
      if (!_formKey.currentState!.validate()) return;
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: AppTheme.coral,
          ),
        );
        return;
      }
    }

    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      _signUp();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.signUp),
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousPage,
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 3,
              backgroundColor: AppTheme.borderColor,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),

            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildAccountPage(localizations),
                    _buildProfilePage(localizations),
                    _buildInterestsPage(localizations),
                  ],
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextPage,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(_currentPage < 2 ? 'Next' : localizations.signUp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountPage(AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Account',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Enter your email and password',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 30),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: localizations.email,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: localizations.password,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage(AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Information',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Tell us about yourself',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 30),

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

          TextFormField(
            controller: _bioController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: localizations.bio,
              prefixIcon: const Icon(Icons.edit_outlined),
              alignLabelWithHint: true,
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
        ],
      ),
    );
  }

  Widget _buildInterestsPage(AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.interests,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Select at least one interest',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 30),

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
                selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryBlue,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
