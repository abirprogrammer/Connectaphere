import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/api_constants.dart';
import '../../models/post.dart';
import '../../models/story.dart';
import '../auth/auth_provider.dart';
import '../stories/story_carousel.dart';
import 'widgets/post_card.dart';

final feedPostsProvider =
FutureProvider.autoDispose<List<Post>>((ref) async {
  try {
    final client = ref.read(apiClientProvider);
    final response = await client.dio.get(ApiConstants.posts);

    if (response.data is Map &&
        response.data['success'] == true) {
      final rawData = response.data['data'];

      if (rawData is List) {
        return rawData.map((p) => Post.fromJson(p)).toList();
      }
    }
  } catch (_) {}

  return [];
});

final storiesFeedProvider =
FutureProvider.autoDispose<List<UserStoryGroup>>((ref) async {
  try {
    final client = ref.read(apiClientProvider);
    final response = await client.dio.get(ApiConstants.stories);

    if (response.data is Map &&
        response.data['success'] == true) {
      final rawData = response.data['data'];

      if (rawData is List) {
        return rawData
            .map((s) => UserStoryGroup.fromJson(s))
            .toList();
      }
    }
  } catch (_) {}

  return [];
});

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(feedPostsProvider);
    final storiesAsync = ref.watch(storiesFeedProvider);
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.value;

    return Scaffold(
      // Facebook-style navigation drawer
      drawer: Drawer(
        width: 310,
        child: SafeArea(
          child: Column(
            children: [
              // Drawer header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  18,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                      currentUser?.avatarUrl != null &&
                          currentUser!.avatarUrl!.isNotEmpty
                          ? NetworkImage(currentUser.avatarUrl!)
                          : null,
                      child: currentUser?.avatarUrl == null ||
                          currentUser!.avatarUrl!.isEmpty
                          ? const Icon(
                        Icons.person,
                        size: 32,
                        color: Colors.grey,
                      )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Welcome to ConnectSphere',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your community, your connections',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/profile');
                        },
                        icon: const Icon(Icons.person_outline),
                        label: const Text('View your profile'),
                      ),
                    ),
                  ],
                ),
              ),

              // Drawer menu items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.home_outlined,
                        color: Colors.blue,
                      ),
                      title: const Text('Feed'),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.person_outline,
                        color: Colors.blue,
                      ),
                      title: const Text('Profile'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/profile');
                      },
                    ),
                    const Divider(height: 12),
                    ListTile(
                      leading: const Icon(
                        Icons.search,
                        color: Colors.blue,
                      ),
                      title: const Text('Search people and posts'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/search');
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.message_outlined,
                        color: Colors.blue,
                      ),
                      title: const Text('Messages'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/conversations');
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.add_box_outlined,
                        color: Colors.blue,
                      ),
                      title: const Text('Create post'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/create-post');
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.auto_stories_outlined,
                        color: Colors.blue,
                      ),
                      title: const Text('Create story'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/create-story');
                      },
                    ),
                  ],
                ),
              ),

              // Drawer footer
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'ConnectSphere • Stay connected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Facebook-style app bar with menu button
      appBar: AppBar(
        leading: Builder(
          builder: (drawerContext) {
            return IconButton(
              tooltip: 'Open menu',
              icon: const Icon(
                Icons.menu_rounded,
                size: 28,
              ),
              onPressed: () {
                Scaffold.of(drawerContext).openDrawer();
              },
            );
          },
        ),
        title: const Text(
          'ConnectSphere',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            tooltip: 'Messages',
            icon: const Icon(Icons.message_outlined),
            onPressed: () => context.push('/conversations'),
          ),
        ],
      ),

      // Main feed
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(feedPostsProvider);
          ref.invalidate(storiesFeedProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Create post quick bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Theme.of(context).cardColor,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage:
                      currentUser?.avatarUrl != null &&
                          currentUser!.avatarUrl!.isNotEmpty
                          ? NetworkImage(currentUser.avatarUrl!)
                          : null,
                      child: currentUser?.avatarUrl == null ||
                          currentUser!.avatarUrl!.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/create-post'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            "What's on your mind?",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Stories section
              storiesAsync.when(
                data: (groups) => StoryCarousel(
                  storyGroups: groups,
                  onCreateStory: () => context.push('/create-story'),
                  onStoryTap: (group) {
                    context.push('/story-view', extra: group);
                  },
                ),
                loading: () => const SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const Divider(thickness: 4),

              // Posts feed
              postsAsync.when(
                data: (posts) {
                  if (posts.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No posts yet. Connect with friends or share something!',
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];

                      return PostCard(
                        post: post,
                        onLike: () async {
                          final client =
                          ref.read(apiClientProvider);

                          await client.dio.post(
                            ApiConstants.toggleReaction,
                            data: {
                              'target_type': 'post',
                              'target_id': post.id,
                              'reaction_type': 'like',
                            },
                          );

                          ref.invalidate(feedPostsProvider);
                        },
                        onComment: () =>
                            _showCommentsBottomSheet(
                              context,
                              ref,
                              post.id,
                            ),
                        onSave: () async {
                          final client =
                          ref.read(apiClientProvider);

                          await client.dio.post(
                            ApiConstants.savePost,
                            data: {
                              'post_id': post.id,
                            },
                          );

                          ref.invalidate(feedPostsProvider);
                        },
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text('Failed to load feed: $err'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Comments bottom sheet
  void _showCommentsBottomSheet(
      BuildContext context,
      WidgetRef ref,
      int postId,
      ) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 12,
                left: 16,
                right: 16,
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),

                  // Comments list
                  Expanded(
                    child: FutureBuilder(
                      future: ref
                          .read(apiClientProvider)
                          .dio
                          .get(
                        '${ApiConstants.comments}?post_id=$postId',
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        try {
                          final res = snapshot.data!;
                          final rawData = res.data is Map
                              ? res.data['data']
                              : null;
                          final items =
                          rawData is List ? rawData : [];

                          if (items.isEmpty) {
                            return const Center(
                              child: Text(
                                'No comments yet. Be the first to comment!',
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final c = items[index];

                              return ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(
                                    Icons.person,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  c['full_name'] ??
                                      c['username'] ??
                                      'User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  c['content'] ?? '',
                                ),
                              );
                            },
                          );
                        } catch (_) {
                          return const Center(
                            child: Text('Error loading comments'),
                          );
                        }
                      },
                    ),
                  ),

                  const Divider(height: 1),

                  // Write comment
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              hintText: 'Write a comment...',
                              border: InputBorder.none,
                              contentPadding:
                              EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.blue,
                          ),
                          onPressed: () async {
                            final content =
                            commentController.text.trim();

                            if (content.isNotEmpty) {
                              await ref
                                  .read(apiClientProvider)
                                  .dio
                                  .post(
                                ApiConstants.comments,
                                data: {
                                  'post_id': postId,
                                  'content': content,
                                },
                              );

                              commentController.clear();

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}