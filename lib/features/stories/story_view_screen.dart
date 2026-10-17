
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/story.dart';

class StoryViewScreen extends StatefulWidget {
final UserStoryGroup group;

const StoryViewScreen({
super.key,
required this.group,
});

@override
State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
int _currentIndex = 0;

@override
Widget build(BuildContext context) {
final stories = widget.group.stories;

if (stories.isEmpty) {
return const Scaffold(
backgroundColor: Colors.black,
body: Center(
child: Text(
'No stories available',
style: TextStyle(color: Colors.white),
),
),
);
}

final story = stories[_currentIndex];

return Scaffold(
backgroundColor: Colors.black,
body: SafeArea(
child: GestureDetector(
behavior: HitTestBehavior.opaque,
onTapUp: (details) {
final width = MediaQuery.of(context).size.width;

if (details.globalPosition.dx < width / 3) {
if (_currentIndex > 0) {
setState(() => _currentIndex--);
}
} else if (_currentIndex < stories.length - 1) {
setState(() => _currentIndex++);
} else {
Navigator.of(context).pop();
}
},
child: Stack(
fit: StackFit.expand,
children: [
Center(
child: CachedNetworkImage(
imageUrl: story.mediaUrl,
fit: BoxFit.contain,
placeholder: (context, url) =>
const CircularProgressIndicator(
color: Colors.white,
),
errorWidget: (context, url, error) => const Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
Icons.broken_image,
color: Colors.white,
size: 56,
),
SizedBox(height: 8),
Text(
'Image could not be loaded',
style: TextStyle(color: Colors.white),
),
],
),
),
),

// Story progress
Positioned(
top: 8,
left: 12,
right: 12,
child: Row(
children: List.generate(stories.length, (index) {
return Expanded(
child: Container(
height: 3,
margin: const EdgeInsets.symmetric(horizontal: 2),
decoration: BoxDecoration(
color: index <= _currentIndex
? Colors.white
    : Colors.white38,
borderRadius: BorderRadius.circular(4),
),
),
);
}),
),
),

Positioned(
top: 22,
left: 16,
right: 8,
child: Row(
children: [
CircleAvatar(
radius: 19,
backgroundColor: Colors.grey.shade700,
backgroundImage: widget.group.avatarUrl != null &&
widget.group.avatarUrl!.isNotEmpty
? CachedNetworkImageProvider(
widget.group.avatarUrl!,
)
    : null,
child: widget.group.avatarUrl == null ||
widget.group.avatarUrl!.isEmpty
? const Icon(
Icons.person,
color: Colors.white,
)
    : null,
),
const SizedBox(width: 10),
Expanded(
child: Text(
widget.group.fullName.isNotEmpty
? widget.group.fullName
    : widget.group.username,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
),
IconButton(
onPressed: () => Navigator.of(context).pop(),
icon: const Icon(
Icons.close,
color: Colors.white,
),
),
],
),
),

if (story.caption != null &&
story.caption!.trim().isNotEmpty)
Positioned(
bottom: 32,
left: 20,
right: 20,
child: Container(
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.black54,
borderRadius: BorderRadius.circular(12),
),
child: Text(
story.caption!,
textAlign: TextAlign.center,
style: const TextStyle(
color: Colors.white,
fontSize: 16,
),
),
),
),
],
),
),
),
);
}
}