import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../models/user.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final int? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  User? _fetchedUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      int? targetId = widget.userId;
      if (targetId == null) {
        targetId = await SecureStorageService.getUserId() ?? 1;
      }
      final client = ref.read(apiClientProvider);
      final response = await client.dio.get('${ApiConstants.profile}?user_id=$targetId');
      if (response.data is Map && response.data['success'] == true) {
        if (mounted) {
          setState(() {
            _fetchedUser = User.fromJson(response.data['data']);
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).value;
    final user = _fetchedUser ?? authUser;

    if (_isLoading && user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Profile not found. Please log in again.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(user.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/edit-profile'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cover Photo & Avatar Header
            Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  color: AppColors.primary.withValues(alpha: 0.2),
                  child: user.coverUrl != null && user.coverUrl!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: user.coverUrl!, fit: BoxFit.cover)
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, Colors.blue.shade800],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  bottom: -50,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 4),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                          ? const Icon(Icons.person, size: 54, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // Name & Username
            Text(user.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text('@${user.username}', style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w500)),
            
            if (user.bio != null && user.bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(user.bio!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.4)),
              ),

            const SizedBox(height: 16),

            // Stats Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Friends', '${user.friendsCount}'),
                  Container(height: 28, width: 1, color: Colors.grey.shade300),
                  _buildStatItem('Posts', '${user.postsCount}'),
                  Container(height: 28, width: 1, color: Colors.grey.shade300),
                  _buildStatItem('Profile Level', 'Pro'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/edit-profile'),
                      icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                      label: const Text('Edit Profile & Cover', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/create-post'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create Post', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(thickness: 6),

            // About Section Info
            ListTile(
              leading: const Icon(Icons.email_outlined, color: AppColors.primary),
              title: const Text('Email'),
              subtitle: Text(user.email),
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
              title: const Text('Location'),
              subtitle: Text(user.location ?? 'Not specified'),
            ),
            ListTile(
              leading: const Icon(Icons.language, color: AppColors.primary),
              title: const Text('Website'),
              subtitle: Text(user.website ?? 'Not specified'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
              title: const Text('Member Since'),
              subtitle: Text(user.email.isNotEmpty ? 'Active Member' : ''),
            ),
            const SizedBox(height: 20),

            // Premium Log Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFC62828)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(authStateProvider.notifier).logout();
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
