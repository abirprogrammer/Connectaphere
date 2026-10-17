import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/api_constants.dart';
import '../../models/post.dart';
import '../auth/auth_provider.dart';

class ReelsScreen extends ConsumerWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: ref.read(apiClientProvider).dio.get(ApiConstants.reels),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No videos found.', style: TextStyle(color: Colors.white)));
          }
          try {
            final res = snapshot.data!;
            final rawList = (res.data is Map && res.data['data'] is List) ? res.data['data'] as List : [];
            final reels = rawList.map((p) => Post.fromJson(p)).toList();

            if (reels.isEmpty) {
              return const Center(child: Text('No reels uploaded yet.', style: TextStyle(color: Colors.white)));
            }

            return PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: reels.length,
              itemBuilder: (context, index) {
                return ReelItem(post: reels[index]);
              },
            );
          } catch (_) {
            return const Center(child: Text('Error loading videos', style: TextStyle(color: Colors.white)));
          }
        },
      ),
    );
  }
}

class ReelItem extends StatefulWidget {
  final Post post;

  const ReelItem({super.key, required this.post});

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.post.media.isNotEmpty && widget.post.media.first.mediaType == 'video') {
      final videoUrl = widget.post.media.first.url;
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _isInitialized = true);
            _controller?.setLooping(true);
            _controller?.play();
          }
        }).catchError((err) {
          debugPrint('Video player error: $err');
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isInitialized && _controller != null)
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          )
        else
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        Positioned(
          bottom: 36,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: widget.post.avatarUrl != null && widget.post.avatarUrl!.isNotEmpty
                        ? NetworkImage(widget.post.avatarUrl!)
                        : null,
                    child: widget.post.avatarUrl == null || widget.post.avatarUrl!.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.post.fullName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.post.content != null && widget.post.content!.isNotEmpty)
                Text(
                  widget.post.content!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
