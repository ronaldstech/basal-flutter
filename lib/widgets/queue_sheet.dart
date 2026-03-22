import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../models/music_models.dart';
import '../providers/audio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/skeleton_image.dart';
import '../providers/auth_provider.dart';

void showQueueSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _QueueSheet(),
  );
}

class _QueueSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final queue = audioState.queue;
    final currentSong = audioState.currentSong;
    final currentIndex =
        currentSong == null ? -1 : queue.indexWhere((s) => s.id == currentSong.id);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[950] ?? Colors.black,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('Queue',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${queue.length} songs',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ),
                  const Spacer(),
                  Text(
                    audioState.isShuffled ? 'Shuffled' : 'In Order',
                    style: TextStyle(
                      color: audioState.isShuffled
                          ? AppTheme.primaryColor
                          : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            if (queue.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Queue is empty.',
                      style: TextStyle(color: Colors.white38)),
                ),
              )
            else
              Expanded(
                child: ReorderableListView.builder(
                  scrollController: scrollController,
                  itemCount: queue.length,
                  onReorder: (oldIndex, newIndex) {
                    if (!ref.read(isPremiumProvider)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reordering queue is for Premium members'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                      return;
                    }
                    if (newIndex > oldIndex) newIndex--;
                    final newQueue = List<Song>.from(queue);
                    final moved = newQueue.removeAt(oldIndex);
                    newQueue.insert(newIndex, moved);
                    ref.read(audioProvider.notifier).setQueue(newQueue);
                  },
                  itemBuilder: (context, index) {
                    final song = queue[index];
                    final isCurrent = index == currentIndex;
                    return ListTile(
                      key: Key(song.id),
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      leading: Stack(
                        alignment: Alignment.center,
                        children: [
                                  SkeletonImage(
                                    imageUrl: song.thumbnailUrl,
                                    width: 40,
                                    height: 40,
                                    borderRadius: 4,
                                  ),
                          if (isCurrent)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(Iconsax.volume_high,
                                  size: 18, color: AppTheme.primaryColor),
                            ),
                        ],
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrent 
                              ? AppTheme.primaryColor 
                              : (ref.watch(isPremiumProvider) ? Colors.white : Colors.white30),
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, 
                              color: ref.watch(isPremiumProvider) ? Colors.white54 : Colors.white24)),
                      trailing: Icon(Icons.drag_handle,
                          color: ref.watch(isPremiumProvider) ? Colors.white30 : Colors.white12, 
                          size: 20),
                      onTap: () {
                        if (ref.read(isPremiumProvider)) {
                          ref.read(audioProvider.notifier).playSong(song);
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Direct song selection from queue is for Premium members'),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
