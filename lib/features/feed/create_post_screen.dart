import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/secure_storage_service.dart';
import '../auth/auth_provider.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  String? _uploadedMediaUrl;
  String _mediaType = 'image'; // image or video
  String _privacy = 'public';
  bool _isUploading = false;

  Future<void> _pickMedia(String type) async {
    final XFile? file = type == 'video'
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() {
        _selectedFile = File(file.path);
        _mediaType = type;
      });
    }
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedFile == null) return;

    setState(() => _isUploading = true);
    final client = ref.read(apiClientProvider);

    try {
      final userId = await SecureStorageService.getUserId() ?? 1;

      if (_selectedFile != null) {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(_selectedFile!.path),
        });
        final uploadRes = await client.dio.post(ApiConstants.uploadMedia, data: formData);
        if (uploadRes.data['success'] == true) {
          _uploadedMediaUrl = uploadRes.data['data']['url'];
          _mediaType = uploadRes.data['data']['media_type'] ?? _mediaType;
        }
      }

      final mediaList = _uploadedMediaUrl != null
          ? [
              {'media_type': _mediaType, 'url': _uploadedMediaUrl}
            ]
          : [];

      final postRes = await client.dio.post(ApiConstants.posts, data: {
        'user_id': userId,
        'content': content,
        'privacy': _privacy,
        'media': mediaList,
      });

      if (postRes.data['success'] == true && mounted) {
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(postRes.data['message'] ?? 'Failed to publish post.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          ElevatedButton(
            onPressed: _isUploading ? null : _submitPost,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: _isUploading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? user?.username ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    DropdownButton<String>(
                      value: _privacy,
                      isDense: true,
                      items: const [
                        DropdownMenuItem(value: 'public', child: Text('Public')),
                        DropdownMenuItem(value: 'friends', child: Text('Friends')),
                        DropdownMenuItem(value: 'private', child: Text('Only Me')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _privacy = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: "What's on your mind?",
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_selectedFile != null)
              Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black,
                ),
                child: _mediaType == 'video'
                    ? const Center(child: Icon(Icons.videocam, size: 50, color: Colors.white))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedFile!, fit: BoxFit.cover),
                      ),
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library, color: Colors.green, size: 28),
                  onPressed: () => _pickMedia('image'),
                ),
                const Text('Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.video_call, color: Colors.red, size: 28),
                  onPressed: () => _pickMedia('video'),
                ),
                const Text('Video', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
