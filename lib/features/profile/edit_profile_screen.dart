import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../models/user.dart';
import '../auth/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  File? _avatarFile;
  File? _coverFile;
  String? _avatarUrl;
  String? _coverUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  void _loadCurrentProfile() {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _bioController.text = user.bio ?? '';
      _locationController.text = user.location ?? '';
      _websiteController.text = user.website ?? '';
      _avatarUrl = user.avatarUrl;
      _coverUrl = user.coverUrl;
      setState(() {});
    }
  }

  Future<void> _pickAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _avatarFile = File(image.path));
    }
  }

  Future<void> _pickCover() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _coverFile = File(image.path));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final client = ref.read(apiClientProvider);

    try {
      final userId = await SecureStorageService.getUserId() ?? 1;

      if (_avatarFile != null) {
        final formData = FormData.fromMap({'file': await MultipartFile.fromFile(_avatarFile!.path)});
        final res = await client.dio.post(ApiConstants.uploadMedia, data: formData);
        if (res.data is Map && res.data['success'] == true) {
          _avatarUrl = res.data['data']['url'];
        }
      }

      if (_coverFile != null) {
        final formData = FormData.fromMap({'file': await MultipartFile.fromFile(_coverFile!.path)});
        final res = await client.dio.post(ApiConstants.uploadMedia, data: formData);
        if (res.data is Map && res.data['success'] == true) {
          _coverUrl = res.data['data']['url'];
        }
      }

      final updateRes = await client.dio.post(ApiConstants.profile, data: {
        'user_id': userId,
        'full_name': _fullNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'website': _websiteController.text.trim(),
        if (_avatarUrl != null) 'avatar_url': _avatarUrl,
        if (_coverUrl != null) 'cover_url': _coverUrl,
      });

      if (updateRes.data is Map && updateRes.data['success'] == true && mounted) {
        final profileRes = await client.dio.get('${ApiConstants.profile}?user_id=$userId');
        if (profileRes.data is Map && profileRes.data['success'] == true) {
          final updatedUser = User.fromJson(profileRes.data['data']);
          ref.read(authStateProvider.notifier).updateUser(updatedUser);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
          context.pop();
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(updateRes.data['message'] ?? 'Failed to update profile.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Photo Section
            const Text('Cover Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickCover,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                  image: _coverFile != null
                      ? DecorationImage(image: FileImage(_coverFile!), fit: BoxFit.cover)
                      : (_coverUrl != null && _coverUrl!.isNotEmpty
                          ? DecorationImage(image: CachedNetworkImageProvider(_coverUrl!), fit: BoxFit.cover)
                          : null),
                ),
                child: (_coverFile == null && (_coverUrl == null || _coverUrl!.isEmpty))
                    ? const Center(child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey))
                    : const Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Profile Picture Section
            const Text('Profile Picture', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _avatarFile != null
                        ? FileImage(_avatarFile!)
                        : (_avatarUrl != null && _avatarUrl!.isNotEmpty ? CachedNetworkImageProvider(_avatarUrl!) : null) as ImageProvider?,
                    child: (_avatarFile == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 54, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        onPressed: _pickAvatar,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(labelText: 'Bio', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'Location', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _websiteController,
              decoration: InputDecoration(labelText: 'Website', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }
}
