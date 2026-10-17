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

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
      });
    }
  }

  Future<void> _submitStory() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image for your story.')),
      );
      return;
    }

    setState(() => _isUploading = true);
    final client = ref.read(apiClientProvider);

    try {
      final userId = await SecureStorageService.getUserId() ?? 1;

      // 1. Upload media file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(_selectedFile!.path),
      });
      final uploadRes = await client.dio.post(ApiConstants.uploadMedia, data: formData);
      
      if (uploadRes.data is Map && uploadRes.data['success'] == true) {
        final mediaUrl = uploadRes.data['data']['url'];
        final mediaType = uploadRes.data['data']['media_type'] ?? 'image';

        // 2. Create story in database
        final storyRes = await client.dio.post(ApiConstants.stories, data: {
          'user_id': userId,
          'media_url': mediaUrl,
          'media_type': mediaType,
          'caption': _captionController.text.trim(),
        });

        if (storyRes.data is Map && storyRes.data['success'] == true && mounted) {
          context.pop();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(storyRes.data['message'] ?? 'Failed to publish story.')),
          );
        }
      } else if (mounted) {
        final errorMsg = (uploadRes.data is Map && uploadRes.data['message'] != null)
            ? uploadRes.data['message']
            : 'Media upload failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish story: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Story'),
        actions: [
          ElevatedButton(
            onPressed: _isUploading ? null : _submitStory,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: _isUploading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Share to Story', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Preview Container
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 380,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  image: _selectedFile != null
                      ? DecorationImage(image: FileImage(_selectedFile!), fit: BoxFit.cover)
                      : null,
                ),
                child: _selectedFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo, size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Tap to select photo for story', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _captionController,
              decoration: InputDecoration(
                hintText: 'Add a caption...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
