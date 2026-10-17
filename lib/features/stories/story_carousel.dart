
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/story.dart';

class StoryCarousel extends StatelessWidget {
final List<UserStoryGroup> storyGroups;
final VoidCallback onCreateStory;
final Function(UserStoryGroup) onStoryTap;

const StoryCarousel({
super.key,
required this.storyGroups,
required this.onCreateStory,
required this.onStoryTap,
});

@override
Widget build(BuildContext context) {
return SizedBox(
height: 190,
child: ListView.builder(
scrollDirection: Axis.horizontal,
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 8,
),
itemCount: storyGroups.length + 1,
itemBuilder: (context, index) {
if (index == 0) {
return GestureDetector(
onTap: onCreateStory,
child: Container(
width: 110,
margin: const EdgeInsets.only(right: 8),
decoration: BoxDecoration(
color: Colors.blue.shade50,
borderRadius: BorderRadius.circular(16),
border: Border.all(color: Colors.blue.shade100),
),
child: const Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
CircleAvatar(
radius: 24,
backgroundColor: AppColors.primary,
child: Icon(
Icons.add,
color: Colors.white,
size: 28,
),
),
SizedBox(height: 8),
Text(
'Add Story',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 13,
),
),
],
),
),
);
}

final group = storyGroups[index - 1];

// Empty groups যেন crash না করে।
if (group.stories.isEmpty) {
return const SizedBox.shrink();
}

final firstStory = group.stories.first;

return GestureDetector(
onTap: () => onStoryTap(group),
child: Container(
width: 110,
margin: const EdgeInsets.only(right: 8),
decoration: BoxDecoration(
color: Colors.grey.shade300,
borderRadius: BorderRadius.circular(16),
image: DecorationImage(
image: CachedNetworkImageProvider(
firstStory.mediaUrl,
),
fit: BoxFit.cover,
onError: (_, __) {},
),
),
clipBehavior: Clip.antiAlias,
child: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(16),
gradient: LinearGradient(
colors: [
Colors.black.withValues(alpha: 0.6),
Colors.transparent,
Colors.black.withValues(alpha: 0.7),
],
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
),
),
child: Column(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
padding: const EdgeInsets.all(2),
decoration: const BoxDecoration(
color: AppColors.primary,
shape: BoxShape.circle,
),
child: CircleAvatar(
radius: 17,
backgroundColor: Colors.grey.shade300,
backgroundImage: group.avatarUrl != null &&
group.avatarUrl!.isNotEmpty
? CachedNetworkImageProvider(
group.avatarUrl!,
)
    : null,
child: group.avatarUrl == null ||
group.avatarUrl!.isEmpty
? const Icon(Icons.person)
    : null,
),
),
Text(
group.fullName.isNotEmpty
? group.fullName
    : group.username,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold,
fontSize: 12,
shadows: [
Shadow(
color: Colors.black54,
blurRadius: 4,
),
],
),
),
],
),
),
),
);
},
),
);
}
}
