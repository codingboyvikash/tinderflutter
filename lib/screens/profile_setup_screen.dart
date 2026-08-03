import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _professionController = TextEditingController();
  final _educationController = TextEditingController();
  final _languagesController = TextEditingController();
  final _hobbiesController = TextEditingController();
  
  DateTime? _selectedBirthDate;
  String _selectedGender = 'male';
  String _selectedInterest = 'female';
  
  double? _latitude;
  double? _longitude;
  bool _fetchingLocation = false;

  final List<String> _predefinedInterests = [
    'Music', 'Travel', 'Art', 'Sports', 'Photography', 
    'Gaming', 'Cooking', 'Reading', 'Movies', 'Fitness',
    'Dancing', 'Writing', 'Technology', 'Nature', 'Fashion'
  ];
  final List<String> _selectedInterestsList = [];
  final List<XFile> _localPhotos = [];
  bool _initializedProfileData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndPopulateProfile();
    });
  }

  void _loadAndPopulateProfile() async {
    final state = ref.read(profileNotifierProvider);
    if (state is ProfileLoaded) {
      _populateFromProfileMap(state.profile);
    } else {
      await ref.read(profileNotifierProvider.notifier).loadProfile();
      final nextState = ref.read(profileNotifierProvider);
      if (nextState is ProfileLoaded) {
        _populateFromProfileMap(nextState.profile);
      }
    }
  }

  void _populateFromProfileMap(Map<String, dynamic> profile) {
    if (_initializedProfileData) return;
    _initializedProfileData = true;

    setState(() {
      _nameController.text = profile['displayName']?.toString() ?? '';
      _bioController.text = profile['bio']?.toString() ?? '';
      _professionController.text = profile['profession']?.toString() ?? '';
      _educationController.text = profile['education']?.toString() ?? '';

      if (profile['languages'] != null && profile['languages'] is List) {
        _languagesController.text = List<String>.from(profile['languages']).join(', ');
      }
      if (profile['hobbies'] != null && profile['hobbies'] is List) {
        _hobbiesController.text = List<String>.from(profile['hobbies']).join(', ');
      }
      if (profile['interests'] != null && profile['interests'] is List) {
        _selectedInterestsList.clear();
        _selectedInterestsList.addAll(List<String>.from(profile['interests']));
      }

      if (profile['gender'] != null && profile['gender'].toString().isNotEmpty) {
        _selectedGender = profile['gender'].toString();
      }
      if (profile['interestedIn'] != null && profile['interestedIn'].toString().isNotEmpty) {
        _selectedInterest = profile['interestedIn'].toString();
      }

      if (profile['birthDate'] != null) {
        try {
          _selectedBirthDate = DateTime.tryParse(profile['birthDate'].toString());
        } catch (_) {}
      }

      if (profile['location'] != null && profile['location']['coordinates'] != null) {
        final coords = profile['location']['coordinates'] as List;
        if (coords.length >= 2) {
          _longitude = (coords[0] as num).toDouble();
          _latitude = (coords[1] as num).toDouble();
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _professionController.dispose();
    _educationController.dispose();
    _languagesController.dispose();
    _hobbiesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final state = ref.read(profileNotifierProvider);
    final photos = state is ProfileLoaded ? List<String>.from(state.profile['photos'] ?? []) : [];
    final remaining = 9 - photos.length - _localPhotos.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only add up to 9 photos.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryPink),
                title: const Text('Select Multiple from Gallery', style: TextStyle(color: AppTheme.textPrimaryLight)),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImages(remaining);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined, color: AppTheme.primaryPink),
                title: const Text('Select Single from Gallery', style: TextStyle(color: AppTheme.textPrimaryLight)),
                onTap: () {
                  Navigator.pop(context);
                  _pickSingleImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryPink),
                title: const Text('Take Photo with Camera', style: TextStyle(color: AppTheme.textPrimaryLight)),
                onTap: () {
                  Navigator.pop(context);
                  _pickSingleImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickSingleImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _localPhotos.add(image);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image Picker Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _pickMultipleImages(int remaining) async {
    try {
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 70,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _localPhotos.addAll(images.take(remaining));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image Picker Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _fetchingLocation = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS coordinates loaded successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _fetchingLocation = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // default age 18
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryPink,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceDark,
              onSurface: AppTheme.textPrimaryLight,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Date of Birth'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fetch your GPS location coordinates'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final profileData = {
      'displayName': _nameController.text.trim(),
      'bio': _bioController.text.trim(),
      'birthDate': _selectedBirthDate!.toIso8601String(),
      'gender': _selectedGender,
      'interestedIn': _selectedInterest,
      'profession': _professionController.text.trim(),
      'education': _educationController.text.trim(),
      'languages': _languagesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      'hobbies': _hobbiesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      'interests': _selectedInterestsList,
      'latitude': _latitude,
      'longitude': _longitude,
    };

    final success = await ref.read(profileNotifierProvider.notifier).updateProfile(profileData);
    if (success && mounted) {
      if (_localPhotos.isNotEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const PopScope(
            canPop: false,
            child: Center(
              child: Card(
                color: AppTheme.surfaceDark,
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryPink),
                      SizedBox(height: 16),
                      Text(
                        'Uploading profile photos...',
                        style: TextStyle(color: AppTheme.textPrimaryLight, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        try {
          for (final photo in _localPhotos) {
            await ref.read(profileNotifierProvider.notifier).uploadPhoto(photo.path);
          }
        } catch (e) {
          // Keep going even if some uploads fail to prevent complete lock
        }

        if (!mounted) return;
        Navigator.pop(context); // Dismiss dialog
      }

      if (mounted) {
        context.go('/home');
      }
    } else {
      if (mounted) {
        final profileState = ref.read(profileNotifierProvider);
        final errorMsg = profileState is ProfileError ? profileState.message : 'Failed to save profile';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileNotifierProvider);

    ref.listen<ProfileState>(profileNotifierProvider, (previous, next) {
      if (next is ProfileLoaded) {
        _populateFromProfileMap(next.profile);
      }
    });

    List<String> photos = [];
    bool isEditing = false;
    if (state is ProfileLoaded) {
      photos = List<String>.from(state.profile['photos'] ?? []);
      if (state.profile['displayName'] != null) {
        isEditing = true;
      }
    }

    final apiBaseUrl = ref.watch(networkServiceProvider).dio.options.baseUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Profile Details' : 'Create Profile', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
              context.go('/onboarding');
            },
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section: Profile Photos (up to 9)
                Text(
                  'Profile Photos (up to 9)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    if (index < photos.length) {
                      final photoUrl = photos[index];
                      return GestureDetector(
                        onTap: () => ref.read(profileNotifierProvider.notifier).deletePhoto(photoUrl),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF334155), width: 1.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: photoUrl.startsWith('/uploads/') 
                                    ? '$apiBaseUrl$photoUrl' 
                                    : photoUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    } else if (index < photos.length + _localPhotos.length) {
                      final localIndex = index - photos.length;
                      final localFile = _localPhotos[localIndex];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _localPhotos.removeAt(localIndex);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primaryPink.withAlpha(128), width: 1.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(localFile.path),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                                ),
                              ),
                              Positioned(
                                left: 6,
                                bottom: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryPink.withAlpha(204),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Pending',
                                    style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    } else {
                      return GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF334155), width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(Icons.add_a_photo_outlined, size: 30, color: AppTheme.textSecondaryLight),
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 32),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    hintText: 'What should we call you?',
                    prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondaryLight),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Display Name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // DOB Picker
                GestureDetector(
                  onTap: _selectBirthDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF334155), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cake_outlined, color: AppTheme.textSecondaryLight),
                            const SizedBox(width: 12),
                            Text(
                              _selectedBirthDate == null
                                  ? 'Select Birth Date'
                                  : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}',
                              style: TextStyle(
                                color: _selectedBirthDate == null ? AppTheme.textSecondaryLight : AppTheme.textPrimaryLight,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondaryLight),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Gender Selectors
                Text('Gender', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Male'),
                        selected: _selectedGender == 'male',
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedGender = 'male');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Female'),
                        selected: _selectedGender == 'female',
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedGender = 'female');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Other'),
                        selected: _selectedGender == 'other',
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedGender = 'other');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Interested In Selectors
                Text('Interested In', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Male'),
                        selected: _selectedInterest == 'male',
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedInterest = 'male');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Female'),
                        selected: _selectedInterest == 'female',
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedInterest = 'female');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Everyone'),
                        selected: _selectedInterest == 'everyone',
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedInterest = 'everyone');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Bio
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Tell us about yourself...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 50.0),
                      child: Icon(Icons.description_outlined, color: AppTheme.textSecondaryLight),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Profession
                TextFormField(
                  controller: _professionController,
                  decoration: const InputDecoration(
                    labelText: 'Profession',
                    hintText: 'What is your job?',
                    prefixIcon: Icon(Icons.work_outline, color: AppTheme.textSecondaryLight),
                  ),
                ),
                const SizedBox(height: 20),

                // Education
                TextFormField(
                  controller: _educationController,
                  decoration: const InputDecoration(
                    labelText: 'Education',
                    hintText: 'University/College name',
                    prefixIcon: Icon(Icons.school_outlined, color: AppTheme.textSecondaryLight),
                  ),
                ),
                const SizedBox(height: 20),

                // Languages
                TextFormField(
                  controller: _languagesController,
                  decoration: const InputDecoration(
                    labelText: 'Languages (comma separated)',
                    hintText: 'e.g. English, Hindi, Spanish',
                    prefixIcon: Icon(Icons.language, color: AppTheme.textSecondaryLight),
                  ),
                ),
                const SizedBox(height: 20),

                // Hobbies
                TextFormField(
                  controller: _hobbiesController,
                  decoration: const InputDecoration(
                    labelText: 'Hobbies (comma separated)',
                    hintText: 'e.g. Gaming, Cricket, Coding',
                    prefixIcon: Icon(Icons.favorite_border, color: AppTheme.textSecondaryLight),
                  ),
                ),
                const SizedBox(height: 28),

                // Interests Grid Selection
                Text('Interests', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _predefinedInterests.map((interest) {
                    final isSelected = _selectedInterestsList.contains(interest);
                    return FilterChip(
                      label: Text(interest),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedInterestsList.add(interest);
                          } else {
                            _selectedInterestsList.remove(interest);
                          }
                        });
                      },
                      selectedColor: AppTheme.primaryPink.withAlpha(51),
                      checkmarkColor: AppTheme.primaryPink,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // GPS Location coordinates selection
                Text('Location Coordinates', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Text(
                          _latitude != null && _longitude != null
                              ? 'Lat: ${_latitude!.toStringAsFixed(4)}\nLong: ${_longitude!.toStringAsFixed(4)}'
                              : 'No Coordinates loaded',
                          style: TextStyle(
                            color: _latitude != null ? AppTheme.textPrimaryLight : AppTheme.textSecondaryLight,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _fetchingLocation ? null : _getCurrentLocation,
                      icon: _fetchingLocation 
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.gps_fixed, size: 18),
                      label: const Text('Locate Me'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 56),
                        backgroundColor: AppTheme.accentPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Save Profile Button
                ElevatedButton(
                  onPressed: state is ProfileLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: state is ProfileLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
