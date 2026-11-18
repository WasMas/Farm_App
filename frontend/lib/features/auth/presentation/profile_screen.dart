import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/app_user.dart';
import 'auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _imageUrlController = TextEditingController();

  final _picker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  bool _isSaving = false;
  bool _removePicture = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _initializeFields(AppUser user) {
    if (_initialized) return;

    _nameController.text = user.name;
    _bioController.text = user.bio;
    _imageUrlController.text = user.profileImageUrl;

    _initialized = true;
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
        _imageUrlController.clear();
        _removePicture = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not select image: $e')));
    }
  }

  void _clearPicture() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _imageUrlController.clear();
      _removePicture = true;
    });
  }

  String? _profileImageAddress(AppUser user) {
    final imagePath = user.profileImage;

    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(imagePath);

    if (uri == null) return null;

    if (uri.hasScheme) {
      return imagePath;
    }

    // Relative Django media paths are resolved against the server.
    final baseUri = Uri.parse(
      ref.read(authRepositoryProvider).dio.options.baseUrl,
    );

    return baseUri.resolve(imagePath).toString();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ref
          .read(authProvider.notifier)
          .updateProfile(
            name: _nameController.text.trim(),
            bio: _bioController.text.trim(),
            profileImageUrl: _imageUrlController.text.trim(),
            image: _selectedImage,
            clearUploadedImage: _removePicture,
          );

      if (!mounted) return;

      setState(() {
        _selectedImage = null;
        _selectedImageBytes = null;
        _removePicture = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your profile has been updated successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update your profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).asData?.value;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    _initializeFields(user);

    final uploadedImageAddress = _profileImageAddress(user);

    ImageProvider? currentImage;

    if (_selectedImageBytes != null) {
      currentImage = MemoryImage(_selectedImageBytes!);
    } else if (!_removePicture && _imageUrlController.text.trim().isNotEmpty) {
      currentImage = NetworkImage(_imageUrlController.text.trim());
    } else if (!_removePicture && uploadedImageAddress != null) {
      currentImage = NetworkImage(uploadedImageAddress);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 58,
                          backgroundImage: currentImage,
                          child: currentImage == null
                              ? const Icon(Icons.person, size: 58)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isSaving ? null : _pickImage,
                              icon: const Icon(Icons.upload),
                              label: const Text('Upload picture'),
                            ),
                            TextButton.icon(
                              onPressed: _isSaving ? null : _clearPicture,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remove picture'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Account information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      hintText: 'Enter your display name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    maxLength: 150,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a display name.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Tell us a little about yourself...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.info_outline),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Profile picture URL',
                      hintText: 'https://example.com/image.jpg',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                      helperText: 'Use this instead of uploading a picture.',
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (_) {
                      setState(() {
                        _selectedImage = null;
                        _selectedImageBytes = null;
                        _removePicture = false;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    child: Text(user.email),
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Account role',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    child: Text(user.role),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Saving...' : 'Save changes'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
