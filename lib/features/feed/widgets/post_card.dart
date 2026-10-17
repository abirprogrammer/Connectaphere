import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/post.dart';
import '../../../core/constants/app_colors.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onSave;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: post.avatarUrl != null && post.avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(post.avatarUrl!)
                  : null,
              child: post.avatarUrl == null || post.avatarUrl!.isEmpty
                  ? const Icon(Icons.person, color: AppColors.primary)
                  : null,
            ),
            title: Text(post.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text('${post.username} • ${_formatTime(post.createdAt)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            trailing: IconButton(
              icon: Icon(post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: post.isSaved ? AppColors.primary : Colors.grey),
              onPressed: onSave,
            ),
          ),

          // Content Text
          if (post.content != null && post.content!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(post.content!, style: const TextStyle(fontSize: 15, height: 1.4)),
            ),

          // Media (Images / Videos)
          if (post.media.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                width: double.infinity,
                child: Image.network(
                  post.media.first.url,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 280,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 220,
                    color: Colors.grey.shade200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Image could not be loaded', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Counters (Likes & Comments count)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.thumb_up, size: 10, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Text('${post.reactionsCount}', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                  ],
                ),
                Text('${post.commentsCount} comments', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onLike,
                  icon: Icon(
                    post.userReaction != null ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                    color: post.userReaction != null ? AppColors.primary : Colors.grey.shade700,
                    size: 20,
                  ),
                  label: Text('Like',
                      style: TextStyle(
                          color: post.userReaction != null ? AppColors.primary : Colors.grey.shade700,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onComment,
                  icon: Icon(Icons.chat_bubble_outline, color: Colors.grey.shade700, size: 20),
                  label: Text('Comment', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.share_outlined, color: Colors.grey.shade700, size: 20),
                  label: Text('Share', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
